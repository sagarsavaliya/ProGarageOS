import type { ReactNode } from 'react';

export function EmptyState(props: { title: string; description?: string; action?: ReactNode }) {
  return (
    <div className="empty-state-panel">
      <div className="empty-state-icon" aria-hidden />
      <h4>{props.title}</h4>
      {props.description ? <p className="muted">{props.description}</p> : null}
      {props.action ? <div className="empty-state-action">{props.action}</div> : null}
    </div>
  );
}
