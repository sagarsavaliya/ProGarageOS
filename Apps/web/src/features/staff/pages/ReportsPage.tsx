import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { KPICard, Table, THead, TRow, TH, TD, EmptyState, LoadingState, PageSection } from '@/components/ui';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest, asData, asList, type JsonMap } from '@/lib/api';
import { money } from '@/lib/format';

export function ReportsPage() {
  const token = useStaffToken();

  const summaryQuery = useQuery({
    queryKey: ['reports-summary', token],
    enabled: token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/dashboard/summary', { token });
      return asData<JsonMap>(payload);
    },
  });

  const jobsQuery = useQuery({
    queryKey: ['reports-jobs-count', token],
    enabled: token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/jobs', { token, query: { per_page: 1 } });
      return asList<JsonMap>(payload);
    },
  });

  const lowStockQuery = useQuery({
    queryKey: ['reports-low-stock', token],
    enabled: token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/inventory', { token, query: { low_stock: true, per_page: 10 } });
      return asList<JsonMap>(payload).items;
    },
  });

  const summary = summaryQuery.data ?? {};
  const kpis = (summary.kpis as JsonMap | undefined) ?? {};
  const totalJobs = Number(jobsQuery.data?.meta?.total ?? kpis.active_jobs ?? 0);
  const lowStock = lowStockQuery.data ?? [];

  return (
    <StaffPage title="Reports" subtitle="Operational KPIs and inventory alerts">
      <div className="kpi-grid">
        <KPICard label="Open jobs" value={String(kpis.active_jobs ?? 0)} />
        <KPICard label="Revenue today" value={money(kpis.revenue)} />
        <KPICard label="Pending amount" value={money(kpis.pending_amount)} />
        <KPICard label="Total jobs" value={String(totalJobs)} />
      </div>

      <div className="detail-grid">
        <PageSection title="Low stock items" subtitle="Parts that need reorder attention">
          {lowStockQuery.isLoading ? <LoadingState label="Loading inventory alerts..." /> : null}
          {!lowStockQuery.isLoading && lowStock.length === 0 ? (
            <EmptyState title="No low stock alerts" description="Inventory levels are healthy across tracked parts." />
          ) : null}
          {lowStock.length > 0 ? (
            <Table className="table-spaced">
              <THead>
                <TRow>
                  <TH>Part</TH>
                  <TH>Stock</TH>
                  <TH>Threshold</TH>
                </TRow>
              </THead>
              <tbody>
                {lowStock.map((item) => (
                  <TRow key={String(item.uuid)}>
                    <TD>{String(item.name ?? item.sku)}</TD>
                    <TD>{String(item.stock_on_hand ?? 0)}</TD>
                    <TD>{String(item.low_stock_threshold ?? '-')}</TD>
                  </TRow>
                ))}
              </tbody>
            </Table>
          ) : null}
          <Link to="/inventory" className="text-link-action">
            View inventory
          </Link>
        </PageSection>

        <PageSection title="Quick links" subtitle="Jump to operational modules">
          <div className="stack quick-links">
            <Link to="/jobs">Jobs list</Link>
            <Link to="/billing">Billing</Link>
            <Link to="/appointments">Appointments</Link>
            <Link to="/audit">Audit log</Link>
          </div>
        </PageSection>
      </div>
    </StaffPage>
  );
}
