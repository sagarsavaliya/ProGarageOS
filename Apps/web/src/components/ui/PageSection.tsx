import type { ReactNode } from 'react';
import { Card } from '@/components/ui/Card';

export function PageSection(props: {
  title: string;
  subtitle?: string;
  children: ReactNode;
  className?: string;
  action?: ReactNode;
}) {
  return (
    <Card className={props.className}>
      <div className="section-header">
        <div>
          <h3>{props.title}</h3>
          {props.subtitle ? <p className="muted section-subtitle">{props.subtitle}</p> : null}
        </div>
        {props.action ? <div className="section-header-action">{props.action}</div> : null}
      </div>
      {props.children}
    </Card>
  );
}
