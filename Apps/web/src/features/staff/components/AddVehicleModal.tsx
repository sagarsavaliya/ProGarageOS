import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Alert, Button, Modal } from '@/components/ui';
import { FieldLabel, SelectInput, TextInput } from '@/components/ui/FormField';
import { apiRequest, asData, type JsonMap } from '@/lib/api';
import { customerName } from '@/lib/format';

const FUEL_TYPES = [
  { value: 'petrol', label: 'Petrol' },
  { value: 'diesel', label: 'Diesel' },
  { value: 'cng', label: 'CNG' },
  { value: 'lpg', label: 'LPG' },
  { value: 'electric', label: 'Electric' },
  { value: 'hybrid', label: 'Hybrid' },
];

export function AddVehicleModal(props: {
  open: boolean;
  token: string;
  onClose: () => void;
  onCreated?: (vehicle: JsonMap) => void;
  customerUuid?: string;
  customerLabel?: string;
}) {
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();
  const [customerUuid, setCustomerUuid] = useState(props.customerUuid ?? '');
  const [form, setForm] = useState({
    registration_number: '',
    maker: '',
    model: '',
    year: '',
    fuel_type: 'petrol',
    odometer_reading: '',
    color: '',
  });

  const customersQuery = useQuery({
    queryKey: ['add-vehicle-customers', props.token],
    enabled: props.open && props.token.length > 0 && !props.customerUuid,
    queryFn: async () => {
      const payload = await apiRequest('/customers', { token: props.token, query: { per_page: 50 } });
      return asData<JsonMap[]>(payload) ?? [];
    },
  });

  const resolvedCustomerUuid = props.customerUuid ?? customerUuid;

  function resetForm() {
    setForm({
      registration_number: '',
      maker: '',
      model: '',
      year: '',
      fuel_type: 'petrol',
      odometer_reading: '',
      color: '',
    });
    setCustomerUuid(props.customerUuid ?? '');
    setError(undefined);
  }

  function handleClose() {
    resetForm();
    props.onClose();
  }

  async function createVehicle(event: React.FormEvent) {
    event.preventDefault();
    if (!resolvedCustomerUuid) {
      setError('Select a customer for this vehicle.');
      return;
    }

    setSaving(true);
    setError(undefined);
    try {
      const payload = await apiRequest('/vehicles', {
        method: 'POST',
        token: props.token,
        body: {
          customer_uuid: resolvedCustomerUuid,
          registration_number: form.registration_number.trim().toUpperCase(),
          maker: form.maker.trim(),
          model: form.model.trim(),
          fuel_type: form.fuel_type,
          ...(form.year.trim() ? { year: Number(form.year) } : {}),
          ...(form.odometer_reading.trim() ? { odometer_reading: Number(form.odometer_reading) } : {}),
          ...(form.color.trim() ? { color: form.color.trim() } : {}),
        },
      });
      const created = asData<JsonMap>(payload);
      resetForm();
      props.onCreated?.(created);
      props.onClose();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <Modal
      open={props.open}
      onClose={handleClose}
      title="Add vehicle"
      subtitle={
        props.customerLabel
          ? `Register a vehicle for ${props.customerLabel}`
          : 'Link a vehicle to an existing customer'
      }
      wide
      footer={
        <>
          <Button type="button" variant="outline" onClick={handleClose}>
            Cancel
          </Button>
          <Button type="submit" form="add-vehicle-form" disabled={saving}>
            {saving ? 'Saving...' : 'Add vehicle'}
          </Button>
        </>
      }
    >
      <form id="add-vehicle-form" className="form-grid form-grid--stack" onSubmit={(event) => void createVehicle(event)}>
        {!props.customerUuid ? (
          <div>
            <FieldLabel htmlFor="vehicle-customer">Customer</FieldLabel>
            <SelectInput
              id="vehicle-customer"
              required
              value={customerUuid}
              onChange={(event) => setCustomerUuid(event.target.value)}
            >
              <option value="">Select customer</option>
              {(customersQuery.data ?? []).map((customer) => (
                <option key={String(customer.uuid)} value={String(customer.uuid)}>
                  {customerName(customer)} · {String(customer.phone_primary ?? customer.phone ?? '-')}
                </option>
              ))}
            </SelectInput>
          </div>
        ) : null}

        <div className="form-grid">
          <div>
            <FieldLabel htmlFor="vehicle-registration">Registration number</FieldLabel>
            <TextInput
              id="vehicle-registration"
              required
              placeholder="e.g. MH12AB1234"
              value={form.registration_number}
              onChange={(event) => setForm({ ...form, registration_number: event.target.value.toUpperCase() })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="vehicle-fuel">Fuel type</FieldLabel>
            <SelectInput
              id="vehicle-fuel"
              value={form.fuel_type}
              onChange={(event) => setForm({ ...form, fuel_type: event.target.value })}
            >
              {FUEL_TYPES.map((fuel) => (
                <option key={fuel.value} value={fuel.value}>
                  {fuel.label}
                </option>
              ))}
            </SelectInput>
          </div>
        </div>

        <div className="form-grid">
          <div>
            <FieldLabel htmlFor="vehicle-maker">Make</FieldLabel>
            <TextInput
              id="vehicle-maker"
              required
              placeholder="e.g. Maruti"
              value={form.maker}
              onChange={(event) => setForm({ ...form, maker: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="vehicle-model">Model</FieldLabel>
            <TextInput
              id="vehicle-model"
              required
              placeholder="e.g. Swift"
              value={form.model}
              onChange={(event) => setForm({ ...form, model: event.target.value })}
            />
          </div>
        </div>

        <div className="form-grid">
          <div>
            <FieldLabel htmlFor="vehicle-year">Year (optional)</FieldLabel>
            <TextInput
              id="vehicle-year"
              inputMode="numeric"
              placeholder="e.g. 2021"
              value={form.year}
              onChange={(event) => setForm({ ...form, year: event.target.value.replace(/\D/g, '').slice(0, 4) })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="vehicle-odometer">Odometer km (optional)</FieldLabel>
            <TextInput
              id="vehicle-odometer"
              inputMode="numeric"
              value={form.odometer_reading}
              onChange={(event) => setForm({ ...form, odometer_reading: event.target.value.replace(/\D/g, '') })}
            />
          </div>
        </div>

        <div>
          <FieldLabel htmlFor="vehicle-color">Color (optional)</FieldLabel>
          <TextInput
            id="vehicle-color"
            placeholder="e.g. White"
            value={form.color}
            onChange={(event) => setForm({ ...form, color: event.target.value })}
          />
        </div>

        {error ? <Alert variant="error">{error}</Alert> : null}
      </form>
    </Modal>
  );
}
