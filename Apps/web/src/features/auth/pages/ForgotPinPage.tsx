import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { Button } from '@/components/ui';
import { AuthShell } from '@/layouts/AuthShell';
import { usePinOtpRequest, usePinOtpReset } from '@/lib/auth';

export function ForgotPinPage() {
  const requestMutation = usePinOtpRequest();
  const resetMutation = usePinOtpReset();

  const [login, setLogin] = useState('');
  const [otp, setOtp] = useState('');
  const [pin, setPin] = useState('');
  const [pinConfirmation, setPinConfirmation] = useState('');
  const [otpRequested, setOtpRequested] = useState(false);
  const [message, setMessage] = useState('');

  const requestOtp = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    await requestMutation.mutateAsync({ login, purpose: 'reset' });
    setOtpRequested(true);
    setMessage('OTP sent. Enter OTP and your new PIN.');
  };

  const resetPin = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    await resetMutation.mutateAsync({
      login,
      otp,
      pin,
      pin_confirmation: pinConfirmation,
      purpose: 'reset',
    });
    setMessage('PIN reset successful. You can login now.');
  };

  return (
    <AuthShell
      title="Forgot PIN"
      subtitle="Request a one-time code and set a new staff PIN."
      links={<Link to="/login">Back to login</Link>}
    >
      {!otpRequested ? (
        <form className="auth-form" onSubmit={requestOtp}>
          <label htmlFor="forgot-login">Phone or email</label>
          <input
            id="forgot-login"
            value={login}
            onChange={(event) => setLogin(event.target.value)}
            placeholder="9876543219 or staff@garage.com"
            required
          />
          {requestMutation.isError ? <div className="error-text">{(requestMutation.error as Error).message}</div> : null}
          <Button type="submit" disabled={requestMutation.isPending}>
            {requestMutation.isPending ? 'Requesting OTP...' : 'Request OTP'}
          </Button>
        </form>
      ) : (
        <form className="auth-form" onSubmit={resetPin}>
          <label htmlFor="forgot-otp">OTP</label>
          <input id="forgot-otp" value={otp} onChange={(event) => setOtp(event.target.value)} placeholder="Enter OTP" required />
          <label htmlFor="forgot-pin">New PIN</label>
          <input
            id="forgot-pin"
            value={pin}
            onChange={(event) => setPin(event.target.value.replace(/\D/g, '').slice(0, 6))}
            placeholder="6-digit PIN"
            inputMode="numeric"
            required
          />
          <label htmlFor="forgot-pin-confirm">Confirm PIN</label>
          <input
            id="forgot-pin-confirm"
            value={pinConfirmation}
            onChange={(event) => setPinConfirmation(event.target.value.replace(/\D/g, '').slice(0, 6))}
            placeholder="Confirm PIN"
            inputMode="numeric"
            required
          />
          {resetMutation.isError ? <div className="error-text">{(resetMutation.error as Error).message}</div> : null}
          <Button type="submit" disabled={resetMutation.isPending}>
            {resetMutation.isPending ? 'Resetting PIN...' : 'Reset PIN'}
          </Button>
        </form>
      )}

      {message ? <p className="muted mt-3">{message}</p> : null}
    </AuthShell>
  );
}
