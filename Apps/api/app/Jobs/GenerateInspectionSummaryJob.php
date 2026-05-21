<?php

namespace App\Jobs;

use App\Models\JobInspectionRecord;
use App\Models\ServiceJob;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Storage;

class GenerateInspectionSummaryJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public int $jobId,
        public string $phase,
    ) {}

    public function handle(): void
    {
        $job = ServiceJob::with('customer', 'vehicle')->find($this->jobId);
        if (! $job) {
            return;
        }

        $records = JobInspectionRecord::where('job_id', $job->id)
            ->where('inspection_phase', $this->phase)
            ->orderBy('id')
            ->get();

        $html = view('pdf.inspection-summary', [
            'job'     => $job,
            'phase'   => $this->phase,
            'records' => $records,
        ])->render();

        $path = "inspections/{$job->tenant_id}/{$job->uuid}-{$this->phase}.html";
        Storage::disk('public')->put($path, $html);
    }
}
