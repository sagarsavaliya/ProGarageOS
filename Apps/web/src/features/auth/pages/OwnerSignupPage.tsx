import { useMemo, useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Button, Card } from '@/components/ui';
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
    <div className="auth-page">
      <Card className="auth-card">
        <h1>Owner Signup</h1>
        <p>Create a new garage account on GarageFlow.</p>

        <form className="auth-form" onSubmit={onSubmit}>
          <input
            placeholder="Business name"
            value={form.business_name}
            onChange={(event) => setForm((prev) => ({ ...prev, business_name: event.target.value }))}
            required
          />
          <input
            placeholder="First name"
            value={form.first_name}
            onChange={(event) => setForm((prev) => ({ ...prev, first_name: event.target.value }))}
            required
          />
          <input
            placeholder="Last name"
            value={form.last_name}
            onChange={(event) => setForm((prev) => ({ ...prev, last_name: event.target.value }))}
          />
          <input
            placeholder="Email (optional)"
            value={form.email}
            onChange={(event) => setForm((prev) => ({ ...prev, email: event.target.value }))}
            type="email"
          />
          <input
            placeholder="Phone"
            value={form.phone}
            onChange={(event) => setForm((prev) => ({ ...prev, phone: event.target.value }))}
            required
          />
          <select
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
          <input
            placeholder="6-digit PIN"
            value={form.pin}
            onChange={(event) => setForm((prev) => ({ ...prev, pin: event.target.value.replace(/\D/g, '').slice(0, 6) }))}
            inputMode="numeric"
            required
          />
          <input
            placeholder="Confirm PIN"
            value={form.pin_confirmation}
            onChange={(event) =>
              setForm((prev) => ({ ...prev, pin_confirmation: event.target.value.replace(/\D/g, '').slice(0, 6) }))
            }
            inputMode="numeric"
            required
          />

          {signupMutation.isError ? <div className="error-text">{(signupMutation.error as Error).message}</div> : null}

          <Button type="submit" disabled={signupMutation.isPending}>
            {signupMutation.isPending ? 'Creating account...' : 'Create account'}
          </Button>
        </form>

        <div className="auth-links">
          <Link to="/login">Back to login</Link>
        </div>
      </Card>
    </div>
  );
}
