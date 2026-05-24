import type { JsonMap } from '@/lib/api';

export function money(value: unknown): string {
  const num = Number(value ?? 0);
  return `₹${Number.isFinite(num) ? num.toLocaleString('en-IN') : '0'}`;
}

export function customerName(record: JsonMap): string {
  if (typeof record.name === 'string' && record.name) {
    return record.name;
  }
  const first = String(record.first_name ?? '');
  const last = String(record.last_name ?? '');
  return `${first} ${last}`.trim() || '-';
}

export function vehicleLabel(record: JsonMap): string {
  if (typeof record.display === 'string' && record.display) {
    return record.display;
  }
  const maker = String(record.maker ?? '');
  const model = String(record.model ?? '');
  const reg = String(record.registration_number ?? '');
  const label = `${maker} ${model}`.trim();
  return reg ? `${label} · ${reg}` : label || '-';
}

export function initials(name: string): string {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? '')
    .join('');
}
