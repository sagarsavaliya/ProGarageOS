import { useEffect, useId, useState } from 'react';
import type { CatalogOption } from '@/lib/vehicle-catalog';

export function CatalogCombobox(props: {
  label: string;
  placeholder: string;
  value: string;
  disabled?: boolean;
  onValueChange: (value: string) => void;
  onOptionSelect: (option: CatalogOption | null) => void;
  onSearch: (query: string) => Promise<CatalogOption[]>;
}) {
  const listId = useId();
  const [options, setOptions] = useState<CatalogOption[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (props.disabled) {
      setOptions([]);
      return;
    }

    const handle = window.setTimeout(async () => {
      setLoading(true);
      try {
        const results = await props.onSearch(props.value.trim());
        setOptions(results);
      } catch {
        setOptions([]);
      } finally {
        setLoading(false);
      }
    }, 250);

    return () => window.clearTimeout(handle);
  }, [props.disabled, props.onSearch, props.value]);

  return (
    <div className="catalog-combobox">
      <label htmlFor={listId}>{props.label}</label>
      <input
        id={listId}
        list={`${listId}-options`}
        placeholder={props.placeholder}
        value={props.value}
        disabled={props.disabled}
        onChange={(event) => {
          props.onValueChange(event.target.value);
          props.onOptionSelect(null);
        }}
        onInput={(event) => {
          const value = (event.target as HTMLInputElement).value;
          const match = options.find((option) => option.name === value);
          if (match) props.onOptionSelect(match);
        }}
      />
      <datalist id={`${listId}-options`}>
        {options.map((option) => (
          <option key={option.uuid} value={option.name} />
        ))}
      </datalist>
      {loading ? <span className="catalog-combobox__hint">Searching…</span> : null}
    </div>
  );
}
