const STATUS_PALETTE: Record<string, string> = {
  draft: 'status-draft',
  intake_inspection: 'status-intake',
  estimate_pending: 'status-estimate',
  estimate_approved: 'status-approved',
  in_progress: 'status-progress',
  qc_pending: 'status-qc',
  ready_for_delivery: 'status-ready',
  delivered: 'status-delivered',
  cancelled: 'status-cancelled',
  on_hold: 'status-hold',
  active: 'status-ready',
  trial: 'status-estimate',
  suspended: 'status-cancelled',
  churned: 'status-draft',
};

function normalizeStatus(value: string | undefined): string {
  if (!value) {
    return 'unknown';
  }
  return value.replace(/_/g, ' ');
}

export function StatusBadge(props: { status?: string }) {
  const key = props.status ?? 'draft';
  const cls = STATUS_PALETTE[key] ?? 'status-draft';
  return <span className={`status-badge ${cls}`}>{normalizeStatus(key)}</span>;
}
