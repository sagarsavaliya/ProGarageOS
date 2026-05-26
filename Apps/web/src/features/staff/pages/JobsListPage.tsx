import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Button, Card, StatusBadge, Table, THead, TRow, TH, TD, EmptyState, LoadingState, ListPager, Alert } from '@/components/ui';
import { FieldLabel, SelectInput, TextInput } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { usePaginatedList } from '@/lib/hooks';
import { customerName, vehicleLabel } from '@/lib/format';
import type { JsonMap } from '@/lib/api';

const STATUS_OPTIONS = [
  { value: '', label: 'All statuses' },
  { value: 'intake_inspection', label: 'Intake inspection' },
  { value: 'estimate_pending', label: 'Estimate pending' },
  { value: 'in_progress', label: 'In progress' },
  { value: 'ready_for_delivery', label: 'Ready for delivery' },
  { value: 'delivered', label: 'Delivered' },
];

export function JobsListPage() {
  const token = useStaffToken();
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [searchInput, setSearchInput] = useState('');

  const listQuery = usePaginatedList('/jobs', token, {
    page,
    per_page: 25,
    ...(search ? { search } : {}),
    ...(status ? { status } : {}),
  });

  const items = listQuery.data?.items ?? [];
  const meta = listQuery.data?.meta ?? {};
  const lastPage = Number(meta.last_page ?? 1);
  const total = Number(meta.total ?? items.length);

  return (
    <StaffPage title="Jobs" subtitle="Search, filter, and manage service jobs">
      <div className="toolbar">
        <form
          className="toolbar-form toolbar-form--filters"
          onSubmit={(event) => {
            event.preventDefault();
            setSearch(searchInput.trim());
            setPage(1);
          }}
        >
          <div>
            <FieldLabel htmlFor="job-search">Search</FieldLabel>
            <TextInput
              id="job-search"
              placeholder="Job number, customer, vehicle..."
              value={searchInput}
              onChange={(event) => setSearchInput(event.target.value)}
            />
          </div>
          <div>
            <FieldLabel htmlFor="job-status">Status</FieldLabel>
            <SelectInput
              id="job-status"
              value={status}
              onChange={(event) => {
                setStatus(event.target.value);
                setPage(1);
              }}
            >
              {STATUS_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </SelectInput>
          </div>
          <div>
            <Button type="submit">Search</Button>
          </div>
        </form>
        <Link to="/jobs/new">
          <Button type="button">New job</Button>
        </Link>
      </div>

      <Card>
        {listQuery.isLoading ? <LoadingState label="Loading jobs..." /> : null}
        {listQuery.isError ? <Alert variant="error">Could not load jobs.</Alert> : null}
        {!listQuery.isLoading && !listQuery.isError && items.length === 0 ? (
          <EmptyState title="No jobs found" description="Try a different search or create a new service job." />
        ) : null}

        {items.length > 0 ? (
          <Table>
            <THead>
              <TRow>
                <TH>Job</TH>
                <TH>Customer</TH>
                <TH>Vehicle</TH>
                <TH>Status</TH>
                <TH>Priority</TH>
              </TRow>
            </THead>
            <tbody>
              {items.map((job: JsonMap) => (
                <TRow key={String(job.uuid)}>
                  <TD>
                    <Link to={`/jobs/${String(job.uuid)}`}>{String(job.job_number ?? job.uuid)}</Link>
                  </TD>
                  <TD>{String(job.customer_name ?? customerName(job))}</TD>
                  <TD>{vehicleLabel((job.vehicle as JsonMap) ?? job)}</TD>
                  <TD>
                    <StatusBadge status={String(job.status ?? 'draft')} />
                  </TD>
                  <TD>{String(job.priority ?? 'normal')}</TD>
                </TRow>
              ))}
            </tbody>
          </Table>
        ) : null}

        <ListPager
          page={page}
          lastPage={lastPage}
          total={total}
          onPrevious={() => setPage((p) => p - 1)}
          onNext={() => setPage((p) => p + 1)}
        />
      </Card>
    </StaffPage>
  );
}
