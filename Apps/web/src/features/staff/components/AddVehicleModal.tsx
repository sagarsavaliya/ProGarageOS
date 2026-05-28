import { useCallback, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Alert, Button, Modal } from '@/components/ui';
import { CatalogCombobox } from '@/components/ui/CatalogCombobox';
import { FieldLabel, SelectInput, TextInput } from '@/components/ui/FormField';
import { apiRequest, asData, type JsonMap } from '@/lib/api';
import { customerName } from '@/lib/format';
import {
  searchCatalogColors,
  searchCatalogMakes,
  searchCatalogModels,
  searchCatalogVariants,
  type CatalogOption,
} from '@/lib/vehicle-catalog';

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
    variant: '',
    year: '',
    fuel_type: 'petrol',
    odometer_reading: '',
    color: '',
  });
  const [catalogIds, setCatalogIds] = useState({
    makeUuid: '',
    modelUuid: '',
    variantUuid: '',
    colorUuid: '',
  });

  const yearFilter = useMemo(() => {
    const year = Number(form.year);
    return Number.isFinite(year) && year >= 1900 ? year : undefined;
  }, [form.year]);

  const searchMakes = useCallback(
    (query: string) => searchCatalogMakes(props.token, query, yearFilter),
    [props.token, yearFilter],
  );
  const searchModels = useCallback(
    (query: string) =>
      catalogIds.makeUuid
        ? searchCatalogModels(props.token, catalogIds.makeUuid, query, yearFilter)
        : Promise.resolve([]),
    [catalogIds.makeUuid, props.token, yearFilter],
  );
  const searchVariants = useCallback(
    (query: string) =>
      catalogIds.modelUuid
        ? searchCatalogVariants(props.token, catalogIds.modelUuid, query, yearFilter)
        : Promise.resolve([]),
    [catalogIds.modelUuid, props.token, yearFilter],
  );
  const searchColors = useCallback(
    (query: string) =>
      searchCatalogColors(props.token, query, catalogIds.variantUuid || undefined),
    [catalogIds.variantUuid, props.token],
  );

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
      variant: '',
      year: '',
      fuel_type: 'petrol',
      odometer_reading: '',
      color: '',
    });
    setCatalogIds({ makeUuid: '', modelUuid: '', variantUuid: '', colorUuid: '' });
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
          ...(form.variant.trim() ? { variant: form.variant.trim() } : {}),
          fuel_type: form.fuel_type,
          ...(form.year.trim() ? { year: Number(form.year) } : {}),
          ...(form.odometer_reading.trim() ? { odometer_reading: Number(form.odometer_reading) } : {}),
          ...(form.color.trim() ? { color: form.color.trim() } : {}),
          ...(catalogIds.makeUuid ? { vehicle_make_uuid: catalogIds.makeUuid } : {}),
          ...(catalogIds.modelUuid ? { vehicle_model_uuid: catalogIds.modelUuid } : {}),
          ...(catalogIds.variantUuid ? { vehicle_variant_uuid: catalogIds.variantUuid } : {}),
          ...(catalogIds.colorUuid ? { vehicle_color_uuid: catalogIds.colorUuid } : {}),
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
            <FieldLabel htmlFor="vehicle-year">Year (optional)</FieldLabel>
            <TextInput
              id="vehicle-year"
              inputMode="numeric"
              placeholder="e.g. 2021"
              value={form.year}
              onChange={(event) => {
                const year = event.target.value.replace(/\D/g, '').slice(0, 4);
                setForm({ ...form, year });
                setCatalogIds({ makeUuid: '', modelUuid: '', variantUuid: '', colorUuid: '' });
              }}
            />
          </div>
        </div>

        <div className="form-grid">
          <CatalogCombobox
            label="Make"
            placeholder="Start typing make…"
            value={form.maker}
            onValueChange={(maker) => setForm({ ...form, maker })}
            onSearch={searchMakes}
            onOptionSelect={(option: CatalogOption | null) => {
              setCatalogIds({
                makeUuid: option?.uuid ?? '',
                modelUuid: '',
                variantUuid: '',
                colorUuid: '',
              });
              if (option) setForm((current) => ({ ...current, maker: option.name, model: '', variant: '', color: '' }));
            }}
          />
          <CatalogCombobox
            label="Model"
            placeholder={catalogIds.makeUuid ? 'Start typing model…' : 'Select make first'}
            value={form.model}
            disabled={!catalogIds.makeUuid}
            onValueChange={(model) => setForm({ ...form, model })}
            onSearch={searchModels}
            onOptionSelect={(option: CatalogOption | null) => {
              setCatalogIds((current) => ({
                ...current,
                modelUuid: option?.uuid ?? '',
                variantUuid: '',
                colorUuid: '',
              }));
              if (option) setForm((current) => ({ ...current, model: option.name, variant: '', color: '' }));
            }}
          />
        </div>

        <div className="form-grid">
          <CatalogCombobox
            label="Variant (optional)"
            placeholder={catalogIds.modelUuid ? 'Start typing variant…' : 'Select model first'}
            value={form.variant}
            disabled={!catalogIds.modelUuid}
            onValueChange={(variant) => setForm({ ...form, variant })}
            onSearch={searchVariants}
            onOptionSelect={(option: CatalogOption | null) => {
              setCatalogIds((current) => ({
                ...current,
                variantUuid: option?.uuid ?? '',
                colorUuid: '',
              }));
              if (option) {
                setForm((current) => ({
                  ...current,
                  variant: option.name,
                  color: '',
                  ...(option.fuel_type ? { fuel_type: option.fuel_type } : {}),
                }));
              }
            }}
          />
          <CatalogCombobox
            label="Color (optional)"
            placeholder="Start typing color…"
            value={form.color}
            onValueChange={(color) => setForm({ ...form, color })}
            onSearch={searchColors}
            onOptionSelect={(option: CatalogOption | null) => {
              setCatalogIds((current) => ({ ...current, colorUuid: option?.uuid ?? '' }));
              if (option) setForm((current) => ({ ...current, color: option.name }));
            }}
          />
        </div>

        <div className="form-grid">
          <div>
            <FieldLabel htmlFor="vehicle-odometer">Odometer km (optional)</FieldLabel>
            <TextInput
              id="vehicle-odometer"
              inputMode="numeric"
              value={form.odometer_reading}
              onChange={(event) => setForm({ ...form, odometer_reading: event.target.value.replace(/\D/g, '') })}
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

        {error ? <Alert variant="error">{error}</Alert> : null}
      </form>
    </Modal>
  );
}
