<?php

namespace App\Services;

use App\Models\StaffAppSession;
use App\Models\StaffNotification;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PushNotificationService
{
    /**
     * Notify a staff user — persists inbox row and attempts FCM delivery.
     *
     * @param  array<string, mixed>  $data  e.g. ['job_uuid' => '...', 'type' => 'job_status']
     */
    public function notifyStaff(
        User $user,
        string $eventCode,
        string $title,
        string $body,
        array $data = [],
    ): StaffNotification {
        $notification = StaffNotification::create([
            'tenant_id'  => $user->tenant_id,
            'user_id'    => $user->id,
            'event_code' => $eventCode,
            'title'      => $title,
            'body'       => $body,
            'data'       => $data,
            'status'     => 'sent',
        ]);

        $tokens = StaffAppSession::where('user_id', $user->id)
            ->where('is_active', true)
            ->pluck('device_token')
            ->filter()
            ->unique()
            ->values()
            ->all();

        if (empty($tokens)) {
            return $notification;
        }

        $sent = $this->sendFcm($tokens, $title, $body, array_merge($data, [
            'notification_uuid' => $notification->uuid,
            'event_code'        => $eventCode,
        ]));

        if (!$sent) {
            $notification->update(['status' => 'failed']);
        }

        return $notification;
    }

    /**
     * Notify all active staff in a tenant (owners + advisors).
     */
    public function notifyTenantStaff(
        int $tenantId,
        string $eventCode,
        string $title,
        string $body,
        array $data = [],
        ?int $exceptUserId = null,
    ): void {
        $users = User::where('tenant_id', $tenantId)
            ->when($exceptUserId, fn ($q) => $q->where('id', '!=', $exceptUserId))
            ->get();

        foreach ($users as $user) {
            $this->notifyStaff($user, $eventCode, $title, $body, $data);
        }
    }

    /**
     * @param  list<string>  $tokens
     * @param  array<string, mixed>  $data
     */
    public function sendFcm(array $tokens, string $title, string $body, array $data = []): bool
    {
        $serverKey = config('services.fcm.server_key');
        if (empty($serverKey)) {
            Log::info('FCM skipped — FCM_SERVER_KEY not configured', [
                'title' => $title,
                'tokens_count' => count($tokens),
            ]);
            return true; // Inbox still works; push is optional in dev
        }

        $payload = [
            'registration_ids' => $tokens,
            'notification'     => [
                'title' => $title,
                'body'  => $body,
                'sound' => 'default',
            ],
            'data' => array_map('strval', $data),
            'priority' => 'high',
        ];

        try {
            $response = Http::withHeaders([
                'Authorization' => 'key=' . $serverKey,
                'Content-Type'  => 'application/json',
            ])->connectTimeout(2)->timeout(3)->post('https://fcm.googleapis.com/fcm/send', $payload);

            if ($response->successful()) {
                return true;
            }

            Log::warning('FCM delivery failed', [
                'status' => $response->status(),
                'body'   => $response->body(),
            ]);
        } catch (\Throwable $e) {
            Log::error('FCM exception: ' . $e->getMessage());
        }

        return false;
    }
}
