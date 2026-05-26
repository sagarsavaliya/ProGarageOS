import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { Button } from '@/components/ui';
import { AuthShell } from '@/layouts/AuthShell';
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
    <AuthShell
      title="Owner PIN setup"
      subtitle="Complete first-time PIN setup for your garage owner account."
      links={
        <>
          <Link to="/login">Back to login</Link>
          <Link to="/dashboard">Go to dashboard</Link>
        </>
      }
    >
      {!otpRequested ? (
        <form className="auth-form" onSubmit={requestOtp}>
          <label htmlFor="setup-login">Phone or email</label>
          <input
            id="setup-login"
            value={login}
            onChange={(event) => setLogin(event.target.value)}
            placeholder="Phone or email"
            required
          />
          {requestMutation.isError ? <div className="error-text">{(requestMutation.error as Error).message}</div> : null}
          <Button type="submit" disabled={requestMutation.isPending}>
            {requestMutation.isPending ? 'Requesting OTP...' : 'Request setup OTP'}
          </Button>
        </form>
      ) : (
        <form className="auth-form" onSubmit={setupPin}>
          <label htmlFor="setup-otp">OTP</label>
          <input id="setup-otp" value={otp} onChange={(event) => setOtp(event.target.value)} placeholder="Enter OTP" required />
          <label htmlFor="setup-pin">New PIN</label>
          <input
            id="setup-pin"
            value={pin}
            onChange={(event) => setPin(event.target.value.replace(/\D/g, '').slice(0, 6))}
            placeholder="6-digit PIN"
            inputMode="numeric"
            required
          />
          <label htmlFor="setup-pin-confirm">Confirm PIN</label>
          <input
            id="setup-pin-confirm"
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

      {message ? <p className="muted mt-3">{message}</p> : null}
    </AuthShell>
  );
}
