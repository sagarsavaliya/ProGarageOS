import { useMemo, useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui';
import { AuthShell } from '@/layouts/AuthShell';
import { useOwnerSignup, useSubscriptionPlans } from '@/lib/auth';
import type { JsonMap } from '@/lib/api';

function normalizePlans(raw: unknown): JsonMap[] {
  if (Array.isArray(raw)) {
    return raw as JsonMap[];
  }
  if (raw && typeof raw === 'object' && Array.isArray((raw as { items?: unknown[] }).items)) {
    return (raw as { items: JsonMap[] }).items;
  }
  return [];
}

export function OwnerSignupPage() {
  const navigate = useNavigate();
  const plansQuery = useSubscriptionPlans();
  const signupMutation = useOwnerSignup();
  const plans = useMemo(() => normalizePlans(plansQuery.data), [plansQuery.data]);

  const [form, setForm] = useState({
    business_name: '',
    first_name: '',
    last_name: '',
    email: '',
    phone: '',
    plan_slug: 'starter',
    pin: '',
    pin_confirmation: '',
  });

  const onSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    await signupMutation.mutateAsync(form);
    navigate('/login', { replace: true });
  };

  return (
    <AuthShell
      title="Create your garage"
      subtitle="Register a new GarageFlow account and choose your plan."
      wide
      links={<Link to="/login">Back to login</Link>}
    >
      <form className="auth-form" onSubmit={onSubmit}>
        <label htmlFor="business-name">Business name</label>
        <input
          id="business-name"
          placeholder="Auto Car Care"
          value={form.business_name}
          onChange={(event) => setForm((prev) => ({ ...prev, business_name: event.target.value }))}
          required
        />

        <div className="form-grid auth-form-grid">
          <div>
            <label htmlFor="first-name">First name</label>
            <input
              id="first-name"
              placeholder="First name"
              value={form.first_name}
              onChange={(event) => setForm((prev) => ({ ...prev, first_name: event.target.value }))}
              required
            />
          </div>
          <div>
            <label htmlFor="last-name">Last name</label>
            <input
              id="last-name"
              placeholder="Last name"
              value={form.last_name}
              onChange={(event) => setForm((prev) => ({ ...prev, last_name: event.target.value }))}
            />
          </div>
        </div>

        <label htmlFor="signup-email">Email (optional)</label>
        <input
          id="signup-email"
          placeholder="owner@garage.com"
          value={form.email}
          onChange={(event) => setForm((prev) => ({ ...prev, email: event.target.value }))}
          type="email"
        />

        <label htmlFor="signup-phone">Phone</label>
        <input
          id="signup-phone"
          placeholder="9876543219"
          value={form.phone}
          onChange={(event) => setForm((prev) => ({ ...prev, phone: event.target.value }))}
          required
        />

        <label htmlFor="plan-slug">Plan</label>
        <select
          id="plan-slug"
          value={form.plan_slug}
          onChange={(event) => setForm((prev) => ({ ...prev, plan_slug: event.target.value }))}
        >
          {plans.length === 0 ? <option value="starter">Starter</option> : null}
          {plans.map((plan) => (
            <option key={String(plan.slug ?? plan.uuid ?? plan.name)} value={String(plan.slug ?? 'starter')}>
              {String(plan.name ?? plan.slug ?? 'Plan')}
            </option>
          ))}
        </select>

        <div className="form-grid auth-form-grid">
          <div>
            <label htmlFor="signup-pin">6-digit PIN</label>
            <input
              id="signup-pin"
              placeholder="••••••"
              value={form.pin}
              onChange={(event) => setForm((prev) => ({ ...prev, pin: event.target.value.replace(/\D/g, '').slice(0, 6) }))}
              inputMode="numeric"
              required
            />
          </div>
          <div>
            <label htmlFor="signup-pin-confirm">Confirm PIN</label>
            <input
              id="signup-pin-confirm"
              placeholder="••••••"
              value={form.pin_confirmation}
              onChange={(event) =>
                setForm((prev) => ({ ...prev, pin_confirmation: event.target.value.replace(/\D/g, '').slice(0, 6) }))
              }
              inputMode="numeric"
              required
            />
          </div>
        </div>

        {signupMutation.isError ? <div className="error-text">{(signupMutation.error as Error).message}</div> : null}

        <Button type="submit" disabled={signupMutation.isPending}>
          {signupMutation.isPending ? 'Creating account...' : 'Create account'}
        </Button>
      </form>
    </AuthShell>
  );
}
