import { Card, Table, THead, TRow, TH, TD } from '@/components/ui';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { ApiError, apiRequest, asData, type JsonMap } from '@/lib/api';
import { useQuery } from '@tanstack/react-query';

export function AuditPage() {
  const token = useStaffToken();

  const auditQuery = useQuery({
    queryKey: ['audit-logs', token],
    enabled: token.length > 0,
    retry: false,
    queryFn: async () => {
      try {
        const payload = await apiRequest('/audit-logs', { token, query: { per_page: 50 } });
        return { items: asData<JsonMap[]>(payload) ?? [], forbidden: false };
      } catch (error) {
        if (error instanceof ApiError && error.status === 403) {
          return { items: [], forbidden: true };
        }
        throw error;
      }
    },
  });

  const items = auditQuery.data?.items ?? [];
  const forbidden = auditQuery.data?.forbidden ?? false;

  return (
    <StaffPage title="Audit log" subtitle="Track important account and job actions">
      <Card>
        {auditQuery.isLoading ? <p className="muted">Loading audit log...</p> : null}
        {forbidden ? (
          <p className="muted">Audit log access is restricted for your role. Contact the garage owner if you need access.</p>
        ) : null}
        {auditQuery.isError && !forbidden ? <p className="error-text">Could not load audit log.</p> : null}
        {!auditQuery.isLoading && !forbidden && items.length === 0 ? <p className="muted">No audit entries yet.</p> : null}

        {items.length > 0 ? (
          <Table>
            <THead>
              <TRow>
                <TH>When</TH>
                <TH>Actor</TH>
                <TH>Action</TH>
                <TH>Entity</TH>
              </TRow>
            </THead>
            <tbody>
              {items.map((entry) => (
                <TRow key={String(entry.uuid ?? entry.id)}>
                  <TD>{String(entry.created_at ?? '-')}</TD>
                  <TD>{String(entry.actor_name ?? entry.user_name ?? '-')}</TD>
                  <TD>{String(entry.action ?? entry.event ?? '-')}</TD>
                  <TD>{String(entry.entity_type ?? entry.subject ?? '-')}</TD>
                </TRow>
              ))}
            </tbody>
          </Table>
        ) : null}
      </Card>
    </StaffPage>
  );
}
