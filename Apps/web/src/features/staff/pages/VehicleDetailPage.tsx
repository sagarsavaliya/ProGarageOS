import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Button, Card } from '@/components/ui';
import { FieldLabel, TextInput } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest, asData, type JsonMap } from '@/lib/api';
import { useDetail } from '@/lib/hooks';
import { customerName, vehicleLabel } from '@/lib/format';

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

  const documents = documentsQuery.data ?? [];
  const customer = (vehicle.customer as JsonMap | undefined) ?? {};

  async function updateOdometer() {
    const value = Number(odometer.replace(/,/g, ''));
    if (!Number.isFinite(value) || value <= 0) {
      setError('Enter a valid odometer reading.');
      return;
    }
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/vehicles/${uuid}`, {
        method: 'PATCH',
        token,
        body: { odometer_reading: value },
      });
      await queryClient.invalidateQueries({ queryKey: ['detail', `/vehicles/${uuid}`] });
      setOdometer('');
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
        {customer.uuid ? (
          <Link to={`/customers/${String(customer.uuid)}`}>
            <Button type="button" variant="outline">
              View customer
            </Button>
          </Link>
        ) : null}
      </div>

      {detailQuery.isLoading ? <p className="muted">Loading vehicle...</p> : null}

      <div className="detail-grid">
        <Card>
          <h3>Details</h3>
          <div className="stack" style={{ marginTop: 12 }}>
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
              <span>Customer</span>
              <span>{customerName(customer)}</span>
            </div>
            <div className="line-item">
              <span>Odometer</span>
              <span>{String(vehicle.odometer_reading ?? '-')}</span>
            </div>
          </div>
        </Card>

        <Card>
          <h3>Update odometer</h3>
          <div className="form-grid" style={{ marginTop: 12 }}>
            <div>
              <FieldLabel htmlFor="odometer">Reading (km)</FieldLabel>
              <TextInput id="odometer" value={odometer} onChange={(event) => setOdometer(event.target.value)} />
            </div>
            {error ? <p className="error-text">{error}</p> : null}
            <Button type="button" onClick={() => void updateOdometer()} disabled={saving}>
              {saving ? 'Saving...' : 'Update odometer'}
            </Button>
          </div>
        </Card>
      </div>

      <Card>
        <h3>Documents</h3>
        {documentsQuery.isLoading ? <p className="muted">Loading documents...</p> : null}
        {!documentsQuery.isLoading && documents.length === 0 ? <p className="muted">No documents uploaded.</p> : null}
        <div className="stack" style={{ marginTop: 12 }}>
          {documents.map((doc) => (
            <div key={String(doc.uuid)} className="line-item">
              <span>
                {String(doc.document_type ?? 'Document')} · {String(doc.document_number ?? '-')}
              </span>
              {doc.file_url ? (
                <a href={String(doc.file_url)} target="_blank" rel="noreferrer">
                  View
                </a>
              ) : null}
            </div>
          ))}
        </div>
      </Card>
    </StaffPage>
  );
}
