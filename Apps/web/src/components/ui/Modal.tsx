import type { ReactNode } from 'react';

export function Modal(props: {
  open: boolean;
  onClose: () => void;
  title: string;
  subtitle?: string;
  children: ReactNode;
  footer?: ReactNode;
  wide?: boolean;
}) {
  if (!props.open) {
    return null;
  }

  return (
    <div className="modal-overlay" onClick={props.onClose} role="presentation">
      <div
        className={`modal-card ${props.wide ? 'modal-card--wide' : ''}`.trim()}
        onClick={(event) => event.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="modal-title"
      >
        <div className="modal-header">
          <div>
            <h3 id="modal-title">{props.title}</h3>
            {props.subtitle ? <p className="muted section-subtitle">{props.subtitle}</p> : null}
          </div>
          <button type="button" className="modal-close" onClick={props.onClose} aria-label="Close">
            <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden>
              <path d="M18 6L6 18M6 6l12 12" />
            </svg>
          </button>
        </div>
        <div className="modal-body">{props.children}</div>
        {props.footer ? <div className="modal-footer">{props.footer}</div> : null}
      </div>
    </div>
  );
}

export function ModalActions(props: { children: ReactNode }) {
  return <div className="modal-actions">{props.children}</div>;
}
