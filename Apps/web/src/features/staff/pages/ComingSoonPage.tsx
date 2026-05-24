import { StaffShell } from '@/layouts/StaffShell';
import { Card } from '@/components/ui/Card';

export function ComingSoonPage(props: {
  title: string;
  userName?: string;
  onLogout: () => void;
}) {
  return (
    <StaffShell title={props.title} userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <h3>{props.title}</h3>
        <p className="muted" style={{ marginTop: 8 }}>
          Coming in Phase 1.
        </p>
      </Card>
    </StaffShell>
  );
}
