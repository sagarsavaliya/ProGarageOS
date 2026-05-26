import { Button } from '@/components/ui/Button';

export function ListPager(props: {
  page: number;
  lastPage: number;
  total?: number;
  onPrevious: () => void;
  onNext: () => void;
}) {
  if (props.lastPage <= 1 && props.total !== undefined && props.total <= 0) {
    return null;
  }

  return (
    <div className="pager">
      <span className="pager-meta">
        Page <strong>{props.page}</strong> of <strong>{props.lastPage}</strong>
        {props.total !== undefined ? (
          <>
            {' '}
            · <strong>{props.total}</strong> total
          </>
        ) : null}
      </span>
      <div className="toolbar-actions">
        <Button type="button" variant="outline" disabled={props.page <= 1} onClick={props.onPrevious}>
          Previous
        </Button>
        <Button type="button" variant="outline" disabled={props.page >= props.lastPage} onClick={props.onNext}>
          Next
        </Button>
      </div>
    </div>
  );
}
