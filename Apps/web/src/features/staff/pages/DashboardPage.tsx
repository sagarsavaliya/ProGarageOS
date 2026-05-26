import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { KPICard, Card, StatusBadge, Table, THead, TRow, TH, TD } from '@/components/ui';
import { StaffShell } from '@/layouts/StaffShell';
import { apiRequest, asData, type JsonMap } from '@/lib/api';

export function DashboardPage(props: {
  token: string;
  userName?: string;
  onLogout: () => void;
}) {
  const summaryQuery = useQuery({
    queryKey: ['staff-dashboard-summary', props.token],
    queryFn: () => apiRequest('/dashboard/summary', { token: props.token }),
  });

  const summary = asData<JsonMap>(summaryQuery.data ?? {});
  const activeJobs = (summary.active_jobs as JsonMap[] | undefined) ?? [];
  const bays = (summary.service_bays as JsonMap[] | undefined) ?? [];

  return (
    <StaffShell title="Dashboard" subtitle="Today's overview" userName={props.userName} onLogout={props.onLogout}>
      <div className="kpi-grid">
        <KPICard label="Open Jobs" value={String(summary.open_jobs ?? 0)} />
        <KPICard label="Revenue Today" value={`₹${summary.revenue_today ?? 0}`} />
        <KPICard label="Pending Invoices" value={String(summary.pending_invoices ?? 0)} />
        <KPICard label="Low Stock Items" value={String(summary.low_stock_count ?? 0)} />
      </div>

      <div className="split-grid">
        <Card>
          <h3>Service Bays</h3>
          <div className="stack" style={{ marginTop: 12 }}>
            {bays.length === 0 ? <p className="muted">No bay status available.</p> : null}
            {bays.map((bay) => (
              <div key={String(bay.uuid ?? bay.name)} className="line-item">
                <strong>{String(bay.name ?? 'Bay')}</strong>
                <StatusBadge status={String(bay.status ?? 'draft')} />
              </div>
            ))}
          </div>
        </Card>

        <Card>
          <h3>Active Jobs</h3>
          <Table className="table-spaced">
            <THead>
              <TRow>
                <TH>Job</TH>
                <TH>Customer</TH>
                <TH>Status</TH>
              </TRow>
            </THead>
            <tbody>
              {activeJobs.slice(0, 8).map((job) => (
                <TRow key={String(job.uuid ?? job.id)}>
                  <TD>
                    <Link to={`/jobs/${String(job.uuid)}`}>{String(job.job_number ?? job.uuid ?? 'Job')}</Link>
                  </TD>
                  <TD>{String(job.customer_name ?? '-')}</TD>
                  <TD>
                    <StatusBadge status={String(job.status ?? 'draft')} />
                  </TD>
                </TRow>
              ))}
            </tbody>
          </Table>
        </Card>
      </div>
    </StaffShell>
  );
}
