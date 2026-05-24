<?php

namespace App\Http\Controllers\Api\Platform;

use App\Http\Controllers\Controller;
use App\Models\Tenant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PlatformStorageController extends Controller
{
    public function disks(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => [
                'default_disk' => config('filesystems.default'),
                'disks'        => ['local', 'public', 's3'],
            ],
        ]);
    }

    public function index(Request $request): JsonResponse
    {
        $disk = $request->query('disk', config('filesystems.default'));
        $prefix = $request->query('prefix', '');
        $tenantUuid = $request->query('tenant_uuid');

        if ($tenantUuid) {
            $tenant = Tenant::where('uuid', $tenantUuid)->firstOrFail();
            $prefix = trim("tenants/{$tenant->id}/{$prefix}", '/');
        }

        if (!in_array($disk, ['local', 'public', 's3'], true)) {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'INVALID_DISK', 'message' => 'Unsupported disk.'],
            ], 422);
        }

        $files = [];
        $directories = [];

        try {
            $all = Storage::disk($disk)->allFiles($prefix);
            foreach (array_slice($all, 0, 500) as $path) {
                $files[] = [
                    'path' => $path,
                    'size' => Storage::disk($disk)->size($path),
                    'last_modified' => Storage::disk($disk)->lastModified($path),
                    'url'  => $this->urlFor($disk, $path),
                ];
            }
            $directories = array_slice(Storage::disk($disk)->allDirectories($prefix), 0, 100);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'STORAGE_ERROR', 'message' => $e->getMessage()],
            ], 500);
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'disk'          => $disk,
                'prefix'        => $prefix,
                'files'         => $files,
                'directories'   => $directories,
                'total_files'   => count($files),
            ],
        ]);
    }

    public function destroy(Request $request): JsonResponse
    {
        $data = $request->validate([
            'disk' => ['required', 'in:local,public,s3'],
            'path' => ['required', 'string', 'max:500'],
        ]);

        if (!Storage::disk($data['disk'])->exists($data['path'])) {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'NOT_FOUND', 'message' => 'File not found.'],
            ], 404);
        }

        Storage::disk($data['disk'])->delete($data['path']);

        return response()->json(['success' => true, 'message' => 'File deleted.']);
    }

    private function urlFor(string $disk, string $path): ?string
    {
        try {
            return Storage::disk($disk)->url($path);
        } catch (\Throwable) {
            return null;
        }
    }
}
