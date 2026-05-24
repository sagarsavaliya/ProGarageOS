import type { ButtonHTMLAttributes, ReactNode } from 'react';

type ButtonVariant = 'primary' | 'outline' | 'ghost';

type ButtonProps = {
  children: ReactNode;
  variant?: ButtonVariant;
} & ButtonHTMLAttributes<HTMLButtonElement>;

export function Button({ children, variant = 'primary', className = '', ...rest }: ButtonProps) {
  return (
    <button {...rest} className={`gf-btn gf-btn-${variant} ${className}`.trim()}>
      {children}
    </button>
  );
}
