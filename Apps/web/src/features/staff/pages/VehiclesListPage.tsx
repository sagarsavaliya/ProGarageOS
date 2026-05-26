import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Button, Card, Table, THead, TRow, TH, TD, EmptyState, LoadingState, ListPager } from '@/components/ui';
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
          className="toolbar-form toolbar-form--search"
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
          <div>
            <Button type="submit">Search</Button>
          </div>
        </form>
      </div>

      <Card>
        {listQuery.isLoading ? <LoadingState label="Loading vehicles..." /> : null}
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
          !listQuery.isLoading && (
            <EmptyState title="No vehicles found" description="Vehicles appear here when linked to customers or fleet records." />
          )
        )}

        <ListPager page={page} lastPage={lastPage} onPrevious={() => setPage((p) => p - 1)} onNext={() => setPage((p) => p + 1)} />
      </Card>
    </StaffPage>
  );
}
