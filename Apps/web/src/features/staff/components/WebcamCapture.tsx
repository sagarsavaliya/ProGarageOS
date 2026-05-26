import { useCallback, useEffect, useRef, useState } from 'react';
import { Button } from '@/components/ui';

type WebcamCaptureProps = {
  onCapture: (file: File) => void;
  disabled?: boolean;
};

export function WebcamCapture(props: WebcamCaptureProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [error, setError] = useState<string>();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function startCamera() {
      if (!navigator.mediaDevices?.getUserMedia) {
        setError('Camera not supported in this browser.');
        return;
      }

      try {
        const stream = await navigator.mediaDevices.getUserMedia({ video: true });
        if (cancelled) {
          stream.getTracks().forEach((track) => track.stop());
          return;
        }
        streamRef.current = stream;
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
          await videoRef.current.play();
        }
        setReady(true);
      } catch {
        setError('Camera access denied or unavailable.');
      }
    }

    void startCamera();

    return () => {
      cancelled = true;
      streamRef.current?.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
    };
  }, []);

  const capture = useCallback(() => {
    const video = videoRef.current;
    if (!video) {
      return;
    }

    const canvas = document.createElement('canvas');
    canvas.width = video.videoWidth || 640;
    canvas.height = video.videoHeight || 480;
    const ctx = canvas.getContext('2d');
    if (!ctx) {
      return;
    }

    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    canvas.toBlob(
      (blob) => {
        if (!blob) {
          return;
        }
        const url = URL.createObjectURL(blob);
        setPreviewUrl(url);
        props.onCapture(new File([blob], `capture-${Date.now()}.jpg`, { type: 'image/jpeg' }));
      },
      'image/jpeg',
      0.92,
    );
  }, [props]);

  const retake = () => {
    if (previewUrl) {
      URL.revokeObjectURL(previewUrl);
    }
    setPreviewUrl(null);
  };

  return (
    <div className="webcam-box">
      {error ? <p className="error-text">{error}</p> : null}
      {previewUrl ? (
        <img src={previewUrl} alt="Captured preview" className="media-preview" />
      ) : (
        <video ref={videoRef} autoPlay muted playsInline className="media-preview" />
      )}
      <div className="toolbar mt-3">
        {previewUrl ? (
          <Button type="button" variant="outline" onClick={retake} disabled={props.disabled}>
            Retake
          </Button>
        ) : (
          <Button type="button" onClick={capture} disabled={props.disabled || !ready}>
            Capture
          </Button>
        )}
      </div>
    </div>
  );
}
