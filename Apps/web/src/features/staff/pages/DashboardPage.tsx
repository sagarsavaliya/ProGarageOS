import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { KPICard, Card, StatusBadge, Table, THead, TRow, TH, TD, EmptyState, LoadingState, PageSection } from '@/components/ui';
import { ServiceBayBoard } from '@/features/staff/components/ServiceBayBoard';
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
  const kpis = (summary.kpis as JsonMap | undefined) ?? {};
  const activeJobs = (summary.active_jobs as JsonMap[] | undefined) ?? [];
  const bays = (summary.service_bays as JsonMap[] | undefined) ?? [];

  return (
    <StaffShell title="Dashboard" subtitle="Today's overview" userName={props.userName} onLogout={props.onLogout}>
      {summaryQuery.isLoading ? <LoadingState label="Loading dashboard..." /> : null}

      <div className="kpi-grid">
        <KPICard label="Open Jobs" value={String(kpis.active_jobs ?? 0)} />
        <KPICard label="Revenue Today" value={`₹${kpis.revenue ?? 0}`} />
        <KPICard label="Pending Amount" value={`₹${kpis.pending_amount ?? 0}`} />
        <KPICard label="Jobs Today" value={String(kpis.jobs_today ?? 0)} />
      </div>

      <Card>
        <div className="section-header">
          <div>
            <h3>Service Bay Floor</h3>
            <p className="muted section-subtitle">Live occupancy — vehicle, job, and technician at a glance</p>
          </div>
        </div>
        <ServiceBayBoard bays={bays} />
      </Card>

      <PageSection title="Active Jobs" subtitle="Open work across your garage floor">
        {activeJobs.length === 0 ? (
          <EmptyState title="No active jobs right now" description="New jobs will appear here once intake or appointments begin." />
        ) : (
          <Table className="table-spaced">
          <THead>
            <TRow>
              <TH>Job</TH>
              <TH>Customer</TH>
              <TH>Vehicle</TH>
              <TH>Technician</TH>
              <TH>Status</TH>
            </TRow>
          </THead>
          <tbody>
            {activeJobs.slice(0, 8).map((job) => {
              const customer = job.customer as JsonMap | undefined;
              const vehicle = job.vehicle as JsonMap | undefined;
              return (
                <TRow key={String(job.uuid ?? job.id)}>
                  <TD>
                    <Link to={`/jobs/${String(job.uuid)}`}>{String(job.job_number ?? job.uuid ?? 'Job')}</Link>
                  </TD>
                  <TD>{String(customer?.name ?? job.customer_name ?? '-')}</TD>
                  <TD>{String(vehicle?.display ?? vehicle?.registration_number ?? '-')}</TD>
                  <TD>{String(job.technician ?? '-')}</TD>
                  <TD>
                    <StatusBadge status={String(job.status ?? 'draft')} />
                  </TD>
                </TRow>
              );
            })}
          </tbody>
        </Table>
        )}
      </PageSection>
    </StaffShell>
  );
}
