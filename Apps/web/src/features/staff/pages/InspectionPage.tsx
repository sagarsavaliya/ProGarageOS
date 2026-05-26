import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Button, Card } from '@/components/ui';
import { FieldLabel, SelectInput, TextArea } from '@/components/ui/FormField';
import { WebcamCapture } from '@/features/staff/components/WebcamCapture';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { API_BASE_URL, apiRequest, asData, type JsonMap } from '@/lib/api';
import { uploadMultipart } from '@/lib/upload';

type ChecklistItem = {
  id: string;
  group: string;
  name: string;
};

const PHOTO_SLOTS = [
  { slot: 'front', label: 'Front' },
  { slot: 'rear', label: 'Rear' },
  { slot: 'left', label: 'Left side' },
  { slot: 'right', label: 'Right side' },
];

export function InspectionPage() {
  const { uuid = '' } = useParams();
  const token = useStaffToken();
  const phase = 'intake';

  const [conditions, setConditions] = useState<Record<string, string>>({});
  const [notes, setNotes] = useState('');
  const [acknowledged, setAcknowledged] = useState(false);
  const [uploadedPhotos, setUploadedPhotos] = useState<Record<string, string>>({});
  const [uploadingSlot, setUploadingSlot] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [pdfLoading, setPdfLoading] = useState(false);
  const [error, setError] = useState<string>();
  const [message, setMessage] = useState<string>();

  const inspectionQuery = useQuery({
    queryKey: ['inspection', uuid, phase, token],
    enabled: uuid.length > 0 && token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest(`/jobs/${uuid}/inspections`, { token, query: { phase } });
      return asData<JsonMap>(payload);
    },
  });

  const templateQuery = useQuery({
    queryKey: ['inspection-templates', phase, token],
    enabled: token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/inspection-templates', { token, query: { phase } });
      const data = asData<JsonMap>(payload);
      const items = (data.items as JsonMap[] | undefined) ?? (Array.isArray(data) ? data : []);
      return items.map((item) => ({
        id: String(item.component_key ?? item.id ?? ''),
        group: String(item.category ?? 'General'),
        name: String(item.component_name ?? item.name ?? ''),
      })) as ChecklistItem[];
    },
  });

  useEffect(() => {
    const data = inspectionQuery.data;
    if (!data) {
      return;
    }
    setNotes(String(data.notes ?? ''));
    setAcknowledged(Boolean(data.customer_acknowledged));
    const nextConditions: Record<string, string> = {};
    for (const item of (data.items as JsonMap[] | undefined) ?? []) {
      nextConditions[String(item.component_key)] = String(item.condition_status ?? 'na');
    }
    setConditions(nextConditions);
    const nextPhotos: Record<string, string> = {};
    for (const photo of (data.photos as JsonMap[] | undefined) ?? []) {
      nextPhotos[String(photo.slot)] = String(photo.url ?? photo.file_url ?? 'uploaded');
    }
    setUploadedPhotos(nextPhotos);
  }, [inspectionQuery.data]);

  const checklist = templateQuery.data ?? [];

  async function uploadPhoto(slot: string, label: string, file: File) {
    setUploadingSlot(slot);
    setError(undefined);
    try {
      const formData = new FormData();
      formData.append('slot', slot);
      formData.append('label', label);
      formData.append('phase', phase);
      formData.append('photo', file);
      await uploadMultipart(`/jobs/${uuid}/inspections/photos`, token, formData);
      setUploadedPhotos((current) => ({ ...current, [slot]: file.name }));
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setUploadingSlot(null);
    }
  }

  async function saveInspection() {
    setSaving(true);
    setError(undefined);
    setMessage(undefined);
    try {
      await apiRequest(`/jobs/${uuid}/inspections`, {
        method: 'POST',
        token,
        body: {
          inspection_phase: phase,
          customer_acknowledged: acknowledged,
          ...(notes.trim() ? { notes: notes.trim() } : {}),
          items: checklist.map((item) => ({
            component_key: item.id,
            component_name: item.name,
            category: item.group,
            condition_status: conditions[item.id] ?? 'na',
            severity: conditions[item.id] === 'damaged' ? 'moderate' : 'none',
          })),
          damage_zones: [],
          photos: Object.entries(uploadedPhotos).map(([slot, label]) => ({ slot, label })),
        },
      });
      setMessage('Inspection saved.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function openInspectionPdf() {
    setPdfLoading(true);
    setError(undefined);
    try {
      const payload = await apiRequest(`/jobs/${uuid}/inspections/pdf`, { token, query: { phase } });
      const data = asData<JsonMap>(payload);
      const url = String(data.pdf_url ?? data.url ?? '');
      if (!url) {
        throw new Error('Inspection PDF not available yet.');
      }
      window.open(url.startsWith('http') ? url : `${API_BASE_URL.replace('/api', '')}${url}`, '_blank');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setPdfLoading(false);
    }
  }

  return (
    <StaffPage title="Intake inspection" subtitle="Checklist, photos, and customer acknowledgement">
      <div className="toolbar">
        <Link to={`/jobs/${uuid}`}>
          <Button type="button" variant="outline">
            Back to job
          </Button>
        </Link>
        <Button type="button" variant="outline" onClick={() => void openInspectionPdf()} disabled={pdfLoading}>
          {pdfLoading ? 'Loading PDF...' : 'Download PDF'}
        </Button>
        <Button type="button" onClick={() => void saveInspection()} disabled={saving}>
          {saving ? 'Saving...' : 'Save inspection'}
        </Button>
      </div>

      {inspectionQuery.isLoading || templateQuery.isLoading ? <p className="muted">Loading inspection...</p> : null}
      {message ? <p className="muted">{message}</p> : null}
      {error ? <p className="error-text">{error}</p> : null}

      <div className="detail-grid">
        <Card>
          <h3>Checklist</h3>
          <div className="stack mt-3">
            {checklist.map((item) => (
              <div key={item.id} className="line-item">
                <span>
                  <small className="muted">{item.group}</small>
                  <br />
                  {item.name}
                </span>
                <SelectInput
                  value={conditions[item.id] ?? 'na'}
                  onChange={(event) => setConditions({ ...conditions, [item.id]: event.target.value })}
                >
                  <option value="na">N/A</option>
                  <option value="good">Good</option>
                  <option value="fair">Fair</option>
                  <option value="damaged">Damaged</option>
                </SelectInput>
              </div>
            ))}
          </div>
        </Card>

        <Card>
          <h3>Notes & acknowledgement</h3>
          <div className="form-grid mt-3">
            <div>
              <FieldLabel>Notes</FieldLabel>
              <TextArea rows={4} value={notes} onChange={(event) => setNotes(event.target.value)} />
            </div>
            <label className="line-item">
              <span>Customer acknowledged</span>
              <input type="checkbox" checked={acknowledged} onChange={(event) => setAcknowledged(event.target.checked)} />
            </label>
          </div>
        </Card>
      </div>

      <Card>
        <h3>Vehicle photos</h3>
        <div className="detail-grid mt-3">
          {PHOTO_SLOTS.map((slot) => (
            <div key={slot.slot}>
              <h4>{slot.label}</h4>
              {uploadedPhotos[slot.slot] ? <p className="muted">Uploaded: {uploadedPhotos[slot.slot]}</p> : null}
              <WebcamCapture
                disabled={uploadingSlot === slot.slot}
                onCapture={(file) => void uploadPhoto(slot.slot, slot.label, file)}
              />
            </div>
          ))}
        </div>
      </Card>
    </StaffPage>
  );
}
