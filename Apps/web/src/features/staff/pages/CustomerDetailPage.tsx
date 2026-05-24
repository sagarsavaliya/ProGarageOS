import { Link, useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Button, Card, StatusBadge, Table, THead, TRow, TH, TD } from '@/components/ui';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest, asData, type JsonMap } from '@/lib/api';
import { useDetail } from '@/lib/hooks';
import { customerName, vehicleLabel } from '@/lib/format';

export function CustomerDetailPage() {
  const { uuid = '' } = useParams();
  const token = useStaffToken();
  const detailQuery = useDetail(`/customers/${uuid}`, token, uuid.length > 0);
  const customer = asData<JsonMap>(detailQuery.data ?? {});

  const historyQuery = useQuery({
    queryKey: ['customer-history', uuid, token],
    enabled: uuid.length > 0 && token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest(`/customers/${uuid}/service-history`, { token });
      return asData<JsonMap[]>(payload) ?? [];
    },
  });

  const vehicles = (customer.vehicles as JsonMap[] | undefined) ?? [];
  const history = historyQuery.data ?? [];

  return (
    <StaffPage title={customerName(customer)} subtitle="Customer profile and service history">
      <div className="toolbar">
        <Link to="/customers">
          <Button type="button" variant="outline">
            Back
          </Button>
        </Link>
        <Link to={`/jobs/new?customer=${uuid}`}>
          <Button type="button">New job</Button>
        </Link>
      </div>

      {detailQuery.isLoading ? <p className="muted">Loading customer...</p> : null}

      <div className="detail-grid">
        <Card>
          <h3>Contact</h3>
          <div className="stack" style={{ marginTop: 12 }}>
            <div className="line-item">
              <span>Phone</span>
              <span>{String(customer.phone_primary ?? customer.phone ?? '-')}</span>
            </div>
            <div className="line-item">
              <span>Email</span>
              <span>{String(customer.email ?? '-')}</span>
            </div>
            <div className="line-item">
              <span>Last visit</span>
              <span>{String(customer.last_visited_at ?? '-')}</span>
            </div>
          </div>
        </Card>

        <Card>
          <h3>Vehicles</h3>
          {vehicles.length === 0 ? <p className="muted">No vehicles registered.</p> : null}
          <div className="stack" style={{ marginTop: 12 }}>
            {vehicles.map((vehicle) => (
              <Link key={String(vehicle.uuid)} to={`/vehicles/${String(vehicle.uuid)}`} className="line-item">
                <span>{vehicleLabel(vehicle)}</span>
                <StatusBadge status={vehicle.is_active === false ? 'cancelled' : 'active'} />
              </Link>
            ))}
          </div>
        </Card>
      </div>

      <Card>
        <h3>Service history</h3>
        {historyQuery.isLoading ? <p className="muted">Loading history...</p> : null}
        {!historyQuery.isLoading && history.length === 0 ? <p className="muted">No service history yet.</p> : null}
        {history.length > 0 ? (
          <Table className="table-spaced">
            <THead>
              <TRow>
                <TH>Job</TH>
                <TH>Vehicle</TH>
                <TH>Status</TH>
                <TH>Date</TH>
              </TRow>
            </THead>
            <tbody>
              {history.map((entry) => (
                <TRow key={String(entry.uuid ?? entry.job_uuid)}>
                  <TD>
                    <Link to={`/jobs/${String(entry.job_uuid ?? entry.uuid)}`}>
                      {String(entry.job_number ?? entry.uuid)}
                    </Link>
                  </TD>
                  <TD>{vehicleLabel((entry.vehicle as JsonMap) ?? entry)}</TD>
                  <TD>
                    <StatusBadge status={String(entry.status ?? 'draft')} />
                  </TD>
                  <TD>{String(entry.completed_at ?? entry.created_at ?? '-')}</TD>
                </TRow>
              ))}
            </tbody>
          </Table>
        ) : null}
      </Card>
    </StaffPage>
  );
}
