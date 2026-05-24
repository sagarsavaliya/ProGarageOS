import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { ApiError, apiRequest, asData, extractToken, normalizeLogin, type JsonMap } from '@/lib/api';
import { ACTIVE_PORTAL, getTokenStorageKey } from '@/lib/portal';

export type AppUser = {
  uuid?: string;
  name?: string;
  first_name?: string;
  last_name?: string;
  email?: string;
  phone?: string;
  role?: string;
  is_platform_admin?: boolean;
  onboarding_completed?: boolean;
  setup_completed?: boolean;
  tenant?: {
    setup_complete?: boolean;
    setup_step?: string;
  };
};

type AuthContextValue = {
  token: string;
  user?: AppUser;
  isReady: boolean;
  isAuthenticated: boolean;
  isOwnerSetupIncomplete: boolean;
  login: (params: { login: string; pin: string }) => Promise<AppUser>;
  logout: () => Promise<void>;
  loginPending: boolean;
  logoutPending: boolean;
  authError?: string;
};

type PinOtpPurpose = 'setup' | 'reset';

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

function extractUser(payload: unknown): AppUser {
  const data = asData<JsonMap | AppUser>(payload);
  let user: AppUser;
  if (data && typeof data === 'object' && 'user' in (data as JsonMap)) {
    user = { ...(((data as JsonMap).user as AppUser) ?? {}) };
  } else {
    user = { ...(data as AppUser) };
  }

  const tenant = user.tenant;
  if (tenant?.setup_complete !== undefined && user.setup_completed === undefined) {
    user.setup_completed = tenant.setup_complete;
  }

  if (!user.name) {
    const fullName = `${user.first_name ?? ''} ${user.last_name ?? ''}`.trim();
    if (fullName) {
      user.name = fullName;
    }
  }

  return user;
}

function isOwner(user?: AppUser): boolean {
  if (!user) {
    return false;
  }
  const role = String(user.role ?? '').toLowerCase();
  return role === 'owner';
}

function hasCompletedOwnerSetup(user?: AppUser): boolean {
  if (!user) {
    return false;
  }
  if (!isOwner(user)) {
    return true;
  }

  if (user.tenant?.setup_complete === true || user.setup_completed === true || user.onboarding_completed === true) {
    return true;
  }

  if (user.tenant?.setup_complete === false || user.setup_completed === false || user.onboarding_completed === false) {
    return false;
  }

  return false;
}

export function AuthProvider(props: { children: ReactNode }) {
  const queryClient = useQueryClient();
  const tokenKey = getTokenStorageKey(ACTIVE_PORTAL);
  const [token, setToken] = useState<string>(() => localStorage.getItem(tokenKey) ?? '');
  const [authError, setAuthError] = useState<string>();

  const meQuery = useQuery({
    queryKey: ['auth-me', token, ACTIVE_PORTAL],
    enabled: token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/auth/me', { token });
      return extractUser(payload);
    },
  });

  const isOwnerSetupIncomplete =
    token.length > 0 &&
    meQuery.isSuccess &&
    isOwner(meQuery.data) &&
    !hasCompletedOwnerSetup(meQuery.data);

  useEffect(() => {
    if (!meQuery.data) {
      return;
    }
    const isPlatformAdmin = Boolean(meQuery.data.is_platform_admin);
    const portalMismatch =
      (ACTIVE_PORTAL === 'admin' && !isPlatformAdmin) ||
      (ACTIVE_PORTAL === 'staff' && isPlatformAdmin);

    if (portalMismatch) {
      localStorage.removeItem(tokenKey);
      setToken('');
    }
  }, [meQuery.data, tokenKey]);

  const loginMutation = useMutation({
    mutationFn: async (params: { login: string; pin: string }) => {
      setAuthError(undefined);
      const payload = await apiRequest('/auth/staff/login', {
        method: 'POST',
        body: { login: normalizeLogin(params.login), pin: params.pin },
      });
      const loginToken = extractToken(payload);
      const user = extractUser(payload);
      const isPlatformAdmin = Boolean(user.is_platform_admin);

      if (!loginToken) {
        throw new ApiError('Token missing in login response', 500);
      }
      if (ACTIVE_PORTAL === 'admin' && !isPlatformAdmin) {
        throw new ApiError('This account is not allowed on admin portal', 403);
      }
      if (ACTIVE_PORTAL === 'staff' && isPlatformAdmin) {
        throw new ApiError('Platform admin accounts must sign in at admin subdomain', 403);
      }

      localStorage.setItem(tokenKey, loginToken);
      setToken(loginToken);
      await queryClient.invalidateQueries({ queryKey: ['auth-me'] });
      return user;
    },
    onError: (error) => {
      setAuthError((error as Error).message);
    },
  });

  const logoutMutation = useMutation({
    mutationFn: async () => {
      if (token) {
        await apiRequest('/auth/logout', { method: 'POST', token });
      }
      localStorage.removeItem(tokenKey);
      setToken('');
      queryClient.clear();
    },
  });

  const value = useMemo<AuthContextValue>(
    () => ({
      token,
      user: meQuery.data,
      isReady: token.length === 0 || meQuery.isFetched,
      isAuthenticated: token.length > 0,
      isOwnerSetupIncomplete,
      login: (params) => loginMutation.mutateAsync(params),
      logout: () => logoutMutation.mutateAsync(),
      loginPending: loginMutation.isPending,
      logoutPending: logoutMutation.isPending,
      authError,
    }),
    [
      token,
      meQuery.data,
      meQuery.isFetched,
      isOwnerSetupIncomplete,
      loginMutation,
      logoutMutation,
      authError,
    ],
  );

  return <AuthContext.Provider value={value}>{props.children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used inside AuthProvider');
  }
  return context;
}

export function useSubscriptionPlans() {
  return useQuery({
    queryKey: ['subscription-plans'],
    queryFn: async () => {
      const payload = await apiRequest('/subscription-plans');
      return asData<JsonMap[] | { items: JsonMap[] }>(payload);
    },
  });
}

export function useOwnerSignup() {
  return useMutation({
    mutationFn: async (body: {
      business_name: string;
      first_name: string;
      last_name?: string;
      email?: string;
      phone: string;
      plan_slug: string;
      pin: string;
      pin_confirmation: string;
    }) => apiRequest('/auth/owner/signup', { method: 'POST', body }),
  });
}

export function usePinOtpRequest() {
  return useMutation({
    mutationFn: async (body: { login: string; purpose: PinOtpPurpose }) =>
      apiRequest('/auth/staff/pin-otp/request', {
        method: 'POST',
        body: { login: normalizeLogin(body.login), purpose: body.purpose },
      }),
  });
}

export function usePinOtpReset() {
  return useMutation({
    mutationFn: async (body: {
      login: string;
      otp: string;
      pin: string;
      pin_confirmation: string;
      purpose: PinOtpPurpose;
    }) =>
      apiRequest('/auth/staff/pin-otp/reset', {
        method: 'POST',
        body: {
          login: normalizeLogin(body.login),
          otp: body.otp,
          pin: body.pin,
          pin_confirmation: body.pin_confirmation,
          purpose: body.purpose,
        },
      }),
  });
}
