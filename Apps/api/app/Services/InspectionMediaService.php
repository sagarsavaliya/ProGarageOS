<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class InspectionMediaService
{
    public function disk(): string
    {
        return config('filesystems.disks.s3.bucket') ? 's3' : 'public';
    }

    /**
     * Store an inspection photo and return public URL + storage path.
     *
     * @return array{path: string, url: string}
     */
    public function storePhoto(
        int $tenantId,
        string $jobUuid,
        UploadedFile $file,
        string $slot,
    ): array {
        $ext      = $file->guessExtension() ?: 'jpg';
        $filename = sprintf('%s_%s.%s', $slot, Str::uuid(), $ext);
        $dir      = "inspections/{$tenantId}/{$jobUuid}";
        $path     = $file->storeAs($dir, $filename, $this->disk());

        return [
            'path' => $path,
            'url'  => Storage::disk($this->disk())->url($path),
        ];
    }

    public function deletePhoto(string $path): void
    {
        if ($path !== '') {
            Storage::disk($this->disk())->delete($path);
        }
    }

    public function storeVehicleDocument(
        UploadedFile $file,
        int $tenantId,
        string $vehicleUuid,
        string $documentType,
    ): string {
        $ext      = $file->guessExtension() ?: 'jpg';
        $filename = sprintf('%s_%s.%s', $documentType, Str::uuid(), $ext);
        $dir      = "vehicle-documents/{$tenantId}/{$vehicleUuid}";
        $path     = $file->storeAs($dir, $filename, $this->disk());

        return Storage::disk($this->disk())->url($path);
    }
}
