import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Button, Card, StatusBadge, Table, THead, TRow, TH, TD, Alert } from '@/components/ui';
import { FieldLabel, SelectInput, TextArea, TextInput } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { API_BASE_URL, apiRequest, asData, type JsonMap } from '@/lib/api';
import { useDetail } from '@/lib/hooks';
import { customerName, money } from '@/lib/format';

export function BillingDetailPage() {
  const { uuid = '' } = useParams();
  const token = useStaffToken();
  const queryClient = useQueryClient();
  const detailQuery = useDetail(`/invoices/${uuid}`, token, uuid.length > 0);
  const invoice = asData<JsonMap>(detailQuery.data ?? {});

  const methodsQuery = useQuery({
    queryKey: ['payment-methods', token],
    enabled: token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/payment-methods', { token });
      return asData<JsonMap[]>(payload) ?? [];
    },
  });

  const [amount, setAmount] = useState('');
  const [methodId, setMethodId] = useState('');
  const [paymentType, setPaymentType] = useState('customer_pay');
  const [reference, setReference] = useState('');
  const [notes, setNotes] = useState('');
  const [customerPayAmount, setCustomerPayAmount] = useState('');
  const [insurancePayAmount, setInsurancePayAmount] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();
  const [message, setMessage] = useState<string>();
  const [pdfLoading, setPdfLoading] = useState(false);

  const items = (invoice.items as JsonMap[] | undefined) ?? [];
  const payments = (invoice.payments as JsonMap[] | undefined) ?? [];
  const customer = (invoice.customer as JsonMap | undefined) ?? {};
  const job = (invoice.job as JsonMap | undefined) ?? {};
  const grandTotal = Number(invoice.grand_total ?? invoice.total_amount ?? 0);

  useEffect(() => {
    if (!uuid || detailQuery.isLoading) {
      return;
    }
    const customerSplit = Number(invoice.customer_pay_amount ?? invoice.customer_portion ?? grandTotal);
    const insuranceSplit = Number(invoice.insurance_claim_amount ?? invoice.insurance_portion ?? 0);
    if (customerSplit || insuranceSplit) {
      setCustomerPayAmount(String(customerSplit));
      setInsurancePayAmount(String(insuranceSplit));
    } else if (grandTotal > 0) {
      setCustomerPayAmount(String(grandTotal));
      setInsurancePayAmount('0');
    }
  }, [uuid, detailQuery.isLoading, grandTotal, invoice.customer_pay_amount, invoice.insurance_claim_amount, invoice.customer_portion, invoice.insurance_portion]);

  async function recordPayment(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/invoices/${uuid}/payments`, {
        method: 'POST',
        token,
        body: {
          amount: Number(amount),
          payment_method_id: Number(methodId),
          payment_type: paymentType,
          ...(reference.trim() ? { reference_number: reference.trim() } : {}),
          ...(notes.trim() ? { notes: notes.trim() } : {}),
        },
      });
      await queryClient.invalidateQueries({ queryKey: ['detail', `/invoices/${uuid}`] });
      setAmount('');
      setReference('');
      setNotes('');
      setMessage('Payment recorded.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function openPdf() {
    setPdfLoading(true);
    setError(undefined);
    try {
      const payload = await apiRequest(`/invoices/${uuid}/pdf`, { token });
      const data = asData<JsonMap>(payload);
      const url = String(data.pdf_url ?? '');
      if (!url) {
        throw new Error('PDF not available yet.');
      }
      window.open(url.startsWith('http') ? url : `${API_BASE_URL.replace('/api', '')}${url}`, '_blank');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setPdfLoading(false);
    }
  }

  async function saveSplitBilling(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/invoices/${uuid}/split-billing`, {
        method: 'PATCH',
        token,
        body: {
          customer_pay_amount: Number(customerPayAmount),
          insurance_claim_amount: Number(insurancePayAmount),
        },
      });
      await queryClient.invalidateQueries({ queryKey: ['detail', `/invoices/${uuid}`] });
      setMessage('Split billing saved.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <StaffPage title={`Invoice ${String(invoice.invoice_number ?? uuid)}`} subtitle="Invoice detail and payments">
      <div className="toolbar">
        <Link to="/billing">
          <Button type="button" variant="outline">
            Back
          </Button>
        </Link>
        <Button type="button" variant="outline" onClick={() => void openPdf()} disabled={pdfLoading}>
          {pdfLoading ? 'Loading PDF...' : 'Download PDF'}
        </Button>
        {job.uuid ? (
          <Link to={`/jobs/${String(job.uuid)}`}>
            <Button type="button" variant="ghost">
              View job
            </Button>
          </Link>
        ) : null}
      </div>

      {detailQuery.isLoading ? <p className="muted">Loading invoice...</p> : null}
      {message ? <Alert variant="success">{message}</Alert> : null}
      {error ? <Alert variant="error">{error}</Alert> : null}

      <div className="detail-grid">
        <Card>
          <h3>Summary</h3>
          <div className="stack mt-3">
            <div className="line-item">
              <span>Customer</span>
              <span>{customerName(customer)}</span>
            </div>
            <div className="line-item">
              <span>Status</span>
              <StatusBadge status={String(invoice.status ?? 'draft')} />
            </div>
            <div className="line-item">
              <span>Total</span>
              <strong>{money(invoice.total_amount)}</strong>
            </div>
            <div className="line-item">
              <span>Paid</span>
              <span>{money(invoice.paid_amount)}</span>
            </div>
            <div className="line-item">
              <span>Balance</span>
              <span>{money(invoice.balance_due ?? invoice.amount_due)}</span>
            </div>
          </div>
        </Card>

        <Card>
          <h3>Record payment</h3>
          <form className="form-grid mt-3" onSubmit={(event) => void recordPayment(event)}>
            <div>
              <FieldLabel>Payment type</FieldLabel>
              <SelectInput value={paymentType} onChange={(event) => setPaymentType(event.target.value)}>
                <option value="customer_pay">Customer payment</option>
                <option value="insurance_claim">Insurance claim</option>
                <option value="advance">Advance</option>
              </SelectInput>
            </div>
            <div>
              <FieldLabel>Amount</FieldLabel>
              <TextInput required value={amount} onChange={(event) => setAmount(event.target.value)} />
            </div>
            <div>
              <FieldLabel>Payment method</FieldLabel>
              <SelectInput required value={methodId} onChange={(event) => setMethodId(event.target.value)}>
                <option value="">Select method</option>
                {(methodsQuery.data ?? []).map((method) => (
                  <option key={String(method.id)} value={String(method.id)}>
                    {String(method.name ?? method.id)}
                  </option>
                ))}
              </SelectInput>
            </div>
            <div>
              <FieldLabel>Reference</FieldLabel>
              <TextInput value={reference} onChange={(event) => setReference(event.target.value)} />
            </div>
            <div>
              <FieldLabel>Notes</FieldLabel>
              <TextArea rows={2} value={notes} onChange={(event) => setNotes(event.target.value)} />
            </div>
            <Button type="submit" disabled={saving}>
              {saving ? 'Recording...' : 'Record payment'}
            </Button>
          </form>
        </Card>

        <Card>
          <h3>Split billing</h3>
          <p className="muted mt-2">
            Divide invoice total between customer and insurance (must equal {money(grandTotal)}).
          </p>
          <form className="form-grid mt-3" onSubmit={(event) => void saveSplitBilling(event)}>
            <div>
              <FieldLabel>Customer pays</FieldLabel>
              <TextInput
                required
                value={customerPayAmount}
                onChange={(event) => setCustomerPayAmount(event.target.value)}
              />
            </div>
            <div>
              <FieldLabel>Insurance pays</FieldLabel>
              <TextInput
                required
                value={insurancePayAmount}
                onChange={(event) => setInsurancePayAmount(event.target.value)}
              />
            </div>
            <Button type="submit" disabled={saving}>
              {saving ? 'Saving...' : 'Save split'}
            </Button>
          </form>
        </Card>
      </div>

      <Card>
        <h3>Line items</h3>
        {items.length === 0 ? <p className="muted">No line items.</p> : null}
        {items.length > 0 ? (
          <Table>
            <THead>
              <TRow>
                <TH>Description</TH>
                <TH>Qty</TH>
                <TH>Amount</TH>
              </TRow>
            </THead>
            <tbody>
              {items.map((item, index) => (
                <TRow key={String(item.uuid ?? index)}>
                  <TD>{String(item.description ?? item.name ?? '-')}</TD>
                  <TD>{String(item.quantity ?? 1)}</TD>
                  <TD>{money(item.total_amount ?? item.amount)}</TD>
                </TRow>
              ))}
            </tbody>
          </Table>
        ) : null}
      </Card>

      <Card>
        <h3>Payments</h3>
        {payments.length === 0 ? <p className="muted">No payments recorded.</p> : null}
        <div className="stack mt-3">
          {payments.map((payment) => (
            <div key={String(payment.uuid ?? payment.id)} className="line-item">
              <span>{String(payment.payment_method_name ?? payment.method ?? 'Payment')}</span>
              <span>{money(payment.amount)}</span>
            </div>
          ))}
        </div>
      </Card>
    </StaffPage>
  );
}
