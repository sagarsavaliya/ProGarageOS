import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Button, Card, StatusBadge, Table, THead, TRow, TH, TD, EmptyState, LoadingState, ListPager } from '@/components/ui';
import { FieldLabel, TextInput } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest, asData, type JsonMap } from '@/lib/api';
import { usePaginatedList } from '@/lib/hooks';
import { customerName, money } from '@/lib/format';

export function BillingListPage() {
  const token = useStaffToken();
  const navigate = useNavigate();
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [searchInput, setSearchInput] = useState('');
  const [showOutstanding, setShowOutstanding] = useState(false);

  const listQuery = usePaginatedList('/invoices', token, {
    page,
    per_page: 20,
    ...(search ? { search } : {}),
  });

  const outstandingQuery = useQuery({
    queryKey: ['payments-outstanding', token],
    enabled: showOutstanding && token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/payments/outstanding', { token, query: { per_page: 25 } });
      return asData<JsonMap>(payload);
    },
  });

  const items = listQuery.data?.items ?? [];
  const meta = listQuery.data?.meta ?? {};
  const lastPage = Number(meta.last_page ?? 1);
  const outstandingItems = (outstandingQuery.data?.items as JsonMap[] | undefined) ?? [];

  return (
    <StaffPage title="Billing" subtitle="Invoices and outstanding payments">
      <div className="toolbar">
        <form
          className="toolbar-form toolbar-form--search"
          onSubmit={(event) => {
            event.preventDefault();
            setSearch(searchInput.trim());
            setPage(1);
          }}
        >
          <div>
            <FieldLabel htmlFor="invoice-search">Search</FieldLabel>
            <TextInput
              id="invoice-search"
              placeholder="Invoice number or customer"
              value={searchInput}
              onChange={(event) => setSearchInput(event.target.value)}
            />
          </div>
          <div>
            <Button type="submit">Search</Button>
          </div>
        </form>
        <Button type="button" onClick={() => navigate('/billing/new')}>
          New invoice
        </Button>
        <Button type="button" variant="outline" onClick={() => setShowOutstanding((value) => !value)}>
          {showOutstanding ? 'Hide outstanding' : 'Outstanding payments'}
        </Button>
      </div>

      {showOutstanding ? (
        <Card>
          <h3>Outstanding payments</h3>
          {outstandingQuery.isLoading ? <LoadingState label="Loading outstanding..." /> : null}
          {outstandingItems.length === 0 && !outstandingQuery.isLoading ? (
            <EmptyState title="No outstanding invoices" description="All caught up — no pending balances right now." />
          ) : null}
          <div className="stack mt-3">
            {outstandingItems.map((item) => (
              <div key={String(item.uuid ?? item.invoice_uuid)} className="line-item">
                <span>
                  {String(item.invoice_number ?? item.uuid)} · {customerName((item.customer as JsonMap) ?? item)}
                </span>
                <Link to={`/billing/${String(item.uuid ?? item.invoice_uuid)}`}>{money(item.balance_due ?? item.amount_due)}</Link>
              </div>
            ))}
          </div>
        </Card>
      ) : null}

      <Card>
        {listQuery.isLoading ? <LoadingState label="Loading invoices..." /> : null}
        {items.length > 0 ? (
          <Table>
            <THead>
              <TRow>
                <TH>Invoice</TH>
                <TH>Customer</TH>
                <TH>Total</TH>
                <TH>Paid</TH>
                <TH>Status</TH>
              </TRow>
            </THead>
            <tbody>
              {items.map((invoice: JsonMap) => (
                <TRow key={String(invoice.uuid)}>
                  <TD>
                    <Link to={`/billing/${String(invoice.uuid)}`}>{String(invoice.invoice_number ?? invoice.uuid)}</Link>
                  </TD>
                  <TD>{String(invoice.customer_name ?? customerName((invoice.customer as JsonMap) ?? {}))}</TD>
                  <TD>{money(invoice.total_amount)}</TD>
                  <TD>{money(invoice.paid_amount)}</TD>
                  <TD>
                    <StatusBadge status={String(invoice.status ?? 'draft')} />
                  </TD>
                </TRow>
              ))}
            </tbody>
          </Table>
        ) : (
          !listQuery.isLoading && <EmptyState title="No invoices found" description="Invoices will appear here once jobs are billed." />
        )}

        <ListPager page={page} lastPage={lastPage} onPrevious={() => setPage((p) => p - 1)} onNext={() => setPage((p) => p + 1)} />
      </Card>
    </StaffPage>
  );
}
