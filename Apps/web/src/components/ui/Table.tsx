import type { ReactNode } from 'react';

export function Table(props: { children: ReactNode; className?: string }) {
  return (
    <div className="table-shell">
      <table className={`gf-table ${props.className ?? ''}`.trim()}>{props.children}</table>
    </div>
  );
}

export function THead(props: { children: ReactNode }) {
  return <thead className="gf-table-head">{props.children}</thead>;
}

export function TRow(props: { children: ReactNode }) {
  return <tr>{props.children}</tr>;
}

export function TH(props: { children: ReactNode }) {
  return <th>{props.children}</th>;
}

export function TD(props: { children: ReactNode }) {
  return <td>{props.children}</td>;
}
