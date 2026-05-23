<?php

namespace App\Http\Controllers\Api\Platform;

use App\Http\Controllers\Controller;
use App\Models\Tenant;
use App\Models\User;
use App\Support\StaffLoginHelper;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class PlatformUserController extends Controller
{
    public function index(string $tenantUuid): JsonResponse
    {
        $tenant = Tenant::where('uuid', $tenantUuid)->firstOrFail();
        $users = User::where('tenant_id', $tenant->id)->orderBy('first_name')->get();

        return response()->json([
            'success' => true,
            'data'    => $users->map(fn (User $u) => $this->format($u)),
        ]);
    }

    public function store(Request $request, string $tenantUuid): JsonResponse
    {
        $tenant = Tenant::where('uuid', $tenantUuid)->firstOrFail();

        $data = $request->validate([
            'first_name' => ['required', 'string', 'max:100'],
            'last_name'  => ['nullable', 'string', 'max:100'],
            'phone'      => ['required', 'string'],
            'email'      => ['nullable', 'email'],
            'role'       => ['required', 'in:owner,manager,service_advisor,technician,receptionist'],
            'pin'        => ['nullable', 'string', 'regex:/^\d{6}$/'],
            'requires_pin_setup' => ['sometimes', 'boolean'],
        ]);

        $phone = StaffLoginHelper::normalizePhone($data['phone']);
        $hasPin = !empty($data['pin']);

        $user = User::create([
            'tenant_id'          => $tenant->id,
            'first_name'         => $data['first_name'],
            'last_name'          => $data['last_name'] ?? '',
            'phone'              => $phone,
            'email'              => $data['email'] ?? null,
            'role'               => $data['role'],
            'pin_hash'           => $hasPin ? Hash::make($data['pin']) : Hash::make(Str::random(40)),
            'requires_pin_setup' => $data['requires_pin_setup'] ?? !$hasPin,
        ]);

        return response()->json(['success' => true, 'data' => $this->format($user)], 201);
    }

    public function update(Request $request, string $tenantUuid, string $userUuid): JsonResponse
    {
        $tenant = Tenant::where('uuid', $tenantUuid)->firstOrFail();
        $user = User::where('uuid', $userUuid)->where('tenant_id', $tenant->id)->firstOrFail();

        $data = $request->validate([
            'first_name'         => ['sometimes', 'string', 'max:100'],
            'last_name'          => ['nullable', 'string', 'max:100'],
            'phone'              => ['sometimes', 'string'],
            'email'              => ['nullable', 'email'],
            'role'               => ['sometimes', 'in:owner,manager,service_advisor,technician,receptionist'],
            'requires_pin_setup' => ['sometimes', 'boolean'],
            'is_platform_admin'  => ['sometimes', 'boolean'],
            'pin'                => ['nullable', 'string', 'regex:/^\d{6}$/'],
        ]);

        if (isset($data['phone'])) {
            $data['phone'] = StaffLoginHelper::normalizePhone($data['phone']);
        }

        if (!empty($data['pin'])) {
            $user->setPin($data['pin']);
            unset($data['pin']);
        }

        $user->update($data);

        return response()->json(['success' => true, 'data' => $this->format($user->fresh())]);
    }

    public function destroy(string $tenantUuid, string $userUuid): JsonResponse
    {
        $tenant = Tenant::where('uuid', $tenantUuid)->firstOrFail();
        $user = User::where('uuid', $userUuid)->where('tenant_id', $tenant->id)->firstOrFail();
        $user->delete();

        return response()->json(['success' => true, 'message' => 'User removed.']);
    }

    private function format(User $user): array
    {
        return [
            'uuid'               => $user->uuid,
            'first_name'         => $user->first_name,
            'last_name'          => $user->last_name,
            'phone'              => $user->phone,
            'email'              => $user->email,
            'role'               => $user->role,
            'requires_pin_setup' => $user->requires_pin_setup,
            'is_platform_admin'  => $user->is_platform_admin,
            'last_login_at'      => $user->last_login_at?->toIso8601String(),
        ];
    }
}
