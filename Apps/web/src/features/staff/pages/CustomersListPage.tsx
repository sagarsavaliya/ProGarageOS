import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Button, Card, Table, THead, TRow, TH, TD, EmptyState, LoadingState, ListPager, Modal, Alert } from '@/components/ui';
import { FieldLabel, TextInput } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest } from '@/lib/api';
import { usePaginatedList } from '@/lib/hooks';
import { customerName, initials } from '@/lib/format';
import { normalizeLogin } from '@/lib/api';
import type { JsonMap } from '@/lib/api';

export function CustomersListPage() {
  const token = useStaffToken();
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [searchInput, setSearchInput] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState({ first_name: '', last_name: '', phone_primary: '', email: '' });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();

  const listQuery = usePaginatedList('/customers', token, { page, per_page: 25, ...(search ? { search } : {}) });
  const items = listQuery.data?.items ?? [];
  const meta = listQuery.data?.meta ?? {};
  const lastPage = Number(meta.last_page ?? 1);

  async function createCustomer(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest('/customers', {
        method: 'POST',
        token,
        body: {
          first_name: form.first_name.trim(),
          last_name: form.last_name.trim(),
          phone_primary: normalizeLogin(form.phone_primary),
          ...(form.email.trim() ? { email: form.email.trim() } : {}),
        },
      });
      setShowModal(false);
      setForm({ first_name: '', last_name: '', phone_primary: '', email: '' });
      await listQuery.refetch();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <StaffPage title="Customers" subtitle="Search and manage customer records">
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
            <FieldLabel htmlFor="customer-search">Search</FieldLabel>
            <TextInput
              id="customer-search"
              placeholder="Name or phone"
              value={searchInput}
              onChange={(event) => setSearchInput(event.target.value)}
            />
          </div>
          <div>
            <Button type="submit">Search</Button>
          </div>
        </form>
        <Button type="button" onClick={() => setShowModal(true)}>
          Add customer
        </Button>
      </div>

      <Card>
        {listQuery.isLoading ? <LoadingState label="Loading customers..." /> : null}
        {items.length > 0 ? (
          <Table>
            <THead>
              <TRow>
                <TH>Customer</TH>
                <TH>Phone</TH>
                <TH>Email</TH>
                <TH>Last visit</TH>
              </TRow>
            </THead>
            <tbody>
              {items.map((customer: JsonMap) => {
                const name = customerName(customer);
                return (
                  <TRow key={String(customer.uuid)}>
                    <TD>
                      <Link to={`/customers/${String(customer.uuid)}`}>
                        <span className="avatar-chip">{initials(name)}</span>
                        {name}
                      </Link>
                    </TD>
                    <TD>{String(customer.phone_primary ?? customer.phone ?? '-')}</TD>
                    <TD>{String(customer.email ?? '-')}</TD>
                    <TD>{String(customer.last_visited_at ?? '-')}</TD>
                  </TRow>
                );
              })}
            </tbody>
          </Table>
        ) : (
          !listQuery.isLoading && (
            <EmptyState
              title="No customers found"
              description="Add your first customer or adjust your search."
              action={
                <Button type="button" onClick={() => setShowModal(true)}>
                  Add customer
                </Button>
              }
            />
          )
        )}

        <ListPager
          page={page}
          lastPage={lastPage}
          onPrevious={() => setPage((p) => p - 1)}
          onNext={() => setPage((p) => p + 1)}
        />
      </Card>

      <Modal
        open={showModal}
        onClose={() => setShowModal(false)}
        title="Add customer"
        subtitle="Create a new customer record for your garage"
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setShowModal(false)}>
              Cancel
            </Button>
            <Button type="submit" form="add-customer-form" disabled={saving}>
              {saving ? 'Saving...' : 'Create'}
            </Button>
          </>
        }
      >
        <form id="add-customer-form" className="form-grid form-grid--stack" onSubmit={(event) => void createCustomer(event)}>
          <div>
            <FieldLabel>First name</FieldLabel>
            <TextInput
              required
              value={form.first_name}
              onChange={(event) => setForm({ ...form, first_name: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel>Last name</FieldLabel>
            <TextInput
              value={form.last_name}
              onChange={(event) => setForm({ ...form, last_name: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel>Phone</FieldLabel>
            <TextInput
              required
              value={form.phone_primary}
              onChange={(event) => setForm({ ...form, phone_primary: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel>Email</FieldLabel>
            <TextInput
              type="email"
              value={form.email}
              onChange={(event) => setForm({ ...form, email: event.target.value })}
            />
          </div>
          {error ? <Alert variant="error">{error}</Alert> : null}
        </form>
      </Modal>
    </StaffPage>
  );
}
