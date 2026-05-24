import type { ReactNode } from 'react';
import { StaffShell } from '@/layouts/StaffShell';
import { useAuth } from '@/lib/auth';

export function StaffPage(props: { title: string; subtitle?: string; children: ReactNode }) {
  const auth = useAuth();
  return (
    <StaffShell
      title={props.title}
      subtitle={props.subtitle}
      userName={auth.user?.name}
      onLogout={() => auth.logout()}
    >
      {props.children}
    </StaffShell>
  );
}

export function useStaffToken() {
  const auth = useAuth();
  return auth.token;
}
