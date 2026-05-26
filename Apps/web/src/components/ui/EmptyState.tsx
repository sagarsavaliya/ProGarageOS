import type { ReactNode } from 'react';

export function EmptyState(props: { title: string; description?: string; action?: ReactNode }) {
  return (
    <div className="empty-state-panel">
      <div className="empty-state-icon" aria-hidden>
        <svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="var(--gf-primary)" strokeWidth="1.75">
          <rect x="4" y="4" width="16" height="16" rx="3" />
          <path d="M8 12h8M12 8v8" opacity="0.5" />
        </svg>
      </div>
      <h4>{props.title}</h4>
      {props.description ? <p className="muted">{props.description}</p> : null}
      {props.action ? <div className="empty-state-action">{props.action}</div> : null}
    </div>
  );
}
