import { useCallback, useEffect, useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Alert, Button, Card, Modal } from '@/components/ui';
import { CatalogCombobox } from '@/components/ui/CatalogCombobox';
import { FieldLabel, SelectInput, TextInput } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiFormRequest, apiRequest, asData, type JsonMap } from '@/lib/api';
import { useDetail } from '@/lib/hooks';
import {
  searchCatalogColors,
  searchCatalogMakes,
  searchCatalogModels,
  searchCatalogVariants,
  type CatalogOption,
} from '@/lib/vehicle-catalog';
import { customerName, vehicleLabel } from '@/lib/format';

const FUEL_TYPES = [
  { value: 'petrol', label: 'Petrol' },
  { value: 'diesel', label: 'Diesel' },
  { value: 'cng', label: 'CNG' },
  { value: 'lpg', label: 'LPG' },
  { value: 'electric', label: 'Electric' },
  { value: 'hybrid', label: 'Hybrid' },
];

const DOC_TYPES = [
  { value: 'rc', label: 'Registration (RC)' },
  { value: 'insurance', label: 'Insurance' },
  { value: 'puc', label: 'PUC' },
  { value: 'fitness', label: 'Fitness' },
  { value: 'permit', label: 'Permit' },
  { value: 'other', label: 'Other' },
];

