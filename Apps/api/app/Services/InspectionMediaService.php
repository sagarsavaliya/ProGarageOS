<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class InspectionMediaService
{
    public function __construct(
        private readonly TenantStorageService $storage,
    ) {}

    public function disk(): string
    {
        return $this->storage->disk();
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
        string $phase = 'intake',
    ): array {
        $ext      = $file->guessExtension() ?: 'jpg';
        $filename = sprintf('%s_%s.%s', $slot, Str::uuid(), $ext);
        $dir      = $this->storage->inspectionPhotoDir($tenantId, $phase, $jobUuid);
        $path     = $file->storeAs($dir, $filename, $this->disk());

        return [
            'path' => $path,
            'url'  => $this->storage->publicUrl($path),
        ];
    }

    public function deletePhoto(string $path): void
    {
        $this->storage->delete($path);
    }

    public function storeVehicleDocument(
        UploadedFile $file,
        int $tenantId,
        string $vehicleUuid,
        string $documentType,
    ): string {
        $ext      = $file->guessExtension() ?: 'jpg';
        $filename = sprintf('%s_%s.%s', $documentType, Str::uuid(), $ext);
        $dir      = $this->storage->vehicleDocumentDir($tenantId, $vehicleUuid);
        $path     = $file->storeAs($dir, $filename, $this->disk());

        return $this->storage->publicUrl($path);
    }

    public function storeSignatureImage(
        string $base64OrRaw,
        int $tenantId,
        string $jobUuid,
        string $phase,
    ): string {
        $binary = $base64OrRaw;
        if (str_contains($base64OrRaw, 'base64,')) {
            $binary = base64_decode(substr($base64OrRaw, strpos($base64OrRaw, ',') + 1)) ?: '';
        }

        $filename = sprintf('%s_%s.png', $phase, Str::uuid());
        $path     = $this->storage->signatureDir($tenantId, $jobUuid) . '/' . $filename;
        Storage::disk($this->disk())->put($path, $binary, 'public');

        return $this->storage->publicUrl($path);
    }
}
