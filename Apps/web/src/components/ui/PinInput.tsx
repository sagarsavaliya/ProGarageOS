import { useMemo } from 'react';

export function PinInput(props: {
  value: string;
  onChange: (value: string) => void;
  onComplete?: (value: string) => void;
  length?: number;
  idPrefix?: string;
}) {
  const length = props.length ?? 6;
  const idPrefix = props.idPrefix ?? 'pin';
  const boxes = useMemo(() => Array.from({ length }, (_, i) => props.value[i] ?? ''), [length, props.value]);

  function applyValue(raw: string) {
    const next = raw.replace(/\D/g, '').slice(0, length);
    props.onChange(next);
    if (next.length === length) {
      props.onComplete?.(next);
    }
  }

  return (
    <div className="pin-grid">
      {boxes.map((digit, idx) => (
        <input
          key={idx}
          id={`${idPrefix}-${idx}`}
          className="pin-box"
          inputMode="numeric"
          autoComplete={idx === 0 ? 'one-time-code' : 'off'}
          maxLength={1}
          value={digit}
          onChange={(event) => {
            const next = event.target.value.replace(/\D/g, '').slice(-1);
            const list = boxes.slice();
            list[idx] = next;
            applyValue(list.join(''));
            if (next && idx + 1 < length) {
              const element = document.querySelector<HTMLInputElement>(`#${idPrefix}-${idx + 1}`);
              element?.focus();
            }
          }}
          onPaste={(event) => {
            if (idx !== 0) {
              return;
            }
            const pasted = event.clipboardData.getData('text');
            if (!pasted) {
              return;
            }
            event.preventDefault();
            const next = pasted.replace(/\D/g, '').slice(0, length);
            applyValue(next);
            const focusIdx = Math.max(0, next.length - 1);
            const element = document.querySelector<HTMLInputElement>(`#${idPrefix}-${focusIdx}`);
            element?.focus();
          }}
          onKeyDown={(event) => {
            if (event.key === 'Backspace' && !digit && idx > 0) {
              const element = document.querySelector<HTMLInputElement>(`#${idPrefix}-${idx - 1}`);
              element?.focus();
            }
          }}
        />
      ))}
    </div>
  );
}
