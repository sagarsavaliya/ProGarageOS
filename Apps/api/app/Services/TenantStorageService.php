<?php

namespace App\Services;

use Illuminate\Support\Facades\Storage;

class TenantStorageService
{
    public function disk(): string
    {
        $bucket = config('filesystems.disks.s3.bucket');
        $key    = config('filesystems.disks.s3.key');

        return ($bucket && $key) ? 's3' : 'public';
    }

    public function publicUrl(string $path): string
    {
        $url = Storage::disk($this->disk())->url($path);

        return str_starts_with($url, 'http') ? $url : url($url);
    }

    public function exists(string $path): bool
    {
        return Storage::disk($this->disk())->exists($path);
    }

    public function put(string $path, string $contents): bool
    {
        return Storage::disk($this->disk())->put($path, $contents);
    }

    public function delete(string $path): void
    {
        if ($path !== '') {
            Storage::disk($this->disk())->delete($path);
        }
    }

    public function inspectionPhotoDir(int $tenantId, string $phase, string $jobUuid): string
    {
        return "tenants/{$tenantId}/inspection/{$phase}/{$jobUuid}";
    }

    public function inspectionSummaryPath(int $tenantId, string $phase, string $jobUuid): string
    {
        return "tenants/{$tenantId}/inspection/{$phase}/{$jobUuid}/summary.html";
    }

    public function vehicleDocumentDir(int $tenantId, string $vehicleUuid): string
    {
        return "tenants/{$tenantId}/docs/{$vehicleUuid}";
    }

    public function invoicePath(int $tenantId, string $invoiceUuid): string
    {
        return "tenants/{$tenantId}/invoices/{$invoiceUuid}.html";
    }

    public function signatureDir(int $tenantId, string $jobUuid): string
    {
        return "tenants/{$tenantId}/signatures/{$jobUuid}";
    }

    public function avatarDir(int $tenantId): string
    {
        return "tenants/{$tenantId}/avatars";
    }
}
