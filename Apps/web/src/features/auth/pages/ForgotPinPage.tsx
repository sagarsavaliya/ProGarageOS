import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { Button, Card } from '@/components/ui';
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
    <div className="auth-page">
      <Card className="auth-card">
        <h1>Forgot PIN</h1>
        <p>Request OTP and reset your staff PIN.</p>

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
              {resetMutation.isPending ? 'Resetting PIN...' : 'Reset PIN'}
            </Button>
          </form>
        )}

        {message ? <p className="muted" style={{ marginTop: 12 }}>{message}</p> : null}
        <div className="auth-links">
          <Link to="/login">Back to login</Link>
        </div>
      </Card>
    </div>
  );
}
