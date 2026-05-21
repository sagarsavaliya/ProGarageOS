<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\InventoryItem;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InventoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $query    = InventoryItem::where('tenant_id', $tenantId)
            ->with('category:id,name', 'preferredVendor:id,name');

        if ($search = $request->query('search')) {
            $query->where(fn ($q) => $q->where('name', 'like', "%{$search}%")->orWhere('sku', 'like', "%{$search}%")->orWhere('brand', 'like', "%{$search}%"));
        }

        if ($request->boolean('low_stock')) {
            $query->whereRaw('stock_on_hand <= low_stock_threshold');
        }

        $items = $query->orderBy('name')->paginate($request->query('per_page', 25));

        return response()->json([
            'success' => true,
            'data'    => $items->map(fn ($item) => [
                'uuid'              => $item->uuid,
                'sku'               => $item->sku,
                'name'              => $item->name,
                'brand'             => $item->brand,
                'category'          => $item->category?->name,
                'selling_price'     => (float) $item->selling_price,
                'cost_price'        => (float) $item->cost_price,
                'stock_on_hand'     => $item->stock_on_hand,
                'unit'              => $item->unit_of_measure,
                'is_low_stock'      => $item->isLowStock(),
                'low_stock_threshold' => $item->low_stock_threshold,
            ]),
            'meta' => [
                'current_page' => $items->currentPage(),
                'per_page'     => $items->perPage(),
                'total'        => $items->total(),
                'last_page'    => $items->lastPage(),
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $data = $request->validate([
            'sku'                 => ['required', 'string', 'max:100'],
            'name'                => ['required', 'string'],
            'brand'               => ['nullable', 'string', 'max:100'],
            'unit_of_measure'     => ['in:piece,litre,ml,kg,gram,set,pair,box,meter'],
            'cost_price'          => ['numeric', 'min:0'],
            'selling_price'       => ['numeric', 'min:0'],
            'stock_on_hand'       => ['integer'],
            'low_stock_threshold' => ['integer', 'min:0'],
            'reorder_quantity'    => ['integer', 'min:1'],
        ]);

        $item = InventoryItem::create(array_merge($data, ['tenant_id' => $tenantId]));
        return response()->json(['success' => true, 'data' => ['uuid' => $item->uuid, 'name' => $item->name, 'sku' => $item->sku]], 201);
    }

    public function adjustStock(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $item     = InventoryItem::where('uuid', $uuid)->where('tenant_id', $tenantId)->firstOrFail();
        $data     = $request->validate([
            'adjustment' => ['required', 'integer'],
            'reason'     => ['nullable', 'string'],
        ]);

        $item->increment('stock_on_hand', $data['adjustment']);
        return response()->json(['success' => true, 'data' => ['stock_on_hand' => $item->fresh()->stock_on_hand]]);
    }

    public function show(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $item     = InventoryItem::where('uuid', $uuid)
            ->where('tenant_id', $tenantId)
            ->with('category:id,name')
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'data'    => $this->formatInventoryDetail($item),
        ]);
    }

    private function formatInventoryDetail(InventoryItem $item): array
    {
        $maxStock = max($item->reorder_quantity * 5, $item->low_stock_threshold * 10, 100);

        return [
            'uuid'                => $item->uuid,
            'sku'                 => $item->sku,
            'name'                => $item->name,
            'brand'               => $item->brand,
            'category'            => $item->category
                ? ['id' => $item->category->id, 'name' => $item->category->name]
                : ['id' => 0, 'name' => ''],
            'unit'                => $item->unit_of_measure,
            'unit_of_measure'     => $item->unit_of_measure,
            'selling_price'       => (float) $item->selling_price,
            'cost_price'          => (float) $item->cost_price,
            'stock_quantity'      => $item->stock_on_hand,
            'stock_on_hand'       => $item->stock_on_hand,
            'minimum_stock_level' => $item->low_stock_threshold,
            'low_stock_threshold' => $item->low_stock_threshold,
            'maximum_stock_level' => $maxStock,
            'is_active'           => $item->is_active,
            'notes'               => $item->description,
            'recent_adjustments'  => [],
        ];
    }
}
