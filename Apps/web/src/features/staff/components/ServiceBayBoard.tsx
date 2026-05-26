import { useState } from 'react';
import { Link } from 'react-router-dom';
import { SelectInput } from '@/components/ui';
import { StatusBadge } from '@/components/ui';
import type { JsonMap } from '@/lib/api';

const BAY_TYPE_LABELS: Record<string, string> = {
  general_lift: 'General lift',
  alignment: 'Alignment',
  paint_booth: 'Paint booth',
  wash_bay: 'Wash bay',
  diagnostic: 'Diagnostic',
  waiting_area: 'Waiting area',
};

const BAY_STATUS_OPTIONS = ['available', 'maintenance', 'reserved'];

function bayTypeLabel(type?: string): string {
  if (!type) {
    return 'Service bay';
  }
  return BAY_TYPE_LABELS[type] ?? type.replace(/_/g, ' ');
}

function bayJob(bay: JsonMap): JsonMap | null {
  const job = bay.job ?? bay.current_job;
  return job && typeof job === 'object' ? (job as JsonMap) : null;
}

function bayCardState(bay: JsonMap): 'available' | 'occupied' | 'maintenance' | 'reserved' {
  if (bayJob(bay)) {
    return 'occupied';
  }
  const status = String(bay.status ?? 'available');
  if (status === 'maintenance' || status === 'reserved') {
    return status;
  }
  return 'available';
}

function BayCard(props: {
  bay: JsonMap;
  onStatusChange?: (bayUuid: string, status: string) => Promise<void>;
}) {
  const state = bayCardState(props.bay);
  const job = bayJob(props.bay);
  const jobUuid = job ? String(job.uuid ?? '') : '';
  const jobNumber = job ? String(job.job_number ?? 'View job') : '';
  const vehicle = job ? String(job.vehicle ?? '') : '';
  const technician = job ? String(job.technician ?? '') : '';
  const bayUuid = String(props.bay.uuid ?? '');
  const [status, setStatus] = useState(String(props.bay.status ?? 'available'));
  const [saving, setSaving] = useState(false);

  async function applyStatus(nextStatus: string) {
    setStatus(nextStatus);
    if (!props.onStatusChange || !bayUuid) {
      return;
    }
    setSaving(true);
    try {
      await props.onStatusChange(bayUuid, nextStatus);
    } finally {
      setSaving(false);
    }
  }

  const card = (
    <article className={`bay-card bay-card--${state}`}>
      <div className="bay-card-top">
        <div className="bay-card-title-wrap">
          <span className={`bay-status-dot bay-status-dot--${state}`} aria-hidden />
          <div>
            <h4 className="bay-card-name">{String(props.bay.name ?? 'Bay')}</h4>
            <p className="bay-card-type">{bayTypeLabel(String(props.bay.type ?? props.bay.bay_type ?? ''))}</p>
          </div>
        </div>
        <span className="bay-code-chip">{String(props.bay.code ?? '—')}</span>
      </div>

      <div className="bay-card-body">
        {state === 'occupied' && job ? (
          <>
            <div className="bay-card-meta-row">
              <span className="bay-card-label">Active job</span>
              <StatusBadge status={String(job.status ?? 'in_progress')} />
            </div>
            <p className="bay-card-job">{jobNumber}</p>
            {vehicle ? <p className="bay-card-vehicle">{vehicle}</p> : null}
            {technician ? (
              <p className="bay-card-tech">
                <span className="bay-card-label-inline">Technician</span>
                {technician}
              </p>
            ) : null}
          </>
        ) : null}

        {state === 'available' ? (
          <>
            <p className="bay-card-state-label">Available</p>
            <p className="bay-card-hint">Ready for the next vehicle assignment.</p>
          </>
        ) : null}

        {state === 'maintenance' ? (
          <>
            <p className="bay-card-state-label">Under maintenance</p>
            <p className="bay-card-hint">Bay is offline until service is complete.</p>
          </>
        ) : null}

        {state === 'reserved' ? (
          <>
            <p className="bay-card-state-label">Reserved</p>
            <p className="bay-card-hint">Held for a scheduled arrival or booking.</p>
          </>
        ) : null}

        {props.onStatusChange && state !== 'occupied' ? (
          <div className="bay-card-actions">
            <SelectInput
              value={status}
              disabled={saving}
              onChange={(event) => void applyStatus(event.target.value)}
              aria-label={`Set status for ${String(props.bay.name ?? 'bay')}`}
            >
              {BAY_STATUS_OPTIONS.map((option) => (
                <option key={option} value={option}>
                  {option.replace(/_/g, ' ')}
                </option>
              ))}
            </SelectInput>
          </div>
        ) : null}
      </div>
    </article>
  );

  if (state === 'occupied' && jobUuid) {
    return (
      <Link to={`/jobs/${jobUuid}`} className="bay-card-link">
        {card}
      </Link>
    );
  }

  return card;
}

export function ServiceBayBoard(props: {
  bays: JsonMap[];
  onStatusChange?: (bayUuid: string, status: string) => Promise<void>;
}) {
  if (props.bays.length === 0) {
    return <p className="muted">No service bays configured yet. Add bays during setup or in Settings.</p>;
  }

  const occupied = props.bays.filter((bay) => bayCardState(bay) === 'occupied').length;
  const available = props.bays.filter((bay) => bayCardState(bay) === 'available').length;

  return (
    <div className="bay-board">
      <div className="bay-board-summary" aria-label="Bay occupancy summary">
        <span>
          <strong>{props.bays.length}</strong> total
        </span>
        <span className="bay-summary-occupied">
          <strong>{occupied}</strong> in use
        </span>
        <span className="bay-summary-free">
          <strong>{available}</strong> free
        </span>
      </div>
      <div className="bay-grid">
        {props.bays.map((bay) => (
          <BayCard
            key={String(bay.uuid ?? bay.code ?? bay.name)}
            bay={bay}
            onStatusChange={props.onStatusChange}
          />
        ))}
      </div>
    </div>
  );
}
