export function LoadingState(props: { label?: string }) {
  return (
    <div className="loading-state" role="status" aria-live="polite">
      <span className="loading-spinner" aria-hidden />
      <span>{props.label ?? 'Loading...'}</span>
    </div>
  );
}
