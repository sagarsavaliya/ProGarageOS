import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { Alert, Button, Card, LoadingState, Modal } from '@/components/ui';
import { FieldLabel, SelectInput, TextInput } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest, asData, type JsonMap } from '@/lib/api';
import { useDetail } from '@/lib/hooks';
import { money } from '@/lib/format';

export function InventoryDetailPage() {
  const { uuid = '' } = useParams();
  const token = useStaffToken();
  const detailQuery = useDetail(`/inventory/${uuid}`, token, uuid.length > 0);
  const item = asData<JsonMap>(detailQuery.data ?? {});

  const [showAdjust, setShowAdjust] = useState(false);
  const [adjustQty, setAdjustQty] = useState('');
  const [adjustReason, setAdjustReason] = useState('restock');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();
  const [message, setMessage] = useState<string>();

  const stock = Number(item.stock_on_hand ?? item.stock_quantity ?? 0);
  const threshold = Number(item.low_stock_threshold ?? item.minimum_stock_level ?? 0);
  const isLowStock = threshold > 0 && stock <= threshold;

  async function refresh() {
    await detailQuery.refetch();
  }

  async function adjustStock() {
    const qty = Number(adjustQty);
    if (!Number.isFinite(qty) || qty === 0) {
      setError('Enter a valid adjustment quantity.');
      return;
    }
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/inventory/${uuid}/stock`, {
        method: 'PATCH',
        token,
        body: { adjustment: qty, reason: adjustReason },
      });
      setShowAdjust(false);
      setAdjustQty('');
      setMessage('Stock updated.');
      await refresh();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <StaffPage title={String(item.name ?? 'Part detail')} subtitle="Inventory item details and stock">
      <div className="toolbar">
        <Link to="/inventory">
          <Button type="button" variant="outline">
            Back to inventory
          </Button>
        </Link>
        <Button type="button" onClick={() => setShowAdjust(true)}>
          Adjust stock
        </Button>
      </div>

      {message ? <Alert variant="success">{message}</Alert> : null}
      {error ? <Alert variant="error">{error}</Alert> : null}
      {detailQuery.isLoading ? <LoadingState label="Loading part..." /> : null}

      <div className="detail-grid">
        <Card>
          <h3>Stock</h3>
          <div className="stack mt-3">
            <div className="line-item">
              <span>On hand</span>
              <span>
                {stock} {String(item.unit_of_measure ?? item.unit ?? 'pcs')}
                {isLowStock ? <span className="chip active chip-inline">Low stock</span> : null}
              </span>
            </div>
            <div className="line-item">
              <span>Low stock threshold</span>
              <span>{threshold || '-'}</span>
            </div>
            <div className="line-item">
              <span>Status</span>
              <span>{item.is_active === false ? 'Inactive' : 'Active'}</span>
            </div>
          </div>
        </Card>

        <Card>
          <h3>Details</h3>
          <div className="stack mt-3">
            <div className="line-item">
              <span>SKU</span>
              <span>{String(item.sku ?? '-')}</span>
            </div>
            <div className="line-item">
              <span>Brand</span>
              <span>{String(item.brand ?? '-')}</span>
            </div>
            <div className="line-item">
              <span>Category</span>
              <span>{String((item.category as JsonMap | undefined)?.name ?? '-')}</span>
            </div>
            <div className="line-item">
              <span>Cost price</span>
              <span>{money(item.cost_price)}</span>
            </div>
            <div className="line-item">
              <span>Selling price</span>
              <span>{money(item.selling_price)}</span>
            </div>
          </div>
        </Card>
      </div>

      {item.notes ? (
        <Card>
          <h3>Notes</h3>
          <p className="muted mt-3">{String(item.notes)}</p>
        </Card>
      ) : null}

      <Modal
        open={showAdjust}
        onClose={() => setShowAdjust(false)}
        title="Adjust stock"
        subtitle={`Current stock: ${stock}`}
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setShowAdjust(false)}>
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
            <FieldLabel htmlFor="detail-adjust-qty">Adjustment quantity</FieldLabel>
            <TextInput
              id="detail-adjust-qty"
              type="number"
              placeholder="e.g. 5 or -2"
              value={adjustQty}
              onChange={(event) => setAdjustQty(event.target.value)}
            />
          </div>
          <div>
            <FieldLabel htmlFor="detail-adjust-reason">Reason</FieldLabel>
            <SelectInput
              id="detail-adjust-reason"
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
        </div>
      </Modal>
    </StaffPage>
  );
}
