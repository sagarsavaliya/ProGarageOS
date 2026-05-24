import { Card } from '@/components/ui/Card';

export function KPICard(props: { label: string; value: string | number; helper?: string }) {
  return (
    <Card>
      <div className="kpi-label">{props.label}</div>
      <div className="kpi-value">{props.value}</div>
      <div className="kpi-helper">{props.helper ?? ''}</div>
    </Card>
  );
}
