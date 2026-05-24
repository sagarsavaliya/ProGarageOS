import { Button, Card } from '@/components/ui';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest, asData, type JsonMap } from '@/lib/api';
import { useQuery, useQueryClient } from '@tanstack/react-query';

export function NotificationsPage() {
  const token = useStaffToken();
  const queryClient = useQueryClient();

  const notificationsQuery = useQuery({
    queryKey: ['notifications', token],
    enabled: token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/notifications', { token });
      return {
        items: asData<JsonMap[]>(payload) ?? [],
        meta: (payload as JsonMap).meta as JsonMap | undefined,
      };
    },
  });

  const items = notificationsQuery.data?.items ?? [];
  const unreadCount = Number(notificationsQuery.data?.meta?.unread_count ?? 0);

  async function markRead(uuid: string) {
    await apiRequest(`/notifications/${uuid}/read`, { method: 'PATCH', token });
    await queryClient.invalidateQueries({ queryKey: ['notifications', token] });
  }

  async function markAllRead() {
    await apiRequest('/notifications/read-all', { method: 'PATCH', token });
    await queryClient.invalidateQueries({ queryKey: ['notifications', token] });
  }

  return (
    <StaffPage title="Notifications" subtitle="Staff inbox and alerts">
      <div className="toolbar">
        <span className="muted">{unreadCount} unread</span>
        <Button type="button" variant="outline" onClick={() => void markAllRead()} disabled={unreadCount === 0}>
          Mark all read
        </Button>
      </div>

      <Card>
        {notificationsQuery.isLoading ? <p className="muted">Loading notifications...</p> : null}
        {!notificationsQuery.isLoading && items.length === 0 ? <p className="muted">No notifications yet.</p> : null}
        <div className="stack" style={{ marginTop: 12 }}>
          {items.map((item) => (
            <div key={String(item.uuid)} className="line-item">
              <div>
                <strong>{String(item.title ?? 'Notification')}</strong>
                <p className="muted">{String(item.body ?? item.message ?? '')}</p>
                <small className="muted">{String(item.created_at ?? '')}</small>
              </div>
              {!item.read_at ? (
                <Button type="button" variant="outline" onClick={() => void markRead(String(item.uuid))}>
                  Mark read
                </Button>
              ) : (
                <span className="chip">Read</span>
              )}
            </div>
          ))}
        </div>
      </Card>
    </StaffPage>
  );
}
