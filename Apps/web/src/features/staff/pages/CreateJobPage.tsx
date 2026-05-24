import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Button, Card } from '@/components/ui';
import { FieldLabel, SelectInput, TextArea, TextInput } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest, asData, normalizeLogin, type JsonMap } from '@/lib/api';
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
  const [complaint, setComplaint] = useState('');
  const [priority, setPriority] = useState('normal');
  const [selectedCategories, setSelectedCategories] = useState<string[]>([]);
  const [vehicleForm, setVehicleForm] = useState({
    registration_number: '',
    maker: '',
    model: '',
    year: '',
    fuel_type: 'petrol',
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string>();

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
          ...(vehicleForm.year ? { year: Number(vehicleForm.year) } : {}),
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
            className="form-grid"
            style={{ marginTop: 12 }}
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
            <div style={{ alignSelf: 'end' }}>
              <Button type="submit">Search</Button>
            </div>
          </form>

          {customersQuery.isLoading ? <p className="muted">Searching...</p> : null}
          <div className="stack" style={{ marginTop: 12 }}>
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
          <div className="toolbar" style={{ marginTop: 12 }}>
            <Button type="button" variant="outline" onClick={() => setStep(0)}>
              Back
            </Button>
            <Button type="button" variant="outline" onClick={() => setShowNewVehicle((value) => !value)}>
              {showNewVehicle ? 'Cancel new vehicle' : 'Add vehicle'}
            </Button>
          </div>

          {showNewVehicle ? (
            <div className="form-grid" style={{ marginTop: 12 }}>
              <div>
                <FieldLabel>Registration</FieldLabel>
                <TextInput
                  value={vehicleForm.registration_number}
                  onChange={(event) => setVehicleForm({ ...vehicleForm, registration_number: event.target.value })}
                />
              </div>
              <div>
                <FieldLabel>Maker</FieldLabel>
                <TextInput
                  value={vehicleForm.maker}
                  onChange={(event) => setVehicleForm({ ...vehicleForm, maker: event.target.value })}
                />
              </div>
              <div>
                <FieldLabel>Model</FieldLabel>
                <TextInput
                  value={vehicleForm.model}
                  onChange={(event) => setVehicleForm({ ...vehicleForm, model: event.target.value })}
                />
              </div>
              <div>
                <FieldLabel>Year</FieldLabel>
                <TextInput
                  value={vehicleForm.year}
                  onChange={(event) => setVehicleForm({ ...vehicleForm, year: event.target.value })}
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
                  <option value="ev">EV</option>
                </SelectInput>
              </div>
              <Button type="button" onClick={() => void createVehicle()} disabled={submitting}>
                Save vehicle
              </Button>
            </div>
          ) : null}

          <div className="stack" style={{ marginTop: 12 }}>
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
          <div className="form-grid" style={{ marginTop: 12 }}>
            <div>
              <FieldLabel>Priority</FieldLabel>
              <SelectInput value={priority} onChange={(event) => setPriority(event.target.value)}>
                <option value="low">Low</option>
                <option value="normal">Normal</option>
                <option value="high">High</option>
                <option value="urgent">Urgent</option>
              </SelectInput>
            </div>
            <div style={{ gridColumn: '1 / -1' }}>
              <FieldLabel>Customer complaint</FieldLabel>
              <TextArea rows={4} value={complaint} onChange={(event) => setComplaint(event.target.value)} />
            </div>
            <div style={{ gridColumn: '1 / -1' }}>
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

          <div className="toolbar" style={{ marginTop: 16 }}>
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
