import { useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Button, Card, PinInput, Alert } from '@/components/ui';
import { useAuth } from '@/lib/auth';

export function LoginPage() {
  const navigate = useNavigate();
  const auth = useAuth();
  const [login, setLogin] = useState('');
  const [pin, setPin] = useState('');

  const onSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    await auth.login({ login, pin });
    navigate('/dashboard', { replace: true });
  };

  return (
    <div className="auth-page login-theme">
      <Card className="auth-card auth-card-elevated">
        <div className="auth-brand">
          <div className="auth-brand-badge">GF</div>
          <div>
            <h1>GarageFlow</h1>
            <p>Garage Operations Platform</p>
          </div>
        </div>

        <h2 className="auth-title">Staff Login</h2>

        <form className="auth-form" onSubmit={onSubmit}>
          <label htmlFor="login">Phone or email</label>
          <input
            id="login"
            type="text"
            inputMode="text"
            value={login}
            onChange={(event) => setLogin(event.target.value)}
            placeholder="9876543219 or name@garage.com"
            required
          />

          <label htmlFor="pin-0">6-digit PIN</label>
          <PinInput value={pin} onChange={setPin} idPrefix="pin" />

          {auth.authError ? <Alert variant="error">{auth.authError}</Alert> : null}

          <Button type="submit" disabled={auth.loginPending || pin.length < 6}>
            {auth.loginPending ? 'Signing in...' : 'Sign in'}
          </Button>
        </form>

        <div className="auth-links">
          <Link to="/forgot-pin">Forgot PIN?</Link>
          <Link to="/signup">Create garage account</Link>
        </div>
      </Card>
    </div>
  );
}
