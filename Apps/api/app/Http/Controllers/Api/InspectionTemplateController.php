<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\InspectionTemplate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;

class InspectionTemplateController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $phase    = $request->query('phase', 'intake');

        $templates = InspectionTemplate::where('tenant_id', $tenantId)
            ->where('component_category', $phase)
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        if ($templates->isEmpty()) {
            $templates = $this->seedDefaultTemplates($tenantId, $phase);
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'phase' => $phase,
                'items' => $templates->map(fn (InspectionTemplate $t) => [
                    'uuid'           => $t->uuid,
                    'component_key'  => $t->code,
                    'component_name' => $t->component_name,
                    'category'       => $t->name,
                    'is_mandatory'   => $t->is_mandatory,
                    'requires_photo' => $t->requires_photo,
                ]),
            ],
        ]);
    }

    private function seedDefaultTemplates(int $tenantId, string $phase): Collection
    {
        $items = $phase === 'delivery' ? $this->deliveryChecklist() : $this->intakeChecklist();

        $created = collect();
        foreach ($items as $i => $item) {
            $created->push(InspectionTemplate::create([
                'tenant_id'          => $tenantId,
                'name'               => $item['group'],
                'code'               => $item['key'],
                'component_name'     => $item['name'],
                'component_category' => $phase,
                'is_mandatory'       => true,
                'requires_photo'     => false,
                'sort_order'         => $i,
                'is_active'          => true,
            ]));
        }

        return $created;
    }

    private function intakeChecklist(): array
    {
        return [
            ['key' => 'body', 'group' => 'Exterior', 'name' => 'Body & Paint'],
            ['key' => 'windshield-front', 'group' => 'Exterior', 'name' => 'Front windshield'],
            ['key' => 'windshield-rear', 'group' => 'Exterior', 'name' => 'Rear windshield'],
            ['key' => 'side-mirrors', 'group' => 'Exterior', 'name' => 'Side mirrors'],
            ['key' => 'lights', 'group' => 'Exterior', 'name' => 'Headlights & tail lights'],
            ['key' => 'dashboard', 'group' => 'Interior', 'name' => 'Dashboard & console'],
            ['key' => 'steering', 'group' => 'Interior', 'name' => 'Steering wheel'],
            ['key' => 'seats', 'group' => 'Interior', 'name' => 'Seats & upholstery'],
            ['key' => 'ac', 'group' => 'Interior', 'name' => 'AC & ventilation'],
            ['key' => 'engine-oil', 'group' => 'Under Hood', 'name' => 'Engine oil level'],
            ['key' => 'coolant', 'group' => 'Under Hood', 'name' => 'Coolant level'],
            ['key' => 'battery', 'group' => 'Under Hood', 'name' => 'Battery condition'],
            ['key' => 'tyres', 'group' => 'Wheels', 'name' => 'Tyre tread & pressure'],
            ['key' => 'spare', 'group' => 'Wheels', 'name' => 'Spare wheel'],
            ['key' => 'tools', 'group' => 'Accessories', 'name' => 'Tool kit & jack'],
            ['key' => 'documents', 'group' => 'Accessories', 'name' => 'RC & insurance copy'],
        ];
    }

    private function deliveryChecklist(): array
    {
        return [
            ['key' => 'body', 'group' => 'Exterior', 'name' => 'Body & Paint'],
            ['key' => 'windshield-front', 'group' => 'Exterior', 'name' => 'Front windshield'],
            ['key' => 'lights', 'group' => 'Exterior', 'name' => 'Lights'],
            ['key' => 'interior-clean', 'group' => 'Interior', 'name' => 'Interior cleanliness'],
            ['key' => 'work-completed', 'group' => 'Service', 'name' => 'All requested work completed'],
            ['key' => 'parts-returned', 'group' => 'Service', 'name' => 'Old parts returned to customer'],
            ['key' => 'documents', 'group' => 'Accessories', 'name' => 'Documents & keys returned'],
        ];
    }
}
