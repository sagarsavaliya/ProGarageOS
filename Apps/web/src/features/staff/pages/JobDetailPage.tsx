import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Button, Card, StatusBadge, Alert, LoadingState } from '@/components/ui';
import { FieldLabel, SelectInput, TextArea } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest, asData, type JsonMap } from '@/lib/api';
import { useDetail } from '@/lib/hooks';
import { customerName, money, vehicleLabel } from '@/lib/format';

const STATUS_OPTIONS = [
  'intake_inspection',
  'estimate_pending',
  'estimate_approved',
  'in_progress',
  'qc_pending',
  'ready_for_delivery',
  'delivered',
  'on_hold',
  'cancelled',
];

export function JobDetailPage() {
  const { uuid = '' } = useParams();
  const token = useStaffToken();
  const queryClient = useQueryClient();
  const detailQuery = useDetail(`/jobs/${uuid}`, token, uuid.length > 0);
  const job = asData<JsonMap>(detailQuery.data ?? {});

  const tasksQuery = useQuery({
    queryKey: ['job-tasks', uuid, token],
    enabled: uuid.length > 0 && token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest(`/jobs/${uuid}/tasks`, { token });
      return asData<JsonMap[]>(payload) ?? [];
    },
  });

  const [status, setStatus] = useState('');
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();

  const invoiceUuid =
    (job.invoice_uuid as string | undefined) ??
    ((job.invoice as JsonMap | undefined)?.uuid as string | undefined);
  const insurance = (job.insurance_claim as JsonMap | undefined) ?? {};
  const customer = (job.customer as JsonMap | undefined) ?? {};
  const vehicle = (job.vehicle as JsonMap | undefined) ?? {};
  const tasks = tasksQuery.data ?? [];

  async function updateStatus() {
    if (!status) {
      return;
    }
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/jobs/${uuid}/status`, {
        method: 'PATCH',
        token,
        body: { status, ...(notes.trim() ? { notes: notes.trim() } : {}) },
      });
      await queryClient.invalidateQueries({ queryKey: ['detail', `/jobs/${uuid}`] });
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <StaffPage title={`Job ${String(job.job_number ?? uuid)}`} subtitle="Job detail and actions">
      {detailQuery.isLoading ? <LoadingState label="Loading job..." /> : null}
      {detailQuery.isError ? <Alert variant="error">Could not load job.</Alert> : null}

      <div className="toolbar">
        <Link to="/jobs">
          <Button type="button" variant="outline">
            Back to jobs
          </Button>
        </Link>
        <Link to={`/jobs/${uuid}/inspection`}>
          <Button type="button">Inspection</Button>
        </Link>
        {invoiceUuid ? (
          <Link to={`/billing/${invoiceUuid}`}>
            <Button type="button" variant="outline">
              Invoice
            </Button>
          </Link>
        ) : null}
      </div>

      <div className="detail-grid">
        <Card>
          <h3>Overview</h3>
          <div className="stack" style={{ marginTop: 12 }}>
            <div className="line-item">
              <span>Status</span>
              <StatusBadge status={String(job.status ?? 'draft')} />
            </div>
            <div className="line-item">
              <span>Customer</span>
              <Link to={`/customers/${String(customer.uuid ?? job.customer_uuid ?? '')}`}>
                {customerName(customer) || String(job.customer_name ?? '-')}
              </Link>
            </div>
            <div className="line-item">
              <span>Vehicle</span>
              <span>{vehicleLabel(vehicle)}</span>
            </div>
            <div className="line-item">
              <span>Priority</span>
              <span>{String(job.priority ?? 'normal')}</span>
            </div>
            <div className="line-item">
              <span>Complaint</span>
              <span>{String(job.customer_complaint ?? '-')}</span>
            </div>
          </div>
        </Card>

        <Card>
          <h3>Update status</h3>
          <div className="form-grid" style={{ marginTop: 12 }}>
            <div>
              <FieldLabel htmlFor="job-status">New status</FieldLabel>
              <SelectInput id="job-status" value={status} onChange={(event) => setStatus(event.target.value)}>
                <option value="">Select status</option>
                {STATUS_OPTIONS.map((option) => (
                  <option key={option} value={option}>
                    {option.replace(/_/g, ' ')}
                  </option>
                ))}
              </SelectInput>
            </div>
            <div>
              <FieldLabel htmlFor="status-notes">Notes</FieldLabel>
              <TextArea id="status-notes" rows={3} value={notes} onChange={(event) => setNotes(event.target.value)} />
            </div>
            {error ? <Alert variant="error">{error}</Alert> : null}
            <Button type="button" onClick={() => void updateStatus()} disabled={saving || !status}>
              {saving ? 'Saving...' : 'Update status'}
            </Button>
          </div>
        </Card>
      </div>

      <Card>
        <h3>Insurance</h3>
        <div className="detail-grid" style={{ marginTop: 12 }}>
          <div className="line-item">
            <span>Insurance job</span>
            <span>{job.is_insurance_job ? 'Yes' : 'No'}</span>
          </div>
          <div className="line-item">
            <span>Company</span>
            <span>{String(insurance.insurance_company ?? job.insurance_company ?? '-')}</span>
          </div>
          <div className="line-item">
            <span>Claim number</span>
            <span>{String(insurance.claim_number ?? job.claim_number ?? '-')}</span>
          </div>
          <div className="line-item">
            <span>Claim status</span>
            <StatusBadge status={String(insurance.insurance_claim_status ?? 'draft')} />
          </div>
          <div className="line-item">
            <span>Claim amount</span>
            <span>{money(insurance.job_insurance_claim_amount ?? insurance.insurance_claim_amount)}</span>
          </div>
        </div>
      </Card>

      <Card>
        <h3>Tasks</h3>
        {tasksQuery.isLoading ? <LoadingState label="Loading tasks..." /> : null}
        {!tasksQuery.isLoading && tasks.length === 0 ? <p className="muted">No tasks yet.</p> : null}
        <div className="stack" style={{ marginTop: 12 }}>
          {tasks.map((task) => (
            <div key={String(task.id ?? task.uuid)} className="line-item">
              <span>{String(task.title ?? task.name ?? 'Task')}</span>
              <StatusBadge status={String(task.status ?? 'pending')} />
            </div>
          ))}
        </div>
      </Card>
    </StaffPage>
  );
}
