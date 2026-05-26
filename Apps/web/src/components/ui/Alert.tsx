import type { ReactNode } from 'react';

type AlertVariant = 'error' | 'success' | 'info';

export function Alert(props: { variant?: AlertVariant; children: ReactNode }) {
  const variant = props.variant ?? 'info';
  return <div className={`alert-banner alert-banner--${variant}`}>{props.children}</div>;
}
