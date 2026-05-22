<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Vehicle;
use App\Models\VehicleDocument;
use App\Services\InspectionMediaService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VehicleDocumentController extends Controller
{
    public function __construct(
        private readonly InspectionMediaService $media,
    ) {}

    public function index(Request $request, string $vehicleUuid): JsonResponse
    {
        $vehicle = Vehicle::where('uuid', $vehicleUuid)->firstOrFail();
        $tenantId = $request->user()->tenant_id;

        $docs = VehicleDocument::where('vehicle_id', $vehicle->id)
            ->where('tenant_id', $tenantId)
            ->where('is_active', true)
            ->orderBy('document_type')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $docs->map(fn (VehicleDocument $d) => $this->formatDocument($d, $request)),
        ]);
    }

    public function store(Request $request, string $vehicleUuid): JsonResponse
    {
        $vehicle  = Vehicle::where('uuid', $vehicleUuid)->firstOrFail();
        $tenantId = $request->user()->tenant_id;

        $data = $request->validate([
            'document_type'     => ['required', 'in:rc,insurance,puc,fitness,permit,other'],
            'document_number'   => ['nullable', 'string', 'max:100'],
            'issuing_authority' => ['nullable', 'string', 'max:150'],
            'issue_date'        => ['nullable', 'date'],
            'expiry_date'       => ['nullable', 'date', 'after_or_equal:issue_date'],
            'file'              => ['nullable', 'file', 'max:10240', 'mimes:jpg,jpeg,png,pdf'],
        ]);

        $fileUrl = null;
        if ($request->hasFile('file')) {
            $fileUrl = $this->media->storeVehicleDocument(
                $request->file('file'),
                $tenantId,
                $vehicle->uuid,
                $data['document_type'],
            );
        }

        $doc = VehicleDocument::create([
            'vehicle_id'        => $vehicle->id,
            'tenant_id'         => $tenantId,
            'document_type'     => $data['document_type'],
            'document_number'   => $data['document_number'] ?? null,
            'issuing_authority' => $data['issuing_authority'] ?? null,
            'issue_date'        => $data['issue_date'] ?? null,
            'expiry_date'       => $data['expiry_date'] ?? null,
            'file_url'          => $fileUrl,
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->formatDocument($doc, $request),
        ], 201);
    }

    public function destroy(Request $request, string $vehicleUuid, string $docUuid): JsonResponse
    {
        $vehicle  = Vehicle::where('uuid', $vehicleUuid)->firstOrFail();
        $tenantId = $request->user()->tenant_id;

        $doc = VehicleDocument::where('uuid', $docUuid)
            ->where('vehicle_id', $vehicle->id)
            ->where('tenant_id', $tenantId)
            ->where('is_active', true)
            ->firstOrFail();

        $doc->update(['is_active' => false]);

        return response()->json([
            'success' => true,
            'message' => 'Document removed',
        ]);
    }

    private function formatDocument(VehicleDocument $doc, Request $request): array
    {
        $url = $doc->file_url;
        if ($url && ! str_starts_with($url, 'http')) {
            $url = url($url);
        }

        return [
            'uuid'            => $doc->uuid,
            'document_type'   => $doc->document_type,
            'document_number' => $doc->document_number,
            'expiry_date'     => $doc->expiry_date?->format('Y-m-d'),
            'issue_date'      => $doc->issue_date?->format('Y-m-d'),
            'file_url'        => $url,
            'is_expired'      => $doc->isExpired(),
            'is_expiring_soon'=> $doc->isExpiringSoon(),
            'is_verified'     => $doc->is_verified,
        ];
    }
}
