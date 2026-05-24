import type { InputHTMLAttributes, SelectHTMLAttributes, TextareaHTMLAttributes } from 'react';

export function FieldLabel(props: { htmlFor?: string; children: React.ReactNode }) {
  return (
    <label htmlFor={props.htmlFor} className="field-label">
      {props.children}
    </label>
  );
}

export function TextInput(props: InputHTMLAttributes<HTMLInputElement>) {
  return <input {...props} className={`field-input ${props.className ?? ''}`} />;
}

export function SelectInput(props: SelectHTMLAttributes<HTMLSelectElement>) {
  return <select {...props} className={`field-input ${props.className ?? ''}`} />;
}

export function TextArea(props: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return <textarea {...props} className={`field-input field-textarea ${props.className ?? ''}`} />;
}
