import { Link } from 'react-router-dom';
import { Button, Card } from '@/components/ui';

export function OnboardingSetupPage() {
  return (
    <div className="auth-page">
      <Card className="auth-card">
        <h1>Setup Required</h1>
        <p>Your owner account setup is incomplete. Complete PIN setup to continue.</p>
        <div className="stack" style={{ marginTop: 16 }}>
          <Link to="/pin-setup">
            <Button type="button">Complete PIN Setup</Button>
          </Link>
          <Link to="/dashboard">Skip for now</Link>
        </div>
      </Card>
    </div>
  );
}
