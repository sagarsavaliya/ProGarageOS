import { Navigate, Route, Routes } from 'react-router-dom';
import { Card } from '@/components/ui/Card';

function AdminPlaceholder() {
  return (
    <div className="auth-page login-theme admin-shell">
      <Card className="auth-card auth-card-elevated admin-card">
        <div className="auth-brand">
          <div className="auth-brand-badge">GF</div>
          <div>
            <h1>GarageFlow</h1>
            <p>Platform Admin</p>
          </div>
        </div>
        <h2 className="auth-title">Admin portal</h2>
        <p>Super-admin tools are scheduled for the next release phase.</p>
      </Card>
    </div>
  );
}

export function AdminRoutes() {
  return (
    <Routes>
      <Route path="/" element={<AdminPlaceholder />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
