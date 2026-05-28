import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Alert, Button, Card, EmptyState, LoadingState } from '@/components/ui';
import { FieldLabel, SelectInput, TextInput } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest, asData, type JsonMap } from '@/lib/api';
import { customerName, money } from '@/lib/format';

type LineDraft = {
  line_type: string;
  name: string;
  quantity: string;
  unit_price: string;
};

const BILLABLE_STATUSES = new Set([
  'estimate_pending',
  'estimate_approved',
  'in_progress',
  'qc_pending',
  'ready_for_delivery',
]);

export function CreateInvoicePage() {
  const token = useStaffToken();
  const navigate = useNavigate();
  const [selectedJobUuid, setSelectedJobUuid] = useState('');
  const [lines, setLines] = useState<LineDraft[]>([
    { line_type: 'service', name: '', quantity: '1', unit_price: '0' },
  ]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();

  const jobsQuery = useQuery({
    queryKey: ['create-invoice-jobs', token],
    enabled: token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/jobs', { token, query: { per_page: 50 } });
      const items = asData<JsonMap[]>(payload) ?? [];
      return items.filter((job) => {
        const status = String(job.status ?? '');
        const hasInvoice = Boolean(job.invoice_uuid ?? (job.invoice as JsonMap | undefined)?.uuid);
        return BILLABLE_STATUSES.has(status) && !hasInvoice;
      });
    },
  });

  const jobs = jobsQuery.data ?? [];
  const selectedJob = jobs.find((job) => String(job.uuid) === selectedJobUuid);

  function selectJob(uuid: string) {
    setSelectedJobUuid(uuid);
    const job = jobs.find((item) => String(item.uuid) === uuid);
    const jobNumber = String(job?.job_number ?? job?.uuid ?? 'Job');
    setLines([{ line_type: 'service', name: `Service — ${jobNumber}`, quantity: '1', unit_price: '0' }]);
  }

  function updateLine(index: number, patch: Partial<LineDraft>) {
    setLines((current) => current.map((line, i) => (i === index ? { ...line, ...patch } : line)));
  }

  function addLine() {
    setLines((current) => [...current, { line_type: 'service', name: 'Line item', quantity: '1', unit_price: '0' }]);
  }

  function removeLine(index: number) {
    setLines((current) => (current.length <= 1 ? current : current.filter((_, i) => i !== index)));
  }

  async function submitInvoice(event: React.FormEvent) {
    event.preventDefault();
    if (!selectedJobUuid) {
      setError('Select a job to bill.');
      return;
    }
    const items = lines
      .map((line) => ({
        line_type: line.line_type,
        name: line.name.trim(),
        quantity: Number(line.quantity),
        unit_price: Number(line.unit_price),
      }))
      .filter((line) => line.name.length > 0);
    if (items.length === 0) {
      setError('Add at least one line item.');
      return;
    }
    setSaving(true);
    setError(undefined);
    try {
      const payload = await apiRequest('/invoices', {
        method: 'POST',
        token,
        body: { job_uuid: selectedJobUuid, type: 'final', items },
      });
      const created = asData<JsonMap>(payload);
      navigate(`/billing/${String(created.uuid)}`);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  const subtotal = lines.reduce((sum, line) => {
    const qty = Number(line.quantity);
    const price = Number(line.unit_price);
    if (!Number.isFinite(qty) || !Number.isFinite(price)) return sum;
    return sum + qty * price;
  }, 0);

  return (
    <StaffPage title="New invoice" subtitle="Create a standalone invoice from a billable job">
      <div className="toolbar">
        <Link to="/billing">
          <Button type="button" variant="outline">
            Back to billing
          </Button>
        </Link>
      </div>

      {error ? <Alert variant="error">{error}</Alert> : null}

      <form className="stack" onSubmit={(event) => void submitInvoice(event)}>
        <Card>
          <h3>Select job</h3>
          {jobsQuery.isLoading ? <LoadingState label="Loading billable jobs..." /> : null}
          {!jobsQuery.isLoading && jobs.length === 0 ? (
            <EmptyState title="No billable jobs" description="Jobs ready for billing will appear here." />
          ) : null}
          <div className="stack mt-3">
            {jobs.map((job) => (
              <button
                key={String(job.uuid)}
                type="button"
                className={`chip ${selectedJobUuid === String(job.uuid) ? 'active' : ''}`}
                onClick={() => selectJob(String(job.uuid))}
              >
                {String(job.job_number ?? job.uuid)} · {customerName((job.customer as JsonMap) ?? job)} ·{' '}
                {String(job.status ?? '').replace(/_/g, ' ')}
              </button>
            ))}
          </div>
        </Card>

        {selectedJob ? (
          <Card>
            <div className="section-header">
              <h3>Line items</h3>
              <Button type="button" variant="outline" onClick={addLine}>
                Add line
              </Button>
            </div>
            <div className="stack mt-3">
              {lines.map((line, index) => (
                <div key={index} className="form-grid">
                  <div>
                    <FieldLabel>Type</FieldLabel>
                    <SelectInput
                      value={line.line_type}
                      onChange={(event) => updateLine(index, { line_type: event.target.value })}
                    >
                      <option value="service">Service</option>
                      <option value="part">Part</option>
                      <option value="labor">Labor</option>
                      <option value="manual">Manual</option>
                      <option value="discount">Discount</option>
                    </SelectInput>
                  </div>
                  <div>
                    <FieldLabel>Name</FieldLabel>
                    <TextInput
                      required
                      value={line.name}
                      onChange={(event) => updateLine(index, { name: event.target.value })}
                    />
                  </div>
                  <div>
                    <FieldLabel>Qty</FieldLabel>
                    <TextInput
                      value={line.quantity}
                      onChange={(event) => updateLine(index, { quantity: event.target.value })}
                    />
                  </div>
                  <div>
                    <FieldLabel>Unit price</FieldLabel>
                    <TextInput
                      value={line.unit_price}
                      onChange={(event) => updateLine(index, { unit_price: event.target.value })}
                    />
                  </div>
                  {lines.length > 1 ? (
                    <div className="align-self-end">
                      <Button type="button" variant="ghost" onClick={() => removeLine(index)}>
                        Remove
                      </Button>
                    </div>
                  ) : null}
                </div>
              ))}
            </div>
            <p className="muted mt-3">Subtotal: {money(subtotal)}</p>
          </Card>
        ) : null}

        <div className="toolbar">
          <Button type="submit" disabled={saving || !selectedJobUuid}>
            {saving ? 'Creating...' : 'Create invoice'}
          </Button>
        </div>
      </form>
    </StaffPage>
  );
}