export function VehicleDetailPage() {
  const { uuid = '' } = useParams();
  const token = useStaffToken();
  const queryClient = useQueryClient();
  const detailQuery = useDetail(`/vehicles/${uuid}`, token, uuid.length > 0);
  const vehicle = asData<JsonMap>(detailQuery.data ?? {});

  const documentsQuery = useQuery({
    queryKey: ['vehicle-documents', uuid, token],
    enabled: uuid.length > 0 && token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest(`/vehicles/${uuid}/documents`, { token });
      return asData<JsonMap[]>(payload) ?? [];
    },
  });

  const [odometer, setOdometer] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();
  const [message, setMessage] = useState<string>();
  const [showEdit, setShowEdit] = useState(false);
  const [showUpload, setShowUpload] = useState(false);
  const [editForm, setEditForm] = useState({
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
  const [docForm, setDocForm] = useState({
    document_type: 'rc',
    document_number: '',
    file: null as File | null,
  });

  const documents = documentsQuery.data ?? [];
  const customer = (vehicle.customer as JsonMap | undefined) ?? {};

  const yearFilter = useMemo(() => {
    const year = Number(editForm.year);
    return Number.isFinite(year) && year >= 1900 ? year : undefined;
  }, [editForm.year]);

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

  useEffect(() => {
    if (!vehicle.uuid) {
      return;
    }
    setEditForm({
      maker: String(vehicle.maker ?? ''),
      model: String(vehicle.model ?? ''),
      variant: String(vehicle.variant ?? ''),
      year: String(vehicle.year ?? ''),
      color: String(vehicle.color ?? ''),
      fuel_type: String(vehicle.fuel_type ?? 'petrol'),
    });
    setCatalogIds({
      makeUuid: String((vehicle.vehicle_make as JsonMap | undefined)?.uuid ?? vehicle.vehicle_make_uuid ?? ''),
      modelUuid: String((vehicle.vehicle_model as JsonMap | undefined)?.uuid ?? vehicle.vehicle_model_uuid ?? ''),
      variantUuid: String((vehicle.vehicle_variant as JsonMap | undefined)?.uuid ?? vehicle.vehicle_variant_uuid ?? ''),
      colorUuid: String((vehicle.vehicle_color as JsonMap | undefined)?.uuid ?? vehicle.vehicle_color_uuid ?? ''),
    });
  }, [vehicle]);

  async function refreshVehicle() {
    await queryClient.invalidateQueries({ queryKey: ['detail', `/vehicles/${uuid}`] });
    await documentsQuery.refetch();
  }

  async function updateOdometer() {
    const value = Number(odometer.replace(/,/g, ''));
    if (!Number.isFinite(value) || value <= 0) {
      setError('Enter a valid odometer reading.');
      return;
    }
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/vehicles/${uuid}/odometer`, {
        method: 'PATCH',
        token,
        body: { odometer_value_km: value, source: 'admin_override' },
      });
      await refreshVehicle();
      setOdometer('');
      setMessage('Odometer updated.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function saveVehicleEdit(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/vehicles/${uuid}`, {
        method: 'PATCH',
        token,
        body: {
          maker: editForm.maker.trim(),
          model: editForm.model.trim(),
          fuel_type: editForm.fuel_type,
          ...(editForm.variant.trim() ? { variant: editForm.variant.trim() } : {}),
          ...(editForm.year.trim() ? { year: Number(editForm.year) } : {}),
          ...(editForm.color.trim() ? { color: editForm.color.trim() } : {}),
          ...(catalogIds.makeUuid ? { vehicle_make_uuid: catalogIds.makeUuid } : {}),
          ...(catalogIds.modelUuid ? { vehicle_model_uuid: catalogIds.modelUuid } : {}),
          ...(catalogIds.variantUuid ? { vehicle_variant_uuid: catalogIds.variantUuid } : {}),
          ...(catalogIds.colorUuid ? { vehicle_color_uuid: catalogIds.colorUuid } : {}),
        },
      });
      await refreshVehicle();
      setShowEdit(false);
      setMessage('Vehicle details saved.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function deactivateVehicle() {
    if (!window.confirm('Deactivate this vehicle? It will be hidden from active lists.')) {
      return;
    }
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/vehicles/${uuid}`, { method: 'DELETE', token });
      await refreshVehicle();
      setMessage('Vehicle deactivated.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function uploadDocument(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(undefined);
    try {
      const formData = new FormData();
      formData.append('document_type', docForm.document_type);
      if (docForm.document_number.trim()) {
        formData.append('document_number', docForm.document_number.trim());
      }
      if (docForm.file) {
        formData.append('file', docForm.file);
      }
      await apiFormRequest(`/vehicles/${uuid}/documents`, { method: 'POST', token, formData });
      await documentsQuery.refetch();
      setShowUpload(false);
      setDocForm({ document_type: 'rc', document_number: '', file: null });
      setMessage('Document uploaded.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function deleteDocument(docUuid: string) {
    if (!window.confirm('Delete this document?')) {
      return;
    }
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/vehicles/${uuid}/documents/${docUuid}`, { method: 'DELETE', token });
      await documentsQuery.refetch();
      setMessage('Document removed.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <StaffPage title={vehicleLabel(vehicle)} subtitle="Vehicle detail and documents">
      <div className="toolbar">
        <Link to="/vehicles">
          <Button type="button" variant="outline">
            Back
          </Button>
        </Link>
        <Button type="button" variant="outline" onClick={() => setShowEdit(true)}>
          Edit vehicle
        </Button>
        {customer.uuid ? (
          <Link to={`/customers/${String(customer.uuid)}`}>
            <Button type="button" variant="outline">
              View customer
            </Button>
          </Link>
        ) : null}
        {vehicle.is_active !== false ? (
          <Button type="button" variant="ghost" onClick={() => void deactivateVehicle()} disabled={saving}>
            Deactivate
          </Button>
        ) : null}
      </div>

      {message ? <Alert variant="success">{message}</Alert> : null}
      {error ? <Alert variant="error">{error}</Alert> : null}
      {detailQuery.isLoading ? <p className="muted">Loading vehicle...</p> : null}

      <div className="detail-grid">
        <Card>
          <h3>Details</h3>
          <div className="stack mt-3">
            <div className="line-item">
              <span>Registration</span>
              <span>{String(vehicle.registration_number ?? '-')}</span>
            </div>
            <div className="line-item">
              <span>Make / model</span>
              <span>
                {String(vehicle.maker ?? '')} {String(vehicle.model ?? '')}
              </span>
            </div>
            <div className="line-item">
              <span>Year</span>
              <span>{String(vehicle.year ?? '-')}</span>
            </div>
            <div className="line-item">
              <span>Fuel</span>
              <span>{String(vehicle.fuel_type ?? '-')}</span>
            </div>
            <div className="line-item">
              <span>Customer</span>
              <span>{customerName(customer)}</span>
            </div>
            <div className="line-item">
              <span>Odometer</span>
              <span>{String(vehicle.odometer_reading ?? '-')} km</span>
            </div>
            <div className="line-item">
              <span>Status</span>
              <span>{vehicle.is_active === false ? 'Inactive' : 'Active'}</span>
            </div>
          </div>
        </Card>

        <Card>
          <h3>Update odometer</h3>
          <div className="form-grid mt-3">
            <div>
              <FieldLabel htmlFor="odometer">Reading (km)</FieldLabel>
              <TextInput id="odometer" value={odometer} onChange={(event) => setOdometer(event.target.value)} />
            </div>
            <Button type="button" onClick={() => void updateOdometer()} disabled={saving}>
              {saving ? 'Saving...' : 'Update odometer'}
            </Button>
          </div>
        </Card>
      </div>

      <Card>
        <div className="section-header">
          <h3>Documents</h3>
          <Button type="button" onClick={() => setShowUpload(true)}>
            Upload document
          </Button>
        </div>
        {documentsQuery.isLoading ? <p className="muted">Loading documents...</p> : null}
        {!documentsQuery.isLoading && documents.length === 0 ? <p className="muted">No documents uploaded.</p> : null}
        <div className="stack mt-3">
          {documents.map((doc) => (
            <div key={String(doc.uuid)} className="line-item">
              <span>
                {String(doc.document_type ?? 'Document')} · {String(doc.document_number ?? '-')}
              </span>
              <div className="inline-actions">
                {doc.file_url ? (
                  <a href={String(doc.file_url)} target="_blank" rel="noreferrer">
                    View
                  </a>
                ) : null}
                <Button type="button" variant="ghost" onClick={() => void deleteDocument(String(doc.uuid))}>
                  Delete
                </Button>
              </div>
            </div>
          ))}
        </div>
      </Card>

      <Modal
        open={showEdit}
        onClose={() => setShowEdit(false)}
        title="Edit vehicle"
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setShowEdit(false)}>
              Cancel
            </Button>
            <Button type="submit" form="edit-vehicle-form" disabled={saving}>
              {saving ? 'Saving...' : 'Save vehicle'}
            </Button>
          </>
        }
      >
        <form id="edit-vehicle-form" className="form-grid form-grid--stack" onSubmit={(event) => void saveVehicleEdit(event)}>
          <div className="form-grid">
            <div>
              <FieldLabel htmlFor="edit-year">Year</FieldLabel>
              <TextInput
                id="edit-year"
                value={editForm.year}
                onChange={(event) => {
                  const year = event.target.value.replace(/\D/g, '').slice(0, 4);
                  setEditForm({ ...editForm, year });
                  setCatalogIds({ makeUuid: '', modelUuid: '', variantUuid: '', colorUuid: '' });
                }}
              />
            </div>
            <div>
              <FieldLabel htmlFor="edit-fuel">Fuel type</FieldLabel>
              <SelectInput
                id="edit-fuel"
                value={editForm.fuel_type}
                onChange={(event) => setEditForm({ ...editForm, fuel_type: event.target.value })}
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
            <CatalogCombobox
              label="Make"
              placeholder="Start typing make…"
              value={editForm.maker}
              onValueChange={(maker) => setEditForm({ ...editForm, maker })}
              onSearch={searchMakes}
              onOptionSelect={(option: CatalogOption | null) => {
                setCatalogIds({
                  makeUuid: option?.uuid ?? '',
                  modelUuid: '',
                  variantUuid: '',
                  colorUuid: '',
                });
                if (option) setEditForm((current) => ({ ...current, maker: option.name, model: '', variant: '', color: '' }));
              }}
            />
            <CatalogCombobox
              label="Model"
              placeholder={catalogIds.makeUuid ? 'Start typing model…' : 'Select make first'}
              value={editForm.model}
              disabled={!catalogIds.makeUuid}
              onValueChange={(model) => setEditForm({ ...editForm, model })}
              onSearch={searchModels}
              onOptionSelect={(option: CatalogOption | null) => {
                setCatalogIds((current) => ({
                  ...current,
                  modelUuid: option?.uuid ?? '',
                  variantUuid: '',
                  colorUuid: '',
                }));
                if (option) setEditForm((current) => ({ ...current, model: option.name, variant: '', color: '' }));
              }}
            />
          </div>
          <div className="form-grid">
            <CatalogCombobox
              label="Variant (optional)"
              placeholder={catalogIds.modelUuid ? 'Start typing variant…' : 'Select model first'}
              value={editForm.variant}
              disabled={!catalogIds.modelUuid}
              onValueChange={(variant) => setEditForm({ ...editForm, variant })}
              onSearch={searchVariants}
              onOptionSelect={(option: CatalogOption | null) => {
                setCatalogIds((current) => ({
                  ...current,
                  variantUuid: option?.uuid ?? '',
                  colorUuid: '',
                }));
                if (option) {
                  setEditForm((current) => ({
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
              value={editForm.color}
              onValueChange={(color) => setEditForm({ ...editForm, color })}
              onSearch={searchColors}
              onOptionSelect={(option: CatalogOption | null) => {
                setCatalogIds((current) => ({ ...current, colorUuid: option?.uuid ?? '' }));
                if (option) setEditForm((current) => ({ ...current, color: option.name }));
              }}
            />
          </div>
        </form>
      </Modal>

      <Modal
        open={showUpload}
        onClose={() => setShowUpload(false)}
        title="Upload document"
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setShowUpload(false)}>
              Cancel
            </Button>
            <Button type="submit" form="upload-doc-form" disabled={saving}>
              {saving ? 'Uploading...' : 'Upload'}
            </Button>
          </>
        }
      >
        <form id="upload-doc-form" className="form-grid form-grid--stack" onSubmit={(event) => void uploadDocument(event)}>
          <div>
            <FieldLabel htmlFor="doc-type">Document type</FieldLabel>
            <SelectInput
              id="doc-type"
              value={docForm.document_type}
              onChange={(event) => setDocForm({ ...docForm, document_type: event.target.value })}
            >
              {DOC_TYPES.map((type) => (
                <option key={type.value} value={type.value}>
                  {type.label}
                </option>
              ))}
            </SelectInput>
          </div>
          <div>
            <FieldLabel htmlFor="doc-number">Document number</FieldLabel>
            <TextInput
              id="doc-number"
              value={docForm.document_number}
              onChange={(event) => setDocForm({ ...docForm, document_number: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="doc-file">File (PDF or image)</FieldLabel>
            <input
              id="doc-file"
              type="file"
              accept=".pdf,.jpg,.jpeg,.png"
              onChange={(event) => setDocForm({ ...docForm, file: event.target.files?.[0] ?? null })}
            />
          </div>
        </form>
      </Modal>
    </StaffPage>
  );
}
