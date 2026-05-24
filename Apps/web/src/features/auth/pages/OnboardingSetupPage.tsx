import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Button, Card } from '@/components/ui';
import { FieldLabel, TextInput } from '@/components/ui/FormField';
import { apiRequest, asData, type JsonMap } from '@/lib/api';
import { useAuth } from '@/lib/auth';

export function OnboardingSetupPage() {
  const auth = useAuth();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const token = auth.token;

  const [step, setStep] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>();
  const [profileForm, setProfileForm] = useState({
    business_name: '',
    phone: '',
    email: '',
    address: '',
    gst_number: '',
  });
  const [bayCount, setBayCount] = useState('2');

  const profileQuery = useQuery({
    queryKey: ['onboarding-profile', token],
    enabled: token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/tenant/profile', { token });
      return asData<JsonMap>(payload);
    },
  });

  useEffect(() => {
    const profile = profileQuery.data;
    if (!profile) {
      return;
    }
    if (profile.setup_completed_at) {
      navigate('/dashboard', { replace: true });
      return;
    }
    setProfileForm({
      business_name: String(profile.business_name ?? ''),
      phone: String(profile.phone ?? ''),
      email: String(profile.email ?? ''),
      address: String(profile.address ?? ''),
      gst_number: String(profile.gst_number ?? ''),
    });
    if (profile.setup_bay_count) {
      setBayCount(String(profile.setup_bay_count));
    }
    const setupStep = String(profile.setup_step ?? 'welcome');
    if (setupStep === 'details') {
      setStep(1);
    } else if (setupStep === 'bays') {
      setStep(2);
    } else if (setupStep === 'done') {
      setStep(3);
    }
  }, [profileQuery.data, navigate]);

  async function syncSetup(body: JsonMap) {
    await apiRequest('/tenant/setup', { method: 'PATCH', token, body });
  }

  async function saveBusinessDetails(event: React.FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError(undefined);
    try {
      await apiRequest('/tenant/profile', {
        method: 'PUT',
        token,
        body: {
          business_name: profileForm.business_name.trim(),
          phone: profileForm.phone.trim() || undefined,
          email: profileForm.email.trim() || undefined,
          address: profileForm.address.trim() || undefined,
          gst_number: profileForm.gst_number.trim() || undefined,
        },
      });
      await syncSetup({ setup_step: 'bays' });
      setStep(2);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setLoading(false);
    }
  }

  async function saveBayCount(event: React.FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError(undefined);
    try {
      const bays = Math.min(50, Math.max(1, Number(bayCount) || 2));
      await syncSetup({ setup_step: 'bays', setup_bay_count: bays });
      setStep(3);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setLoading(false);
    }
  }

  async function completeSetup() {
    setLoading(true);
    setError(undefined);
    try {
      await syncSetup({ complete: true });
      await queryClient.invalidateQueries({ queryKey: ['auth-me'] });
      navigate('/dashboard', { replace: true });
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-page login-theme">
      <Card className="auth-card auth-card-elevated">
        <h1 className="auth-title">Garage setup</h1>
        <p className="muted">Complete your owner onboarding to unlock the staff portal.</p>

        <div className="stepper" style={{ marginTop: 16 }}>
          {['Welcome', 'Business', 'Bays', 'Finish'].map((label, index) => (
            <span key={label} className={`chip ${step === index ? 'active' : ''}`}>
              {index + 1}. {label}
            </span>
          ))}
        </div>

        {profileQuery.isLoading ? <p className="muted">Loading setup...</p> : null}
        {error ? <p className="error-text">{error}</p> : null}

        {step === 0 ? (
          <div className="stack" style={{ marginTop: 16 }}>
            <p>Set up your garage profile, service bays, and go live with GarageFlow.</p>
            <Button type="button" onClick={() => void syncSetup({ setup_step: 'details' }).then(() => setStep(1))}>
              Get started
            </Button>
          </div>
        ) : null}

        {step === 1 ? (
          <form className="form-grid auth-form" onSubmit={(event) => void saveBusinessDetails(event)}>
            <div>
              <FieldLabel>Business name</FieldLabel>
              <TextInput
                required
                value={profileForm.business_name}
                onChange={(event) => setProfileForm({ ...profileForm, business_name: event.target.value })}
              />
            </div>
            <div>
              <FieldLabel>Phone</FieldLabel>
              <TextInput value={profileForm.phone} onChange={(event) => setProfileForm({ ...profileForm, phone: event.target.value })} />
            </div>
            <div>
              <FieldLabel>Email</FieldLabel>
              <TextInput value={profileForm.email} onChange={(event) => setProfileForm({ ...profileForm, email: event.target.value })} />
            </div>
            <div>
              <FieldLabel>Address</FieldLabel>
              <TextInput value={profileForm.address} onChange={(event) => setProfileForm({ ...profileForm, address: event.target.value })} />
            </div>
            <div>
              <FieldLabel>GST number</FieldLabel>
              <TextInput
                value={profileForm.gst_number}
                onChange={(event) => setProfileForm({ ...profileForm, gst_number: event.target.value })}
              />
            </div>
            <Button type="submit" disabled={loading}>
              {loading ? 'Saving...' : 'Continue'}
            </Button>
          </form>
        ) : null}

        {step === 2 ? (
          <form className="stack auth-form" onSubmit={(event) => void saveBayCount(event)}>
            <div>
              <FieldLabel htmlFor="bay-count">Number of service bays</FieldLabel>
              <div className="inline-field-row">
                <TextInput
                  id="bay-count"
                  type="number"
                  min={1}
                  max={50}
                  inputMode="numeric"
                  value={bayCount}
                  onChange={(event) => setBayCount(event.target.value)}
                  required
                />
                <Button type="submit" disabled={loading}>
                  {loading ? 'Saving...' : 'Continue'}
                </Button>
              </div>
            </div>
          </form>
        ) : null}

        {step === 3 ? (
          <div className="stack auth-form">
            <p>Your garage is ready. Complete setup to enter the dashboard.</p>
            <Button type="button" onClick={() => void completeSetup()} disabled={loading}>
              {loading ? 'Finishing...' : 'Complete setup'}
            </Button>
          </div>
        ) : null}
      </Card>
    </div>
  );
}
