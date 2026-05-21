<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StaffAppSession;
use App\Models\StaffNotification;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * GET /notifications — staff inbox (paginated).
     */
    public function index(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();
        $perPage = min((int) $request->query('per_page', 25), 50);

        $query = StaffNotification::where('user_id', $user->id)
            ->orderByDesc('created_at');

        if ($request->boolean('unread_only')) {
            $query->whereNull('read_at');
        }

        $notifications = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data'    => $notifications->map(fn ($n) => $this->format($n)),
            'meta'    => [
                'current_page' => $notifications->currentPage(),
                'per_page'     => $notifications->perPage(),
                'total'        => $notifications->total(),
                'last_page'    => $notifications->lastPage(),
                'unread_count' => StaffNotification::where('user_id', $user->id)->whereNull('read_at')->count(),
            ],
        ]);
    }

    /**
     * POST /device-token — register or refresh FCM token for staff app.
     */
    public function registerDevice(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $data = $request->validate([
            'device_token' => ['required', 'string', 'min:20', 'max:512'],
            'platform'     => ['in:ios,android,web'],
            'app_version'  => ['nullable', 'string', 'max:20'],
        ]);

        StaffAppSession::updateOrCreate(
            [
                'user_id'      => $user->id,
                'device_token' => $data['device_token'],
            ],
            [
                'tenant_id'      => $user->tenant_id,
                'platform'       => $data['platform'] ?? 'android',
                'app_version'    => $data['app_version'] ?? null,
                'last_active_at' => now(),
                'is_active'      => true,
            ],
        );

        return response()->json(['success' => true, 'message' => 'Device registered for push notifications.']);
    }

    /**
     * PATCH /notifications/read-all
     */
    public function markAllRead(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        StaffNotification::where('user_id', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now(), 'status' => 'read']);

        return response()->json(['success' => true]);
    }

    /**
     * PATCH /notifications/{uuid}/read
     */
    public function markRead(Request $request, string $uuid): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $notification = StaffNotification::where('uuid', $uuid)
            ->where('user_id', $user->id)
            ->firstOrFail();

        $notification->update(['read_at' => now(), 'status' => 'read']);

        return response()->json(['success' => true, 'data' => $this->format($notification)]);
    }

    private function format(StaffNotification $n): array
    {
        return [
            'uuid'        => $n->uuid,
            'event_code'  => $n->event_code,
            'title'       => $n->title,
            'body'        => $n->body,
            'data'        => $n->data ?? [],
            'is_read'     => $n->read_at !== null,
            'read_at'     => $n->read_at?->toIso8601String(),
            'created_at'  => $n->created_at->toIso8601String(),
        ];
    }
}
