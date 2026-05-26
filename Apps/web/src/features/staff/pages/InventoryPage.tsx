import { useState } from 'react';
import { Button, Card, Table, THead, TRow, TH, TD, EmptyState, LoadingState, ListPager, Modal, Alert } from '@/components/ui';
import { FieldLabel, SelectInput, TextInput } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest } from '@/lib/api';
import { usePaginatedList } from '@/lib/hooks';
import { money } from '@/lib/format';
import type { JsonMap } from '@/lib/api';

export function InventoryPage() {
  const token = useStaffToken();
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [searchInput, setSearchInput] = useState('');
  const [showAdd, setShowAdd] = useState(false);
  const [adjustUuid, setAdjustUuid] = useState<string | null>(null);
  const [adjustQty, setAdjustQty] = useState('');
  const [adjustReason, setAdjustReason] = useState('restock');
  const [form, setForm] = useState({
    sku: '',
    name: '',
    unit_of_measure: 'pcs',
    cost_price: '',
    selling_price: '',
    stock_on_hand: '0',
    low_stock_threshold: '5',
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();

  const listQuery = usePaginatedList('/inventory', token, {
    page,
    per_page: 20,
    ...(search ? { search } : {}),
  });

  const items = listQuery.data?.items ?? [];
  const meta = listQuery.data?.meta ?? {};
  const lastPage = Number(meta.last_page ?? 1);
  const adjustingPart = items.find((item) => String(item.uuid) === adjustUuid);

  function isLowStock(item: JsonMap): boolean {
    const stock = Number(item.stock_on_hand ?? 0);
    const threshold = Number(item.low_stock_threshold ?? 0);
    return threshold > 0 && stock <= threshold;
  }

  async function addPart(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest('/inventory', {
        method: 'POST',
        token,
        body: {
          sku: form.sku.trim(),
          name: form.name.trim(),
          unit_of_measure: form.unit_of_measure,
          cost_price: Number(form.cost_price),
          selling_price: Number(form.selling_price),
          stock_on_hand: Number(form.stock_on_hand),
          low_stock_threshold: Number(form.low_stock_threshold),
          reorder_quantity: Number(form.low_stock_threshold) || 1,
        },
      });
      setShowAdd(false);
      await listQuery.refetch();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function adjustStock() {
    if (!adjustUuid) {
      return;
    }
    const qty = Number(adjustQty);
    if (!Number.isFinite(qty) || qty === 0) {
      setError('Enter a valid adjustment quantity.');
      return;
    }
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/inventory/${adjustUuid}/stock`, {
        method: 'PATCH',
        token,
        body: { adjustment: qty, reason: adjustReason },
      });
      setAdjustUuid(null);
      setAdjustQty('');
      await listQuery.refetch();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <StaffPage title="Inventory" subtitle="Parts stock and adjustments">
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
            <FieldLabel htmlFor="inventory-search">Search</FieldLabel>
            <TextInput
              id="inventory-search"
              placeholder="SKU or part name"
              value={searchInput}
              onChange={(event) => setSearchInput(event.target.value)}
            />
          </div>
          <div className="align-self-end">
            <Button type="submit">Search</Button>
          </div>
        </form>
        <Button type="button" onClick={() => setShowAdd(true)}>
          Add part
        </Button>
      </div>

      <Card>
        {listQuery.isLoading ? <LoadingState label="Loading inventory..." /> : null}
        {items.length > 0 ? (
          <Table>
            <THead>
              <TRow>
                <TH>SKU</TH>
                <TH>Name</TH>
                <TH>Stock</TH>
                <TH>Threshold</TH>
                <TH>Price</TH>
                <TH>Actions</TH>
              </TRow>
            </THead>
            <tbody>
              {items.map((item: JsonMap) => (
                <TRow key={String(item.uuid)}>
                  <TD>{String(item.sku ?? '-')}</TD>
                  <TD>
                    {String(item.name ?? '-')}
                    {isLowStock(item) ? <span className="chip active chip-inline">Low stock</span> : null}
                  </TD>
                  <TD>{String(item.stock_on_hand ?? 0)}</TD>
                  <TD>{String(item.low_stock_threshold ?? '-')}</TD>
                  <TD>{money(item.selling_price)}</TD>
                  <TD>
                    <Button type="button" variant="outline" onClick={() => setAdjustUuid(String(item.uuid))}>
                      Adjust
                    </Button>
                  </TD>
                </TRow>
              ))}
            </tbody>
          </Table>
        ) : (
          !listQuery.isLoading && (
            <EmptyState title="No inventory items found" description="Add parts to track stock and low-stock alerts." />
          )
        )}

        <ListPager page={page} lastPage={lastPage} onPrevious={() => setPage((p) => p - 1)} onNext={() => setPage((p) => p + 1)} />
      </Card>

      <Modal
        open={showAdd}
        onClose={() => setShowAdd(false)}
        title="Add part"
        subtitle="Register a new part in your inventory catalog"
        wide
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setShowAdd(false)}>
              Cancel
            </Button>
            <Button type="submit" form="add-part-form" disabled={saving}>
              {saving ? 'Saving...' : 'Add part'}
            </Button>
          </>
        }
      >
        <form id="add-part-form" className="form-grid form-grid--stack" onSubmit={(event) => void addPart(event)}>
          <div>
            <FieldLabel>SKU</FieldLabel>
            <TextInput required value={form.sku} onChange={(event) => setForm({ ...form, sku: event.target.value })} />
          </div>
          <div>
            <FieldLabel>Name</FieldLabel>
            <TextInput required value={form.name} onChange={(event) => setForm({ ...form, name: event.target.value })} />
          </div>
          <div>
            <FieldLabel>Unit</FieldLabel>
            <TextInput value={form.unit_of_measure} onChange={(event) => setForm({ ...form, unit_of_measure: event.target.value })} />
          </div>
          <div>
            <FieldLabel>Cost price</FieldLabel>
            <TextInput value={form.cost_price} onChange={(event) => setForm({ ...form, cost_price: event.target.value })} />
          </div>
          <div>
            <FieldLabel>Selling price</FieldLabel>
            <TextInput value={form.selling_price} onChange={(event) => setForm({ ...form, selling_price: event.target.value })} />
          </div>
          <div>
            <FieldLabel>Stock on hand</FieldLabel>
            <TextInput value={form.stock_on_hand} onChange={(event) => setForm({ ...form, stock_on_hand: event.target.value })} />
          </div>
          <div>
            <FieldLabel>Low stock threshold</FieldLabel>
            <TextInput
              value={form.low_stock_threshold}
              onChange={(event) => setForm({ ...form, low_stock_threshold: event.target.value })}
            />
          </div>
          {error ? <Alert variant="error">{error}</Alert> : null}
        </form>
      </Modal>

      <Modal
        open={Boolean(adjustUuid)}
        onClose={() => {
          setAdjustUuid(null);
          setError(undefined);
        }}
        title="Adjust stock"
        subtitle={
          adjustingPart
            ? `${String(adjustingPart.name ?? 'Part')} · current stock ${String(adjustingPart.stock_on_hand ?? 0)}`
            : 'Increase or decrease on-hand quantity'
        }
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setAdjustUuid(null)}>
              Cancel
            </Button>
            <Button type="button" onClick={() => void adjustStock()} disabled={saving}>
              {saving ? 'Saving...' : 'Apply adjustment'}
            </Button>
          </>
        }
      >
        <div className="form-grid form-grid--stack">
          <div>
            <FieldLabel htmlFor="stock-adjust-qty">Adjustment quantity</FieldLabel>
            <TextInput
              id="stock-adjust-qty"
              type="number"
              inputMode="decimal"
              placeholder="e.g. 5 or -2"
              value={adjustQty}
              onChange={(event) => setAdjustQty(event.target.value)}
            />
            <p className="form-hint">Use positive numbers to add stock and negative numbers to remove stock.</p>
          </div>
          <div>
            <FieldLabel htmlFor="stock-adjust-reason">Reason</FieldLabel>
            <SelectInput
              id="stock-adjust-reason"
              value={adjustReason}
              onChange={(event) => setAdjustReason(event.target.value)}
            >
              <option value="restock">Restock</option>
              <option value="sale">Used on job / sale</option>
              <option value="damage">Damaged / write-off</option>
              <option value="correction">Inventory correction</option>
              <option value="return">Supplier return</option>
            </SelectInput>
          </div>
          {error ? <Alert variant="error">{error}</Alert> : null}
        </div>
      </Modal>
    </StaffPage>
  );
}
