import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Button, Card, StatusBadge, Table, THead, TRow, TH, TD } from '@/components/ui';
import { FieldLabel, SelectInput, TextArea, TextInput } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest, asData, type JsonMap } from '@/lib/api';
import { usePaginatedList } from '@/lib/hooks';
import { customerName, vehicleLabel } from '@/lib/format';

function todayIsoDate(): string {
  return new Date().toISOString().slice(0, 10);
}

export function AppointmentsPage() {
  const token = useStaffToken();
  const [date, setDate] = useState(todayIsoDate());
  const [page, setPage] = useState(1);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    customer_uuid: '',
    vehicle_uuid: '',
    scheduled_date: todayIsoDate(),
    start_time: '10:00',
    notes: '',
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();

  const listQuery = usePaginatedList('/appointments', token, { page, per_page: 25, date });
  const items = listQuery.data?.items ?? [];
  const meta = listQuery.data?.meta ?? {};
  const lastPage = Number(meta.last_page ?? 1);

  const customersQuery = useQuery({
    queryKey: ['appointment-customers', token],
    enabled: showForm && token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/customers', { token, query: { per_page: 50 } });
      return asData<JsonMap[]>(payload) ?? [];
    },
  });

  const vehiclesQuery = useQuery({
    queryKey: ['appointment-vehicles', form.customer_uuid, token],
    enabled: showForm && form.customer_uuid.length > 0,
    queryFn: async () => {
      const payload = await apiRequest(`/customers/${form.customer_uuid}/vehicles`, { token });
      return asData<JsonMap[]>(payload) ?? [];
    },
  });

  async function createAppointment(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest('/appointments', {
        method: 'POST',
        token,
        body: {
          customer_uuid: form.customer_uuid,
          vehicle_uuid: form.vehicle_uuid,
          scheduled_date: form.scheduled_date,
          start_time: form.start_time,
          ...(form.notes.trim() ? { notes: form.notes.trim() } : {}),
          source: 'phone',
        },
      });
      setShowForm(false);
      await listQuery.refetch();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function checkIn(appointmentUuid: string) {
    setError(undefined);
    try {
      await apiRequest(`/appointments/${appointmentUuid}/check-in`, { method: 'PUT', token, body: {} });
      await listQuery.refetch();
    } catch (err) {
      setError((err as Error).message);
    }
  }

  return (
    <StaffPage title="Appointments" subtitle="Daily schedule and check-in">
      <div className="toolbar">
        <div>
          <FieldLabel htmlFor="appt-date">Date</FieldLabel>
          <TextInput
            id="appt-date"
            type="date"
            value={date}
            onChange={(event) => {
              setDate(event.target.value);
              setPage(1);
            }}
          />
        </div>
        <Button type="button" onClick={() => setShowForm(true)}>
          Book appointment
        </Button>
      </div>

      <Card>
        {listQuery.isLoading ? <p className="muted">Loading appointments...</p> : null}
        {items.length > 0 ? (
          <Table>
            <THead>
              <TRow>
                <TH>Time</TH>
                <TH>Customer</TH>
                <TH>Vehicle</TH>
                <TH>Status</TH>
                <TH>Actions</TH>
              </TRow>
            </THead>
            <tbody>
              {items.map((appointment: JsonMap) => (
                <TRow key={String(appointment.uuid)}>
                  <TD>{String(appointment.start_time ?? '-')}</TD>
                  <TD>{String(appointment.customer_name ?? customerName((appointment.customer as JsonMap) ?? {}))}</TD>
                  <TD>{vehicleLabel((appointment.vehicle as JsonMap) ?? appointment)}</TD>
                  <TD>
                    <StatusBadge status={String(appointment.status ?? 'scheduled')} />
                  </TD>
                  <TD>
                    {appointment.status === 'scheduled' || appointment.status === 'confirmed' ? (
                      <Button type="button" variant="outline" onClick={() => void checkIn(String(appointment.uuid))}>
                        Check in
                      </Button>
                    ) : appointment.job_uuid ? (
                      <Link to={`/jobs/${String(appointment.job_uuid)}`}>View job</Link>
                    ) : null}
                  </TD>
                </TRow>
              ))}
            </tbody>
          </Table>
        ) : (
          !listQuery.isLoading && <p className="muted">No appointments for this date.</p>
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

      {showForm ? (
        <div className="modal-overlay" onClick={() => setShowForm(false)}>
          <div className="modal-card gf-card" onClick={(event) => event.stopPropagation()}>
            <h3>Book appointment</h3>
            <form className="form-grid" style={{ marginTop: 12 }} onSubmit={(event) => void createAppointment(event)}>
              <div>
                <FieldLabel>Customer</FieldLabel>
                <SelectInput
                  required
                  value={form.customer_uuid}
                  onChange={(event) => setForm({ ...form, customer_uuid: event.target.value, vehicle_uuid: '' })}
                >
                  <option value="">Select customer</option>
                  {(customersQuery.data ?? []).map((customer) => (
                    <option key={String(customer.uuid)} value={String(customer.uuid)}>
                      {customerName(customer)}
                    </option>
                  ))}
                </SelectInput>
              </div>
              <div>
                <FieldLabel>Vehicle</FieldLabel>
                <SelectInput
                  required
                  value={form.vehicle_uuid}
                  onChange={(event) => setForm({ ...form, vehicle_uuid: event.target.value })}
                >
                  <option value="">Select vehicle</option>
                  {(vehiclesQuery.data ?? []).map((vehicle) => (
                    <option key={String(vehicle.uuid)} value={String(vehicle.uuid)}>
                      {vehicleLabel(vehicle)}
                    </option>
                  ))}
                </SelectInput>
              </div>
              <div>
                <FieldLabel>Date</FieldLabel>
                <TextInput
                  type="date"
                  required
                  value={form.scheduled_date}
                  onChange={(event) => setForm({ ...form, scheduled_date: event.target.value })}
                />
              </div>
              <div>
                <FieldLabel>Start time</FieldLabel>
                <TextInput
                  type="time"
                  required
                  value={form.start_time}
                  onChange={(event) => setForm({ ...form, start_time: event.target.value })}
                />
              </div>
              <div style={{ gridColumn: '1 / -1' }}>
                <FieldLabel>Notes</FieldLabel>
                <TextArea rows={3} value={form.notes} onChange={(event) => setForm({ ...form, notes: event.target.value })} />
              </div>
              {error ? <p className="error-text">{error}</p> : null}
              <div className="toolbar">
                <Button type="button" variant="outline" onClick={() => setShowForm(false)}>
                  Cancel
                </Button>
                <Button type="submit" disabled={saving}>
                  {saving ? 'Saving...' : 'Book'}
                </Button>
              </div>
            </form>
          </div>
        </div>
      ) : null}
    </StaffPage>
  );
}
