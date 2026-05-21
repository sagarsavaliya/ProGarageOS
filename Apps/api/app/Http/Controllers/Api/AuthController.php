<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\User;
use App\Services\WhatsAppService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Staff (PIN-based) login.
     */
    public function staffLogin(Request $request): JsonResponse
    {
        $request->validate([
            'login' => ['required', 'string'],
            'pin'   => ['required', 'string', 'min:4', 'max:10'],
        ]);

        $key = 'staff-login:' . $request->ip();
        if (RateLimiter::tooManyAttempts($key, 10)) {
            $seconds = RateLimiter::availableIn($key);
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'               => 'RATE_LIMITED',
                    'message'            => "Too many attempts. Please wait {$seconds} seconds.",
                    'retry_after_seconds' => $seconds,
                ],
            ], 429)->withHeaders(['Retry-After' => $seconds]);
        }

        $user = User::with('tenant')
            ->where('email', $request->login)
            ->orWhere('phone', $request->login)
            ->first();

        if (!$user || !Hash::check($request->pin, $user->pin_hash)) {
            RateLimiter::hit($key, 900);
            $remaining = 10 - RateLimiter::attempts($key);
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'    => 'INVALID_CREDENTIALS',
                    'message' => "Invalid PIN or credentials. {$remaining} attempts remaining.",
                ],
            ], 401);
        }

        RateLimiter::clear($key);
        $user->update(['last_login_at' => now()]);

        $token = $user->createToken('staff-app', ['staff'], now()->addDays(30));

        return response()->json([
            'success' => true,
            'data'    => [
                'token'      => $token->plainTextToken,
                'token_type' => 'Bearer',
                'expires_at' => $token->accessToken->expires_at?->toIso8601String(),
                'user'       => $this->formatUser($user),
            ],
        ]);
    }

    /**
     * Request OTP for customer login.
     */
    public function customerOtpRequest(Request $request): JsonResponse
    {
        $request->validate([
            'phone' => ['required', 'string', 'regex:/^\+?[1-9]\d{9,14}$/'],
        ]);

        $key = 'otp-request:' . $request->phone;
        if (RateLimiter::tooManyAttempts($key, 5)) {
            $seconds = RateLimiter::availableIn($key);
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'               => 'RATE_LIMITED',
                    'message'            => "Too many OTP requests. Wait {$seconds} seconds.",
                    'retry_after_seconds' => $seconds,
                ],
            ], 429)->withHeaders(['Retry-After' => $seconds]);
        }

        $customer = Customer::firstOrCreate(
            ['phone_primary' => $request->phone],
            ['first_name' => 'Customer', 'uuid' => (string) \Illuminate\Support\Str::uuid()]
        );

        $otp = $customer->generateOtp();
        RateLimiter::hit($key, 600);

        // Dispatch OTP via WhatsApp
        $whatsapp = new WhatsAppService();
        $sent = $whatsapp->sendOtp($request->phone, $otp);

        if (!$sent) {
            Log::warning("WhatsApp OTP delivery failed for {$request->phone} — OTP still valid for manual entry.");
        }

        $response = [
            'success' => true,
            'message' => 'OTP sent via WhatsApp.',
        ];

        // Expose OTP in debug mode only (local dev without real WhatsApp)
        if (config('app.debug')) {
            $response['dev_otp'] = $otp;
        }

        $retryAfter = RateLimiter::availableIn($key) ?: 30;
        return response()->json($response)->withHeaders(['Retry-After' => $retryAfter]);
    }

    /**
     * Verify OTP and issue customer token.
     */
    public function customerOtpVerify(Request $request): JsonResponse
    {
        $request->validate([
            'phone' => ['required', 'string'],
            'otp'   => ['required', 'string', 'size:6'],
        ]);

        $customer = Customer::where('phone_primary', $request->phone)->first();

        if (!$customer || !$customer->verifyOtp($request->otp)) {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'INVALID_OTP', 'message' => 'Invalid or expired OTP.'],
            ], 401);
        }

        $customer->update(['otp_code' => null, 'otp_expires_at' => null]);
        $token = $customer->createToken('customer-app', ['customer'], now()->addDays(90));

        return response()->json([
            'success' => true,
            'data'    => [
                'token'      => $token->plainTextToken,
                'token_type' => 'Bearer',
                'expires_at' => $token->accessToken->expires_at?->toIso8601String(),
                'customer'   => [
                    'uuid'           => $customer->uuid,
                    'phone_primary'  => $customer->phone_primary,
                    'first_name'     => $customer->first_name,
                    'last_name'      => $customer->last_name,
                    'email'          => $customer->email,
                ],
            ],
        ]);
    }

    /**
     * Logout (revoke current token).
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['success' => true, 'message' => 'Logged out successfully.']);
    }

    /**
     * Return authenticated user/customer info.
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($user instanceof Customer) {
            return response()->json(['success' => true, 'data' => ['customer' => $user]]);
        }
        return response()->json(['success' => true, 'data' => ['user' => $this->formatUser($user->load('tenant'))]]);
    }

    private function formatUser(User $user): array
    {
        return [
            'uuid'              => $user->uuid,
            'first_name'        => $user->first_name,
            'last_name'         => $user->last_name,
            'email'             => $user->email,
            'phone'             => $user->phone,
            'role'              => $user->role,
            'is_platform_admin' => $user->is_platform_admin,
            'is_support_agent'  => $user->is_support_agent,
            'avatar_url'        => $user->avatar_url,
            'last_login_at'     => $user->last_login_at?->toIso8601String(),
            'tenant'            => $user->tenant ? [
                'uuid'          => $user->tenant->uuid,
                'business_name' => $user->tenant->business_name,
                'status'        => $user->tenant->status,
                'currency'      => $user->tenant->currency,
                'timezone'      => $user->tenant->timezone,
            ] : null,
        ];
    }
}
