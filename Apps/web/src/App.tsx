import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '@/lib/auth';
import { ACTIVE_PORTAL } from '@/lib/portal';
import { StaffRoutes } from '@/router/StaffRoutes';
import { AdminRoutes } from '@/router/AdminRoutes';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>{ACTIVE_PORTAL === 'admin' ? <AdminRoutes /> : <StaffRoutes />}</BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}
