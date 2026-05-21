<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Inspection — {{ $job->job_number }}</title>
    <style>
        body { font-family: DejaVu Sans, sans-serif; font-size: 12px; color: #222; }
        h1 { font-size: 18px; margin-bottom: 4px; }
        .meta { color: #666; margin-bottom: 16px; }
        table { width: 100%; border-collapse: collapse; margin-top: 12px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background: #f5f5f5; }
    </style>
</head>
<body>
    <h1>{{ ucfirst($phase) }} inspection — {{ $job->job_number }}</h1>
    <p class="meta">
        Customer: {{ $job->customer?->full_name }} ·
        Vehicle: {{ $job->vehicle?->registration_number }} ·
        {{ now()->format('d M Y H:i') }}
    </p>
    <table>
        <thead>
            <tr>
                <th>Component</th>
                <th>Condition</th>
                <th>Severity</th>
            </tr>
        </thead>
        <tbody>
            @foreach($records as $row)
                @if(str_starts_with((string) $row->category, 'item:'))
                    <tr>
                        <td>{{ $row->component_name }}</td>
                        <td>{{ $row->condition_status }}</td>
                        <td>{{ $row->severity }}</td>
                    </tr>
                @endif
            @endforeach
        </tbody>
    </table>
</body>
</html>
