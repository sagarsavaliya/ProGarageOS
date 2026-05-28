import { useCallback, useMemo, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Button, Card } from '@/components/ui';
import { CatalogCombobox } from '@/components/ui/CatalogCombobox';
import { FieldLabel, SelectInput, TextArea, TextInput } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest, asData, normalizeLogin, type JsonMap } from '@/lib/api';
import {
  searchCatalogColors,
  searchCatalogMakes,
  searchCatalogModels,
  searchCatalogVariants,
  type CatalogOption,
} from '@/lib/vehicle-catalog';
import { customerName, vehicleLabel } from '@/lib/format';

export function CreateJobPage() {
  const token = useStaffToken();
  const navigate = useNavigate();
  const [step, setStep] = useState(0);
  const [phoneSearch, setPhoneSearch] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCustomer, setSelectedCustomer] = useState<JsonMap | null>(null);
  const [selectedVehicle, setSelectedVehicle] = useState<JsonMap | null>(null);
  const [showNewVehicle, setShowNewVehicle] = useState(false);
  const [showNewCustomer, setShowNewCustomer] = useState(false);
  const [customerForm, setCustomerForm] = useState({ first_name: '', last_name: '', phone_primary: '', email: '' });
  const [complaint, setComplaint] = useState('');
  const [priority, setPriority] = useState('normal');
  const [selectedCategories, setSelectedCategories] = useState<string[]>([]);
  const [isInsuranceJob, setIsInsuranceJob] = useState(false);
  const [insuranceCompany, setInsuranceCompany] = useState('');
  const [claimNumber, setClaimNumber] = useState('');
  const [vehicleForm, setVehicleForm] = useState({
    registration_number: '',
    maker: '',
    model: '',
    variant: '',
    year: '',
    color: '',
    fuel_type: 'petrol',
  });
  const [catalogIds, setCatalogIds] = useState({
    makeUuid: '',
    modelUuid: '',
    variantUuid: '',
    colorUuid: '',
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string>();

  const yearFilter = useMemo(() => {
    const year = Number(vehicleForm.year);
    return Number.isFinite(year) && year >= 1900 ? year : undefined;
  }, [vehicleForm.year]);

  const searchMakes = useCallback(
    (query: string) => searchCatalogMakes(token, query, yearFilter),
    [token, yearFilter],
  );
  const searchModels = useCallback(
    (query: string) =>
      catalogIds.makeUuid ? searchCatalogModels(token, catalogIds.makeUuid, query, yearFilter) : Promise.resolve([]),
    [catalogIds.makeUuid, token, yearFilter],
  );
  const searchVariants = useCallback(
    (query: string) =>
      catalogIds.modelUuid ? searchCatalogVariants(token, catalogIds.modelUuid, query, yearFilter) : Promise.resolve([]),
    [catalogIds.modelUuid, token, yearFilter],
  );
  const searchColors = useCallback(
    (query: string) => searchCatalogColors(token, query, catalogIds.variantUuid || undefined),
    [catalogIds.variantUuid, token],
  );

  const customersQuery = useQuery({
    queryKey: ['create-job-customers', searchTerm, token],
    enabled: token.length > 0 && searchTerm.length >= 3,
    queryFn: async () => {
      const payload = await apiRequest('/customers', { token, query: { search: searchTerm, per_page: 10 } });
      return asData<JsonMap[]>(payload) ?? [];
    },
  });

  const vehiclesQuery = useQuery({
    queryKey: ['create-job-vehicles', selectedCustomer?.uuid, token],
    enabled: token.length > 0 && Boolean(selectedCustomer?.uuid),
    queryFn: async () => {
      const payload = await apiRequest(`/customers/${String(selectedCustomer?.uuid)}/vehicles`, { token });
      return asData<JsonMap[]>(payload) ?? [];
    },
  });

  const categoriesQuery = useQuery({
    queryKey: ['service-categories', token],
    enabled: token.length > 0 && step === 2,
    queryFn: async () => {
      const payload = await apiRequest('/service-categories', { token });
      return asData<JsonMap[]>(payload) ?? [];
    },
  });

  const customers = customersQuery.data ?? [];
  const vehicles = vehiclesQuery.data ?? [];
  const categories = categoriesQuery.data ?? [];

  function toggleCategory(uuid: string) {
    setSelectedCategories((current) =>
      current.includes(uuid) ? current.filter((id) => id !== uuid) : [...current, uuid],
    );
  }

  async function createCustomer() {
    setSubmitting(true);
    setError(undefined);
    try {
      const payload = await apiRequest('/customers', {
        method: 'POST',
        token,
        body: {
          first_name: customerForm.first_name.trim(),
          last_name: customerForm.last_name.trim(),
          phone_primary: normalizeLogin(customerForm.phone_primary),
          ...(customerForm.email.trim() ? { email: customerForm.email.trim() } : {}),
        },
      });
      const created = asData<JsonMap>(payload);
      setSelectedCustomer(created);
      setShowNewCustomer(false);
      setStep(1);
      return created;
    } catch (err) {
      setError((err as Error).message);
      return null;
    } finally {
      setSubmitting(false);
    }
  }

  async function createVehicle() {
    if (!selectedCustomer?.uuid) {
      return null;
    }
    setSubmitting(true);
    setError(undefined);
    try {
      const payload = await apiRequest('/vehicles', {
        method: 'POST',
        token,
        body: {
          customer_uuid: selectedCustomer.uuid,
          registration_number: vehicleForm.registration_number.toUpperCase(),
          maker: vehicleForm.maker,
          model: vehicleForm.model,
          fuel_type: vehicleForm.fuel_type,
          ...(vehicleForm.variant.trim() ? { variant: vehicleForm.variant.trim() } : {}),
          ...(vehicleForm.year ? { year: Number(vehicleForm.year) } : {}),
          ...(vehicleForm.color.trim() ? { color: vehicleForm.color.trim() } : {}),
          ...(catalogIds.makeUuid ? { vehicle_make_uuid: catalogIds.makeUuid } : {}),
          ...(catalogIds.modelUuid ? { vehicle_model_uuid: catalogIds.modelUuid } : {}),
          ...(catalogIds.variantUuid ? { vehicle_variant_uuid: catalogIds.variantUuid } : {}),
          ...(catalogIds.colorUuid ? { vehicle_color_uuid: catalogIds.colorUuid } : {}),
        },
      });
      const created = asData<JsonMap>(payload);
      setSelectedVehicle(created);
      setShowNewVehicle(false);
      return created;
    } catch (err) {
      setError((err as Error).message);
      return null;
    } finally {
      setSubmitting(false);
    }
  }

  async function submitJob() {
    if (!selectedCustomer?.uuid || !selectedVehicle?.uuid) {
      setError('Customer and vehicle are required.');
      return;
    }
    setSubmitting(true);
    setError(undefined);
    try {
      const payload = await apiRequest('/jobs', {
        method: 'POST',
        token,
        body: {
          customer_uuid: selectedCustomer.uuid,
          vehicle_uuid: selectedVehicle.uuid,
          priority,
          ...(complaint.trim() ? { customer_complaint: complaint.trim() } : {}),
          ...(selectedCategories.length ? { service_category_uuids: selectedCategories } : {}),
          ...(isInsuranceJob
            ? {
                is_insurance_job: true,
                ...(insuranceCompany.trim() ? { insurance_company: insuranceCompany.trim() } : {}),
                ...(claimNumber.trim() ? { claim_number: claimNumber.trim() } : {}),
              }
            : {}),
          delivery_method: 'pickup',
        },
      });
      const created = asData<JsonMap>(payload);
      navigate(`/jobs/${String(created.uuid)}`);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <StaffPage title="New job" subtitle="Three-step intake wizard">
      <div className="stepper">
        {['Customer', 'Vehicle', 'Job details'].map((label, index) => (
          <span key={label} className={`chip ${step === index ? 'active' : ''}`}>
            {index + 1}. {label}
          </span>
        ))}
      </div>

      {step === 0 ? (
        <Card>
          <h3>Find customer by phone</h3>
          <form
            className="form-grid mt-3"
            onSubmit={(event) => {
              event.preventDefault();
              setSearchTerm(normalizeLogin(phoneSearch).replace('+91', '') || phoneSearch.trim());
            }}
          >
            <div>
              <FieldLabel htmlFor="phone-search">Phone number</FieldLabel>
              <TextInput
                id="phone-search"
                placeholder="10-digit mobile"
                value={phoneSearch}
                onChange={(event) => setPhoneSearch(event.target.value)}
              />
            </div>
            <div className="align-self-end">
              <Button type="submit">Search</Button>
            </div>
          </form>

          <div className="toolbar mt-3">
            <Button type="button" variant="outline" onClick={() => setShowNewCustomer((value) => !value)}>
              {showNewCustomer ? 'Cancel new customer' : 'Add new customer'}
            </Button>
          </div>

          {showNewCustomer ? (
            <div className="form-grid mt-3">
              <div>
                <FieldLabel>First name</FieldLabel>
                <TextInput
                  value={customerForm.first_name}
                  onChange={(event) => setCustomerForm({ ...customerForm, first_name: event.target.value })}
                />
              </div>
              <div>
                <FieldLabel>Last name</FieldLabel>
                <TextInput
                  value={customerForm.last_name}
                  onChange={(event) => setCustomerForm({ ...customerForm, last_name: event.target.value })}
                />
              </div>
              <div>
                <FieldLabel>Phone</FieldLabel>
                <TextInput
                  value={customerForm.phone_primary}
                  onChange={(event) => setCustomerForm({ ...customerForm, phone_primary: event.target.value })}
                />
              </div>
              <div>
                <FieldLabel>Email</FieldLabel>
                <TextInput
                  value={customerForm.email}
                  onChange={(event) => setCustomerForm({ ...customerForm, email: event.target.value })}
                />
              </div>
              <Button type="button" onClick={() => void createCustomer()} disabled={submitting}>
                Save customer
              </Button>
            </div>
          ) : null}

          {customersQuery.isLoading ? <p className="muted">Searching...</p> : null}
          <div className="stack mt-3">
            {customers.map((customer) => (
              <button
                key={String(customer.uuid)}
                type="button"
                className={`chip ${selectedCustomer?.uuid === customer.uuid ? 'active' : ''}`}
                onClick={() => {
                  setSelectedCustomer(customer);
                  setSelectedVehicle(null);
                  setStep(1);
                }}
              >
                {customerName(customer)} · {String(customer.phone_primary ?? customer.phone ?? '-')}
              </button>
            ))}
          </div>
        </Card>
      ) : null}

      {step === 1 ? (
        <Card>
          <h3>Select vehicle for {customerName(selectedCustomer ?? {})}</h3>
          <div className="toolbar mt-3">
            <Button type="button" variant="outline" onClick={() => setStep(0)}>
              Back
            </Button>
            <Button type="button" variant="outline" onClick={() => setShowNewVehicle((value) => !value)}>
              {showNewVehicle ? 'Cancel new vehicle' : 'Add vehicle'}
            </Button>
          </div>

          {showNewVehicle ? (
            <div className="form-grid form-grid--stack mt-3">
              <div className="form-grid">
                <div>
                  <FieldLabel>Registration</FieldLabel>
                  <TextInput
                    value={vehicleForm.registration_number}
                    onChange={(event) =>
                      setVehicleForm({ ...vehicleForm, registration_number: event.target.value.toUpperCase() })
                    }
                  />
                </div>
                <div>
                  <FieldLabel>Year</FieldLabel>
                  <TextInput
                    value={vehicleForm.year}
                    onChange={(event) => {
                      const year = event.target.value.replace(/\D/g, '').slice(0, 4);
                      setVehicleForm({ ...vehicleForm, year });
                      setCatalogIds({ makeUuid: '', modelUuid: '', variantUuid: '', colorUuid: '' });
                    }}
                  />
                </div>
              </div>
              <div className="form-grid">
                <CatalogCombobox
                  label="Make"
                  placeholder="Start typing make…"
                  value={vehicleForm.maker}
                  onValueChange={(maker) => setVehicleForm({ ...vehicleForm, maker })}
                  onSearch={searchMakes}
                  onOptionSelect={(option: CatalogOption | null) => {
                    setCatalogIds({ makeUuid: option?.uuid ?? '', modelUuid: '', variantUuid: '', colorUuid: '' });
                    if (option) {
                      setVehicleForm((current) => ({ ...current, maker: option.name, model: '', variant: '', color: '' }));
                    }
                  }}
                />
                <CatalogCombobox
                  label="Model"
                  placeholder={catalogIds.makeUuid ? 'Start typing model…' : 'Select make first'}
                  value={vehicleForm.model}
                  disabled={!catalogIds.makeUuid}
                  onValueChange={(model) => setVehicleForm({ ...vehicleForm, model })}
                  onSearch={searchModels}
                  onOptionSelect={(option: CatalogOption | null) => {
                    setCatalogIds((current) => ({
                      ...current,
                      modelUuid: option?.uuid ?? '',
                      variantUuid: '',
                      colorUuid: '',
                    }));
                    if (option) setVehicleForm((current) => ({ ...current, model: option.name, variant: '', color: '' }));
                  }}
                />
              </div>
              <div className="form-grid">
                <CatalogCombobox
                  label="Variant (optional)"
                  placeholder={catalogIds.modelUuid ? 'Start typing variant…' : 'Select model first'}
                  value={vehicleForm.variant}
                  disabled={!catalogIds.modelUuid}
                  onValueChange={(variant) => setVehicleForm({ ...vehicleForm, variant })}
                  onSearch={searchVariants}
                  onOptionSelect={(option: CatalogOption | null) => {
                    setCatalogIds((current) => ({
                      ...current,
                      variantUuid: option?.uuid ?? '',
                      colorUuid: '',
                    }));
                    if (option) {
                      setVehicleForm((current) => ({
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
                  value={vehicleForm.color}
                  onValueChange={(color) => setVehicleForm({ ...vehicleForm, color })}
                  onSearch={searchColors}
                  onOptionSelect={(option: CatalogOption | null) => {
                    setCatalogIds((current) => ({ ...current, colorUuid: option?.uuid ?? '' }));
                    if (option) setVehicleForm((current) => ({ ...current, color: option.name }));
                  }}
                />
              </div>
              <div>
                <FieldLabel>Fuel</FieldLabel>
                <SelectInput
                  value={vehicleForm.fuel_type}
                  onChange={(event) => setVehicleForm({ ...vehicleForm, fuel_type: event.target.value })}
                >
                  <option value="petrol">Petrol</option>
                  <option value="diesel">Diesel</option>
                  <option value="cng">CNG</option>
                  <option value="electric">Electric</option>
                  <option value="hybrid">Hybrid</option>
                </SelectInput>
              </div>
              <Button type="button" onClick={() => void createVehicle()} disabled={submitting}>
                Save vehicle
              </Button>
            </div>
          ) : null}

          <div className="stack mt-3">
            {vehicles.map((vehicle) => (
              <button
                key={String(vehicle.uuid)}
                type="button"
                className={`chip ${selectedVehicle?.uuid === vehicle.uuid ? 'active' : ''}`}
                onClick={() => {
                  setSelectedVehicle(vehicle);
                  setStep(2);
                }}
              >
                {vehicleLabel(vehicle)}
              </button>
            ))}
          </div>
        </Card>
      ) : null}

      {step === 2 ? (
        <Card>
          <h3>Job details</h3>
          <div className="form-grid mt-3">
            <div>
              <FieldLabel>Priority</FieldLabel>
              <SelectInput value={priority} onChange={(event) => setPriority(event.target.value)}>
                <option value="low">Low</option>
                <option value="normal">Normal</option>
                <option value="urgent">Urgent</option>
                <option value="critical">Critical</option>
              </SelectInput>
            </div>
            <div className="form-span-full">
              <FieldLabel>Customer complaint</FieldLabel>
              <TextArea rows={4} value={complaint} onChange={(event) => setComplaint(event.target.value)} />
            </div>
            <div className="form-span-full">
              <label className="line-item">
                <span>Insurance job</span>
                <input
                  type="checkbox"
                  checked={isInsuranceJob}
                  onChange={(event) => setIsInsuranceJob(event.target.checked)}
                />
              </label>
            </div>
            {isInsuranceJob ? (
              <>
                <div>
                  <FieldLabel>Insurance company</FieldLabel>
                  <TextInput value={insuranceCompany} onChange={(event) => setInsuranceCompany(event.target.value)} />
                </div>
                <div>
                  <FieldLabel>Claim number</FieldLabel>
                  <TextInput value={claimNumber} onChange={(event) => setClaimNumber(event.target.value)} />
                </div>
              </>
            ) : null}
            <div className="form-span-full">
              <FieldLabel>Service categories</FieldLabel>
              <div className="stack">
                {categories.map((category) => (
                  <label key={String(category.uuid)} className="line-item">
                    <span>{String(category.name ?? category.code)}</span>
                    <input
                      type="checkbox"
                      checked={selectedCategories.includes(String(category.uuid))}
                      onChange={() => toggleCategory(String(category.uuid))}
                    />
                  </label>
                ))}
              </div>
            </div>
          </div>

          <div className="toolbar mt-4">
            <Button type="button" variant="outline" onClick={() => setStep(1)}>
              Back
            </Button>
            <Link to="/jobs">
              <Button type="button" variant="ghost">
                Cancel
              </Button>
            </Link>
            <Button type="button" onClick={() => void submitJob()} disabled={submitting}>
              {submitting ? 'Creating...' : 'Create job'}
            </Button>
          </div>
        </Card>
      ) : null}

      {error ? <p className="error-text">{error}</p> : null}
    </StaffPage>
  );
}
