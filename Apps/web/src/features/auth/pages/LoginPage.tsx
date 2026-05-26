import { useCallback, useEffect, useRef, useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Button, PinInput, Alert } from '@/components/ui';
import { AuthShell } from '@/layouts/AuthShell';
import { useAuth } from '@/lib/auth';

export function LoginPage() {
  const navigate = useNavigate();
  const auth = useAuth();
  const [login, setLogin] = useState('');
  const [pin, setPin] = useState('');
  const submittingRef = useRef(false);

  const submitLogin = useCallback(async () => {
    if (submittingRef.current || auth.loginPending || !login.trim() || pin.length !== 6) {
      return;
    }

    submittingRef.current = true;
    try {
      await auth.login({ login, pin });
      navigate('/dashboard', { replace: true });
    } catch {
      setPin('');
    } finally {
      submittingRef.current = false;
    }
  }, [auth, login, navigate, pin]);

  useEffect(() => {
    if (pin.length === 6 && login.trim()) {
      void submitLogin();
    }
  }, [pin, login, submitLogin]);

  const onSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    await submitLogin();
  };

  return (
    <AuthShell
      title="Staff login"
      subtitle="Sign in with your phone or email and 6-digit PIN."
      links={
        <>
          <Link to="/forgot-pin">Forgot PIN?</Link>
          <Link to="/signup">Create garage account</Link>
        </>
      }
    >
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
        <PinInput value={pin} onChange={setPin} onComplete={() => void submitLogin()} idPrefix="pin" />

        {auth.authError ? <Alert variant="error">{auth.authError}</Alert> : null}

        <Button type="submit" disabled={auth.loginPending || pin.length < 6}>
          {auth.loginPending ? 'Signing in...' : 'Sign in'}
        </Button>
      </form>
    </AuthShell>
  );
}
