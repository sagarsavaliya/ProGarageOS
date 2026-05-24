import { useMemo } from 'react';

export function PinInput(props: {
  value: string;
  onChange: (value: string) => void;
  length?: number;
  idPrefix?: string;
}) {
  const length = props.length ?? 6;
  const idPrefix = props.idPrefix ?? 'pin';
  const boxes = useMemo(() => Array.from({ length }, (_, i) => props.value[i] ?? ''), [length, props.value]);

  return (
    <div className="pin-grid">
      {boxes.map((digit, idx) => (
        <input
          key={idx}
          id={`${idPrefix}-${idx}`}
          className="pin-box"
          inputMode="numeric"
          maxLength={1}
          value={digit}
          onChange={(event) => {
            const next = event.target.value.replace(/\D/g, '').slice(-1);
            const list = boxes.slice();
            list[idx] = next;
            props.onChange(list.join(''));
            if (next && idx + 1 < length) {
              const element = document.querySelector<HTMLInputElement>(`#${idPrefix}-${idx + 1}`);
              element?.focus();
            }
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
