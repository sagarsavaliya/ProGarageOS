import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Alert,
  Button,
  Card,
  LoadingState,
  Modal,
  StatusBadge,
  Table,
  THead,
  TRow,
  TH,
  TD,
} from '@/components/ui';
import { FieldLabel, SelectInput, TextArea, TextInput } from '@/components/ui/FormField';
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

const TASK_STATUS_OPTIONS = ['pending_approval', 'approved', 'in_progress', 'completed', 'cancelled', 'waived'];

const INSURANCE_STATUS_OPTIONS = [
  'none',
  'survey_pending',
  'estimate_submitted',
  'approved',
  'rejected',
  'settled',
];

type EstimateLine = {
  id: number;
  name: string;
  estimated_price: number;
  final_price: number;
  labor_minutes: number;
};

export function JobDetailPage() {
  const { uuid = '' } = useParams();
  const token = useStaffToken();
  const navigate = useNavigate();
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

  const estimateQuery = useQuery({
    queryKey: ['job-estimate', uuid, token],
    enabled: uuid.length > 0 && token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest(`/jobs/${uuid}/estimate`, { token });
      return asData<JsonMap>(payload);
    },
  });

  const techniciansQuery = useQuery({
    queryKey: ['technicians', token],
    enabled: token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/staff/technicians', { token });
      return asData<JsonMap[]>(payload) ?? [];
    },
  });

  const baysQuery = useQuery({
    queryKey: ['service-bays', token],
    enabled: token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/service-bays', { token });
      return asData<JsonMap[]>(payload) ?? [];
    },
  });

  const [status, setStatus] = useState('');
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();
  const [message, setMessage] = useState<string>();

  const [showEditJob, setShowEditJob] = useState(false);
  const [jobForm, setJobForm] = useState({
    priority: 'normal',
    customer_complaint: '',
    primary_technician_uuid: '',
    assigned_bay_uuid: '',
  });

  const [showInsurance, setShowInsurance] = useState(false);
  const [insuranceForm, setInsuranceForm] = useState({
    insurance_claim_status: 'none',
    insurance_company: '',
    claim_number: '',
    job_insurance_claim_amount: '',
    customer_liability_amount: '',
  });

  const [showTaskModal, setShowTaskModal] = useState(false);
  const [editingTaskId, setEditingTaskId] = useState<number | null>(null);
  const [taskForm, setTaskForm] = useState({
    name: '',
    description: '',
    status: 'approved',
    estimated_price: '',
    final_price: '',
    assigned_technician_uuid: '',
  });

  const [estimateLines, setEstimateLines] = useState<EstimateLine[]>([]);
  const [rejectNotes, setRejectNotes] = useState('');

  const invoiceUuid =
    (job.invoice_uuid as string | undefined) ??
    ((job.invoice as JsonMap | undefined)?.uuid as string | undefined);
  const insurance = (job.insurance_claim as JsonMap | undefined) ?? {};
  const customer = (job.customer as JsonMap | undefined) ?? {};
  const vehicle = (job.vehicle as JsonMap | undefined) ?? {};
  const tasks = tasksQuery.data ?? [];
  const estimate = estimateQuery.data ?? {};
  const technicians = techniciansQuery.data ?? [];
  const bays = baysQuery.data ?? [];

  useEffect(() => {
    if (!job.uuid) {
      return;
    }
    setJobForm({
      priority: String(job.priority ?? 'normal'),
      customer_complaint: String(job.customer_complaint ?? ''),
      primary_technician_uuid: String(
        (job.primary_technician as JsonMap | undefined)?.uuid ?? job.primary_technician_uuid ?? '',
      ),
      assigned_bay_uuid: String((job.assigned_bay as JsonMap | undefined)?.uuid ?? job.assigned_bay_uuid ?? ''),
    });
    setInsuranceForm({
      insurance_claim_status: String(insurance.insurance_claim_status ?? job.insurance_claim_status ?? 'none'),
      insurance_company: String(insurance.insurance_company ?? job.insurance_company ?? ''),
      claim_number: String(insurance.claim_number ?? job.claim_number ?? ''),
      job_insurance_claim_amount: String(insurance.job_insurance_claim_amount ?? ''),
      customer_liability_amount: String(insurance.customer_liability_amount ?? ''),
    });
  }, [job, insurance]);

  useEffect(() => {
    const lines = (estimate.lines as JsonMap[] | undefined) ?? [];
    if (lines.length === 0) {
      return;
    }
    setEstimateLines(
      lines.map((line) => ({
        id: Number(line.id),
        name: String(line.name ?? 'Task'),
        estimated_price: Number(line.estimated_price ?? 0),
        final_price: Number(line.final_price ?? line.estimated_price ?? 0),
        labor_minutes: Number(line.labor_minutes ?? 0),
      })),
    );
  }, [estimate]);

  async function invalidateJob() {
    await queryClient.invalidateQueries({ queryKey: ['detail', `/jobs/${uuid}`] });
    await tasksQuery.refetch();
    await estimateQuery.refetch();
  }

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
      await invalidateJob();
      setMessage('Job status updated.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function saveJobEdit(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/jobs/${uuid}`, {
        method: 'PUT',
        token,
        body: {
          priority: jobForm.priority,
          customer_complaint: jobForm.customer_complaint.trim() || null,
          primary_technician_uuid: jobForm.primary_technician_uuid || null,
          assigned_bay_uuid: jobForm.assigned_bay_uuid || null,
        },
      });
      await invalidateJob();
      setShowEditJob(false);
      setMessage('Job details saved.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function saveInsurance(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/jobs/${uuid}/insurance-claim`, {
        method: 'PATCH',
        token,
        body: {
          insurance_claim_status: insuranceForm.insurance_claim_status,
          insurance_company: insuranceForm.insurance_company.trim() || null,
          claim_number: insuranceForm.claim_number.trim() || null,
          ...(insuranceForm.job_insurance_claim_amount.trim()
            ? { job_insurance_claim_amount: Number(insuranceForm.job_insurance_claim_amount) }
            : {}),
          ...(insuranceForm.customer_liability_amount.trim()
            ? { customer_liability_amount: Number(insuranceForm.customer_liability_amount) }
            : {}),
        },
      });
      await invalidateJob();
      setShowInsurance(false);
      setMessage('Insurance details saved.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  function openTaskModal(task?: JsonMap) {
    if (task) {
      setEditingTaskId(Number(task.id));
      setTaskForm({
        name: String(task.name ?? task.title ?? ''),
        description: String(task.description ?? ''),
        status: String(task.status ?? 'approved'),
        estimated_price: String(task.estimated_price ?? ''),
        final_price: String(task.final_price ?? task.estimated_price ?? ''),
        assigned_technician_uuid: String((task.technician as JsonMap | undefined)?.uuid ?? ''),
      });
    } else {
      setEditingTaskId(null);
      setTaskForm({
        name: '',
        description: '',
        status: 'approved',
        estimated_price: '',
        final_price: '',
        assigned_technician_uuid: '',
      });
    }
    setShowTaskModal(true);
  }

  async function saveTask(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(undefined);
    try {
      const body = {
        name: taskForm.name.trim(),
        description: taskForm.description.trim() || null,
        status: taskForm.status,
        estimated_price: Number(taskForm.estimated_price || 0),
        final_price: Number(taskForm.final_price || taskForm.estimated_price || 0),
        ...(taskForm.assigned_technician_uuid ? { assigned_technician_uuid: taskForm.assigned_technician_uuid } : {}),
      };
      if (editingTaskId) {
        await apiRequest(`/jobs/${uuid}/tasks/${editingTaskId}`, { method: 'PATCH', token, body });
      } else {
        await apiRequest(`/jobs/${uuid}/tasks`, { method: 'POST', token, body });
      }
      await invalidateJob();
      setShowTaskModal(false);
      setMessage(editingTaskId ? 'Task updated.' : 'Task added.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function deleteTask(taskId: number) {
    if (!window.confirm('Remove this task?')) {
      return;
    }
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/jobs/${uuid}/tasks/${taskId}`, { method: 'DELETE', token });
      await invalidateJob();
      setMessage('Task removed.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function saveEstimate() {
    if (estimateLines.length === 0) {
      setError('Add at least one task before saving the estimate.');
      return;
    }
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/jobs/${uuid}/estimate`, {
        method: 'PUT',
        token,
        body: {
          lines: estimateLines.map((line) => ({
            id: line.id,
            estimated_price: line.estimated_price,
            final_price: line.final_price,
            labor_minutes: line.labor_minutes,
          })),
        },
      });
      await estimateQuery.refetch();
      setMessage('Estimate saved.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function sendEstimate() {
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/jobs/${uuid}/estimate/send`, { method: 'POST', token, body: {} });
      await invalidateJob();
      setMessage('Estimate sent to customer.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function approveEstimate() {
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/jobs/${uuid}/estimate/approve`, { method: 'POST', token, body: {} });
      await invalidateJob();
      setMessage('Estimate approved.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function rejectEstimate() {
    if (!rejectNotes.trim()) {
      setError('Enter a reason for rejection.');
      return;
    }
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/jobs/${uuid}/estimate/reject`, {
        method: 'POST',
        token,
        body: { notes: rejectNotes.trim() },
      });
      await invalidateJob();
      setRejectNotes('');
      setMessage('Estimate rejected.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function createInvoice() {
    const billableTasks = tasks.filter((task) => task.is_billable !== false);
    if (billableTasks.length === 0) {
      setError('Add billable tasks before creating an invoice.');
      return;
    }
    setSaving(true);
    setError(undefined);
    try {
      const payload = await apiRequest('/invoices', {
        method: 'POST',
        token,
        body: {
          job_uuid: uuid,
          type: 'final',
          items: billableTasks.map((task) => ({
            line_type: 'service',
            name: String(task.name ?? task.title ?? 'Service'),
            quantity: 1,
            unit_price: Number(task.final_price ?? task.estimated_price ?? 0),
          })),
        },
      });
      const created = asData<JsonMap>(payload);
      await invalidateJob();
      navigate(`/billing/${String(created.uuid)}`);
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
      {message ? <Alert variant="success">{message}</Alert> : null}
      {error ? <Alert variant="error">{error}</Alert> : null}

      <div className="toolbar">
        <Link to="/jobs">
          <Button type="button" variant="outline">
            Back to jobs
          </Button>
        </Link>
        <Link to={`/jobs/${uuid}/inspection`}>
          <Button type="button">Inspection</Button>
        </Link>
        <Button type="button" variant="outline" onClick={() => setShowEditJob(true)}>
          Edit job
        </Button>
        {invoiceUuid ? (
          <Link to={`/billing/${invoiceUuid}`}>
            <Button type="button" variant="outline">
              Invoice
            </Button>
          </Link>
        ) : (
          <Button type="button" variant="outline" onClick={() => void createInvoice()} disabled={saving}>
            Create invoice
          </Button>
        )}
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
              <span>Technician</span>
              <span>{String((job.primary_technician as JsonMap | undefined)?.name ?? job.technician_name ?? '-')}</span>
            </div>
            <div className="line-item">
              <span>Bay</span>
              <span>{String((job.assigned_bay as JsonMap | undefined)?.name ?? '-')}</span>
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
            <Button type="button" onClick={() => void updateStatus()} disabled={saving || !status}>
              {saving ? 'Saving...' : 'Update status'}
            </Button>
          </div>
        </Card>
      </div>

      <Card>
        <div className="section-header">
          <h3>Insurance</h3>
          <Button type="button" variant="outline" onClick={() => setShowInsurance(true)}>
            Edit insurance
          </Button>
        </div>
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
        <div className="section-header">
          <div>
            <h3>Tasks</h3>
            <p className="muted section-subtitle">Work items for this job</p>
          </div>
          <Button type="button" onClick={() => openTaskModal()}>
            Add task
          </Button>
        </div>
        {tasksQuery.isLoading ? <LoadingState label="Loading tasks..." /> : null}
        {!tasksQuery.isLoading && tasks.length === 0 ? <p className="muted">No tasks yet.</p> : null}
        {tasks.length > 0 ? (
          <Table className="table-spaced">
            <THead>
              <TRow>
                <TH>Task</TH>
                <TH>Status</TH>
                <TH>Price</TH>
                <TH>Actions</TH>
              </TRow>
            </THead>
            <tbody>
              {tasks.map((task) => (
                <TRow key={String(task.id ?? task.uuid)}>
                  <TD>{String(task.name ?? task.title ?? 'Task')}</TD>
                  <TD>
                    <StatusBadge status={String(task.status ?? 'pending')} />
                  </TD>
                  <TD>{money(task.final_price ?? task.estimated_price)}</TD>
                  <TD>
                    <div className="inline-actions">
                      <Button type="button" variant="ghost" onClick={() => openTaskModal(task)}>
                        Edit
                      </Button>
                      <Button type="button" variant="ghost" onClick={() => void deleteTask(Number(task.id))}>
                        Remove
                      </Button>
                    </div>
                  </TD>
                </TRow>
              ))}
            </tbody>
          </Table>
        ) : null}
      </Card>

      <Card>
        <div className="section-header">
          <div>
            <h3>Estimate</h3>
            <p className="muted section-subtitle">
              Approval: {String(estimate.approval_status ?? job.approval_status ?? 'draft')} · Total{' '}
              {money(estimate.subtotal ?? estimate.estimated_amount ?? job.estimated_amount)}
            </p>
          </div>
          <div className="inline-actions">
            <Button type="button" variant="outline" onClick={() => void saveEstimate()} disabled={saving || estimateLines.length === 0}>
              Save estimate
            </Button>
            <Button type="button" variant="outline" onClick={() => void sendEstimate()} disabled={saving}>
              Send
            </Button>
            <Button type="button" onClick={() => void approveEstimate()} disabled={saving}>
              Approve
            </Button>
          </div>
        </div>
        {estimateLines.length === 0 ? <p className="muted">Add tasks to build the estimate.</p> : null}
        {estimateLines.length > 0 ? (
          <Table className="table-spaced">
            <THead>
              <TRow>
                <TH>Line</TH>
                <TH>Est. price</TH>
                <TH>Final price</TH>
                <TH>Minutes</TH>
              </TRow>
            </THead>
            <tbody>
              {estimateLines.map((line, index) => (
                <TRow key={line.id}>
                  <TD>{line.name}</TD>
                  <TD>
                    <TextInput
                      value={String(line.estimated_price)}
                      onChange={(event) => {
                        const next = [...estimateLines];
                        next[index] = { ...line, estimated_price: Number(event.target.value) || 0 };
                        setEstimateLines(next);
                      }}
                    />
                  </TD>
                  <TD>
                    <TextInput
                      value={String(line.final_price)}
                      onChange={(event) => {
                        const next = [...estimateLines];
                        next[index] = { ...line, final_price: Number(event.target.value) || 0 };
                        setEstimateLines(next);
                      }}
                    />
                  </TD>
                  <TD>
                    <TextInput
                      value={String(line.labor_minutes)}
                      onChange={(event) => {
                        const next = [...estimateLines];
                        next[index] = { ...line, labor_minutes: Number(event.target.value) || 0 };
                        setEstimateLines(next);
                      }}
                    />
                  </TD>
                </TRow>
              ))}
            </tbody>
          </Table>
        ) : null}
        <div className="form-grid" style={{ marginTop: 16 }}>
          <div>
            <FieldLabel htmlFor="reject-notes">Reject notes</FieldLabel>
            <TextArea
              id="reject-notes"
              rows={2}
              value={rejectNotes}
              onChange={(event) => setRejectNotes(event.target.value)}
              placeholder="Reason if customer rejects estimate"
            />
          </div>
          <Button type="button" variant="outline" onClick={() => void rejectEstimate()} disabled={saving}>
            Reject estimate
          </Button>
        </div>
      </Card>

      <Modal
        open={showEditJob}
        onClose={() => setShowEditJob(false)}
        title="Edit job"
        subtitle="Update assignment and complaint details"
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setShowEditJob(false)}>
              Cancel
            </Button>
            <Button type="submit" form="edit-job-form" disabled={saving}>
              {saving ? 'Saving...' : 'Save changes'}
            </Button>
          </>
        }
      >
        <form id="edit-job-form" className="form-grid form-grid--stack" onSubmit={(event) => void saveJobEdit(event)}>
          <div>
            <FieldLabel htmlFor="edit-priority">Priority</FieldLabel>
            <SelectInput
              id="edit-priority"
              value={jobForm.priority}
              onChange={(event) => setJobForm({ ...jobForm, priority: event.target.value })}
            >
              <option value="low">Low</option>
              <option value="normal">Normal</option>
              <option value="urgent">Urgent</option>
              <option value="critical">Critical</option>
            </SelectInput>
          </div>
          <div>
            <FieldLabel htmlFor="edit-tech">Primary technician</FieldLabel>
            <SelectInput
              id="edit-tech"
              value={jobForm.primary_technician_uuid}
              onChange={(event) => setJobForm({ ...jobForm, primary_technician_uuid: event.target.value })}
            >
              <option value="">Unassigned</option>
              {technicians.map((tech) => (
                <option key={String(tech.uuid)} value={String(tech.uuid)}>
                  {String(tech.name ?? tech.full_name ?? tech.first_name)}
                </option>
              ))}
            </SelectInput>
          </div>
          <div>
            <FieldLabel htmlFor="edit-bay">Service bay</FieldLabel>
            <SelectInput
              id="edit-bay"
              value={jobForm.assigned_bay_uuid}
              onChange={(event) => setJobForm({ ...jobForm, assigned_bay_uuid: event.target.value })}
            >
              <option value="">No bay</option>
              {bays.map((bay) => (
                <option key={String(bay.uuid)} value={String(bay.uuid)}>
                  {String(bay.name)} ({String(bay.code ?? bay.status)})
                </option>
              ))}
            </SelectInput>
          </div>
          <div>
            <FieldLabel htmlFor="edit-complaint">Customer complaint</FieldLabel>
            <TextArea
              id="edit-complaint"
              rows={4}
              value={jobForm.customer_complaint}
              onChange={(event) => setJobForm({ ...jobForm, customer_complaint: event.target.value })}
            />
          </div>
        </form>
      </Modal>

      <Modal
        open={showInsurance}
        onClose={() => setShowInsurance(false)}
        title="Insurance claim"
        subtitle="Track insurer and claim progress"
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setShowInsurance(false)}>
              Cancel
            </Button>
            <Button type="submit" form="insurance-form" disabled={saving}>
              {saving ? 'Saving...' : 'Save insurance'}
            </Button>
          </>
        }
      >
        <form id="insurance-form" className="form-grid form-grid--stack" onSubmit={(event) => void saveInsurance(event)}>
          <div>
            <FieldLabel htmlFor="ins-status">Claim status</FieldLabel>
            <SelectInput
              id="ins-status"
              value={insuranceForm.insurance_claim_status}
              onChange={(event) => setInsuranceForm({ ...insuranceForm, insurance_claim_status: event.target.value })}
            >
              {INSURANCE_STATUS_OPTIONS.map((option) => (
                <option key={option} value={option}>
                  {option.replace(/_/g, ' ')}
                </option>
              ))}
            </SelectInput>
          </div>
          <div>
            <FieldLabel htmlFor="ins-company">Insurance company</FieldLabel>
            <TextInput
              id="ins-company"
              value={insuranceForm.insurance_company}
              onChange={(event) => setInsuranceForm({ ...insuranceForm, insurance_company: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="ins-claim">Claim number</FieldLabel>
            <TextInput
              id="ins-claim"
              value={insuranceForm.claim_number}
              onChange={(event) => setInsuranceForm({ ...insuranceForm, claim_number: event.target.value })}
            />
          </div>
          <div className="form-grid">
            <div>
              <FieldLabel htmlFor="ins-amount">Claim amount</FieldLabel>
              <TextInput
                id="ins-amount"
                value={insuranceForm.job_insurance_claim_amount}
                onChange={(event) => setInsuranceForm({ ...insuranceForm, job_insurance_claim_amount: event.target.value })}
              />
            </div>
            <div>
              <FieldLabel htmlFor="ins-liability">Customer liability</FieldLabel>
              <TextInput
                id="ins-liability"
                value={insuranceForm.customer_liability_amount}
                onChange={(event) => setInsuranceForm({ ...insuranceForm, customer_liability_amount: event.target.value })}
              />
            </div>
          </div>
        </form>
      </Modal>

      <Modal
        open={showTaskModal}
        onClose={() => setShowTaskModal(false)}
        title={editingTaskId ? 'Edit task' : 'Add task'}
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setShowTaskModal(false)}>
              Cancel
            </Button>
            <Button type="submit" form="task-form" disabled={saving}>
              {saving ? 'Saving...' : editingTaskId ? 'Update task' : 'Add task'}
            </Button>
          </>
        }
      >
        <form id="task-form" className="form-grid form-grid--stack" onSubmit={(event) => void saveTask(event)}>
          <div>
            <FieldLabel htmlFor="task-name">Task name</FieldLabel>
            <TextInput
              id="task-name"
              required
              value={taskForm.name}
              onChange={(event) => setTaskForm({ ...taskForm, name: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="task-desc">Description</FieldLabel>
            <TextArea
              id="task-desc"
              rows={2}
              value={taskForm.description}
              onChange={(event) => setTaskForm({ ...taskForm, description: event.target.value })}
            />
          </div>
          <div className="form-grid">
            <div>
              <FieldLabel htmlFor="task-status">Status</FieldLabel>
              <SelectInput
                id="task-status"
                value={taskForm.status}
                onChange={(event) => setTaskForm({ ...taskForm, status: event.target.value })}
              >
                {TASK_STATUS_OPTIONS.map((option) => (
                  <option key={option} value={option}>
                    {option.replace(/_/g, ' ')}
                  </option>
                ))}
              </SelectInput>
            </div>
            <div>
              <FieldLabel htmlFor="task-tech">Technician</FieldLabel>
              <SelectInput
                id="task-tech"
                value={taskForm.assigned_technician_uuid}
                onChange={(event) => setTaskForm({ ...taskForm, assigned_technician_uuid: event.target.value })}
              >
                <option value="">Unassigned</option>
                {technicians.map((tech) => (
                  <option key={String(tech.uuid)} value={String(tech.uuid)}>
                    {String(tech.name ?? tech.full_name ?? tech.first_name)}
                  </option>
                ))}
              </SelectInput>
            </div>
          </div>
          <div className="form-grid">
            <div>
              <FieldLabel htmlFor="task-est">Estimated price</FieldLabel>
              <TextInput
                id="task-est"
                value={taskForm.estimated_price}
                onChange={(event) => setTaskForm({ ...taskForm, estimated_price: event.target.value })}
              />
            </div>
            <div>
              <FieldLabel htmlFor="task-final">Final price</FieldLabel>
              <TextInput
                id="task-final"
                value={taskForm.final_price}
                onChange={(event) => setTaskForm({ ...taskForm, final_price: event.target.value })}
              />
            </div>
          </div>
        </form>
      </Modal>
    </StaffPage>
  );
}
