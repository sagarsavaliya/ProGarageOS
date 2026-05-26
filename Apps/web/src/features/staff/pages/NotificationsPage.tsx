import { Button, Card, EmptyState, LoadingState } from '@/components/ui';
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
        <span className="pager-meta">
          <strong>{unreadCount}</strong> unread
        </span>
        <Button type="button" variant="outline" onClick={() => void markAllRead()} disabled={unreadCount === 0}>
          Mark all read
        </Button>
      </div>

      <Card>
        {notificationsQuery.isLoading ? <LoadingState label="Loading notifications..." /> : null}
        {!notificationsQuery.isLoading && items.length === 0 ? (
          <EmptyState title="No notifications yet" description="Alerts about jobs, billing, and inventory will show up here." />
        ) : null}

        <div className={`feed-list ${items.length > 0 ? 'feed-list--compact' : ''}`}>
          {items.map((item: JsonMap) => {
            const unread = !item.read_at;
            return (
              <div key={String(item.uuid)} className={`feed-item ${unread ? 'feed-item--unread' : ''}`.trim()}>
                <div>
                  <div className="feed-item-title">{String(item.title ?? 'Notification')}</div>
                  <p className="feed-item-body muted">{String(item.body ?? item.message ?? '')}</p>
                  <div className="feed-item-time">{String(item.created_at ?? '')}</div>
                </div>
                {unread ? (
                  <Button type="button" variant="outline" onClick={() => void markRead(String(item.uuid))}>
                    Mark read
                  </Button>
                ) : (
                  <span className="chip">Read</span>
                )}
              </div>
            );
          })}
        </div>
      </Card>
    </StaffPage>
  );
}
