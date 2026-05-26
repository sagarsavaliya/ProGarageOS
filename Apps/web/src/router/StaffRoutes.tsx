import { Navigate, Outlet, Route, Routes, useLocation } from 'react-router-dom';
import { LoginPage } from '@/features/auth/pages/LoginPage';
import { OwnerSignupPage } from '@/features/auth/pages/OwnerSignupPage';
import { ForgotPinPage } from '@/features/auth/pages/ForgotPinPage';
import { PinSetupPage } from '@/features/auth/pages/PinSetupPage';
import { OnboardingSetupPage } from '@/features/auth/pages/OnboardingSetupPage';
import { DashboardPage } from '@/features/staff/pages/DashboardPage';
import { JobsListPage } from '@/features/staff/pages/JobsListPage';
import { JobDetailPage } from '@/features/staff/pages/JobDetailPage';
import { CreateJobPage } from '@/features/staff/pages/CreateJobPage';
import { CustomersListPage } from '@/features/staff/pages/CustomersListPage';
import { CustomerDetailPage } from '@/features/staff/pages/CustomerDetailPage';
import { VehiclesListPage } from '@/features/staff/pages/VehiclesListPage';
import { VehicleDetailPage } from '@/features/staff/pages/VehicleDetailPage';
import { AppointmentsPage } from '@/features/staff/pages/AppointmentsPage';
import { InventoryPage } from '@/features/staff/pages/InventoryPage';
import { BillingListPage } from '@/features/staff/pages/BillingListPage';
import { BillingDetailPage } from '@/features/staff/pages/BillingDetailPage';
import { InspectionPage } from '@/features/staff/pages/InspectionPage';
import { ReportsPage } from '@/features/staff/pages/ReportsPage';
import { SettingsPage } from '@/features/staff/pages/SettingsPage';
import { NotificationsPage } from '@/features/staff/pages/NotificationsPage';
import { AuditPage } from '@/features/staff/pages/AuditPage';
import { useAuth } from '@/lib/auth';
import { LoadingState } from '@/components/ui';

function RequireAuth() {
  const auth = useAuth();
  const location = useLocation();

  if (!auth.isReady) {
    return (
      <div className="center-state">
        <LoadingState label="Checking session..." />
      </div>
    );
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
        <Route path="/jobs" element={<JobsListPage />} />
        <Route path="/jobs/new" element={<CreateJobPage />} />
        <Route path="/jobs/:uuid/inspection" element={<InspectionPage />} />
        <Route path="/jobs/:uuid" element={<JobDetailPage />} />
        <Route path="/customers" element={<CustomersListPage />} />
        <Route path="/customers/:uuid" element={<CustomerDetailPage />} />
        <Route path="/vehicles" element={<VehiclesListPage />} />
        <Route path="/vehicles/:uuid" element={<VehicleDetailPage />} />
        <Route path="/appointments" element={<AppointmentsPage />} />
        <Route path="/inventory" element={<InventoryPage />} />
        <Route path="/billing" element={<BillingListPage />} />
        <Route path="/billing/:uuid" element={<BillingDetailPage />} />
        <Route path="/reports" element={<ReportsPage />} />
        <Route path="/settings" element={<SettingsPage />} />
        <Route path="/notifications" element={<NotificationsPage />} />
        <Route path="/audit" element={<AuditPage />} />
      </Route>

      <Route path="/" element={<Navigate to="/dashboard" replace />} />
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}
