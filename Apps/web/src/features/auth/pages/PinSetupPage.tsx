import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { Button, Card } from '@/components/ui';
import { useAuth, usePinOtpRequest, usePinOtpReset } from '@/lib/auth';

export function PinSetupPage() {
  const auth = useAuth();
  const requestMutation = usePinOtpRequest();
  const resetMutation = usePinOtpReset();
  const defaultLogin = auth.user?.phone ?? auth.user?.email ?? '';

  const [login, setLogin] = useState(defaultLogin);
  const [otp, setOtp] = useState('');
  const [pin, setPin] = useState('');
  const [pinConfirmation, setPinConfirmation] = useState('');
  const [otpRequested, setOtpRequested] = useState(false);
  const [message, setMessage] = useState('');

  const requestOtp = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    await requestMutation.mutateAsync({ login, purpose: 'setup' });
    setOtpRequested(true);
    setMessage('OTP sent. Complete setup by creating a new PIN.');
  };

  const setupPin = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    await resetMutation.mutateAsync({
      login,
      otp,
      pin,
      pin_confirmation: pinConfirmation,
      purpose: 'setup',
    });
    setMessage('PIN setup complete. Continue to dashboard.');
  };

  return (
    <div className="auth-page">
      <Card className="auth-card">
        <h1>Owner PIN Setup</h1>
        <p>Complete your first-time PIN setup for this account.</p>

        {!otpRequested ? (
          <form className="auth-form" onSubmit={requestOtp}>
            <input value={login} onChange={(event) => setLogin(event.target.value)} placeholder="Phone or email" required />
            {requestMutation.isError ? <div className="error-text">{(requestMutation.error as Error).message}</div> : null}
            <Button type="submit" disabled={requestMutation.isPending}>
              {requestMutation.isPending ? 'Requesting OTP...' : 'Request Setup OTP'}
            </Button>
          </form>
        ) : (
          <form className="auth-form" onSubmit={setupPin}>
            <input value={otp} onChange={(event) => setOtp(event.target.value)} placeholder="OTP" required />
            <input
              value={pin}
              onChange={(event) => setPin(event.target.value.replace(/\D/g, '').slice(0, 6))}
              placeholder="New PIN"
              inputMode="numeric"
              required
            />
            <input
              value={pinConfirmation}
              onChange={(event) => setPinConfirmation(event.target.value.replace(/\D/g, '').slice(0, 6))}
              placeholder="Confirm PIN"
              inputMode="numeric"
              required
            />
            {resetMutation.isError ? <div className="error-text">{(resetMutation.error as Error).message}</div> : null}
            <Button type="submit" disabled={resetMutation.isPending}>
              {resetMutation.isPending ? 'Saving PIN...' : 'Save PIN'}
            </Button>
          </form>
        )}

        {message ? <p className="muted" style={{ marginTop: 12 }}>{message}</p> : null}
        <div className="auth-links">
          <Link to="/login">Back to login</Link>
          <Link to="/dashboard">Go to dashboard</Link>
        </div>
      </Card>
    </div>
  );
}
