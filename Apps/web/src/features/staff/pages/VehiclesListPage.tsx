import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Button, Card, Table, THead, TRow, TH, TD } from '@/components/ui';
import { FieldLabel, TextInput } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { usePaginatedList } from '@/lib/hooks';
import { customerName, vehicleLabel } from '@/lib/format';
import type { JsonMap } from '@/lib/api';

export function VehiclesListPage() {
  const token = useStaffToken();
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [searchInput, setSearchInput] = useState('');

  const listQuery = usePaginatedList('/vehicles', token, {
    page,
    per_page: 25,
    ...(search ? { search } : {}),
  });

  const items = listQuery.data?.items ?? [];
  const meta = listQuery.data?.meta ?? {};
  const lastPage = Number(meta.last_page ?? 1);

  return (
    <StaffPage title="Vehicles" subtitle="Fleet and customer vehicles">
      <div className="toolbar">
        <form
          className="form-grid"
          style={{ flex: 1, gridTemplateColumns: '1fr auto' }}
          onSubmit={(event) => {
            event.preventDefault();
            setSearch(searchInput.trim());
            setPage(1);
          }}
        >
          <div>
            <FieldLabel htmlFor="vehicle-search">Search</FieldLabel>
            <TextInput
              id="vehicle-search"
              placeholder="Registration, make, model..."
              value={searchInput}
              onChange={(event) => setSearchInput(event.target.value)}
            />
          </div>
          <div style={{ alignSelf: 'end' }}>
            <Button type="submit">Search</Button>
          </div>
        </form>
      </div>

      <Card>
        {listQuery.isLoading ? <p className="muted">Loading vehicles...</p> : null}
        {items.length > 0 ? (
          <Table>
            <THead>
              <TRow>
                <TH>Vehicle</TH>
                <TH>Customer</TH>
                <TH>Odometer</TH>
                <TH>Fuel</TH>
              </TRow>
            </THead>
            <tbody>
              {items.map((vehicle: JsonMap) => (
                <TRow key={String(vehicle.uuid)}>
                  <TD>
                    <Link to={`/vehicles/${String(vehicle.uuid)}`}>{vehicleLabel(vehicle)}</Link>
                  </TD>
                  <TD>{customerName((vehicle.customer as JsonMap) ?? vehicle)}</TD>
                  <TD>{String(vehicle.odometer_reading ?? '-')}</TD>
                  <TD>{String(vehicle.fuel_type ?? '-')}</TD>
                </TRow>
              ))}
            </tbody>
          </Table>
        ) : (
          !listQuery.isLoading && <p className="muted">No vehicles found.</p>
        )}

        <div className="pager">
          <span className="muted">Page {page} of {lastPage}</span>
          <div className="toolbar">
            <Button type="button" variant="outline" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
              Previous
            </Button>
            <Button type="button" variant="outline" disabled={page >= lastPage} onClick={() => setPage((p) => p + 1)}>
              Next
            </Button>
          </div>
        </div>
      </Card>
    </StaffPage>
  );
}
