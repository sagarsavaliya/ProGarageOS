import { Navigate, Outlet, Route, Routes, useLocation } from 'react-router-dom';
import { LoginPage } from '@/features/auth/pages/LoginPage';
import { OwnerSignupPage } from '@/features/auth/pages/OwnerSignupPage';
import { ForgotPinPage } from '@/features/auth/pages/ForgotPinPage';
import { PinSetupPage } from '@/features/auth/pages/PinSetupPage';
import { OnboardingSetupPage } from '@/features/auth/pages/OnboardingSetupPage';
import { DashboardPage } from '@/features/staff/pages/DashboardPage';
import { ComingSoonPage } from '@/features/staff/pages/ComingSoonPage';
import { useAuth } from '@/lib/auth';

function RequireAuth() {
  const auth = useAuth();
  const location = useLocation();

  if (!auth.isReady) {
    return <div className="center-state">Checking session...</div>;
  }
  if (!auth.isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  if (auth.isOwnerSetupIncomplete && location.pathname !== '/onboarding/setup' && location.pathname !== '/pin-setup') {
    return <Navigate to="/onboarding/setup" replace />;
  }
  if (!auth.isOwnerSetupIncomplete && location.pathname === '/onboarding/setup') {
    return <Navigate to="/dashboard" replace />;
  }
  return <Outlet />;
}

function GuestOnly() {
  const auth = useAuth();
  if (auth.isAuthenticated) {
    return <Navigate to="/dashboard" replace />;
  }
  return <Outlet />;
}

function WithShellPage(props: { title: string }) {
  const auth = useAuth();
  return <ComingSoonPage title={props.title} userName={auth.user?.name} onLogout={auth.logout} />;
}

export function StaffRoutes() {
  const auth = useAuth();

  return (
    <Routes>
      <Route element={<GuestOnly />}>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/signup" element={<OwnerSignupPage />} />
        <Route path="/forgot-pin" element={<ForgotPinPage />} />
      </Route>

      <Route element={<RequireAuth />}>
        <Route path="/dashboard" element={<DashboardPage token={auth.token} userName={auth.user?.name} onLogout={auth.logout} />} />
        <Route path="/onboarding/setup" element={<OnboardingSetupPage />} />
        <Route path="/pin-setup" element={<PinSetupPage />} />
        <Route path="/jobs" element={<WithShellPage title="Jobs" />} />
        <Route path="/customers" element={<WithShellPage title="Customers" />} />
        <Route path="/vehicles" element={<WithShellPage title="Vehicles" />} />
        <Route path="/appointments" element={<WithShellPage title="Appointments" />} />
        <Route path="/inventory" element={<WithShellPage title="Inventory" />} />
        <Route path="/billing" element={<WithShellPage title="Billing" />} />
        <Route path="/reports" element={<WithShellPage title="Reports" />} />
        <Route path="/settings" element={<WithShellPage title="Settings" />} />
        <Route path="/notifications" element={<WithShellPage title="Notifications" />} />
      </Route>

      <Route path="/" element={<Navigate to="/dashboard" replace />} />
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}
