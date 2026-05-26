import type { ReactNode } from 'react';
import { Card } from '@/components/ui/Card';

export function AuthShell(props: {
  title: string;
  subtitle?: string;
  children: ReactNode;
  links?: ReactNode;
  wide?: boolean;
}) {
  return (
    <div className="auth-page login-theme">
      <Card className={`auth-card auth-card-elevated ${props.wide ? 'auth-card--wide' : ''}`.trim()}>
        <div className="auth-brand">
          <div className="auth-brand-badge">GF</div>
          <div>
            <h1>GarageFlow</h1>
            <p>Garage Operations Platform</p>
          </div>
        </div>

        <h2 className="auth-title">{props.title}</h2>
        {props.subtitle ? <p className="muted auth-subtitle">{props.subtitle}</p> : null}

        {props.children}
        {props.links ? <div className="auth-links">{props.links}</div> : null}
      </Card>
    </div>
  );
}
