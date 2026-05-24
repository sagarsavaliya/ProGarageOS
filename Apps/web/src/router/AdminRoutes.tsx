import { Navigate, Route, Routes } from 'react-router-dom';
import { Card } from '@/components/ui/Card';

function AdminPlaceholder() {
  return (
    <div className="auth-page">
      <Card className="auth-card">
        <h1>Admin Portal</h1>
        <p>Admin portal is intentionally minimal in Phase 0.</p>
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
