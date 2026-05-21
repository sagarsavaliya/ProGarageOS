<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\InventoryController;
use App\Http\Controllers\Api\InvoiceController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\InspectionTemplateController;
use App\Http\Controllers\Api\JobEstimateController;
use App\Http\Controllers\Api\JobTaskController;
use App\Http\Controllers\Api\PaymentMethodController;
use App\Http\Controllers\Api\ServiceBayController;
use App\Http\Controllers\Api\ServiceCategoryController;
use App\Http\Controllers\Api\VehicleDocumentController;
use App\Http\Controllers\Api\ServiceJobController;
use App\Http\Controllers\Api\StaffController;
use App\Http\Controllers\Api\VehicleController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Pro Garage OS API Routes
|--------------------------------------------------------------------------
| Base URL: /api
| Auth: Laravel Sanctum (Bearer token)
*/

// ── Health Check ──────────────────────────────────────────────────────────
Route::get('/health', fn () => response()->json([
    'status'    => 'ok',
    'timestamp' => now()->toIso8601String(),
    'version'   => config('app.version', '1.0.0'),
    'api'       => 'progarageos',
]));

// ── Authentication ─────────────────────────────────────────────────────────
Route::prefix('auth')->group(function () {
    Route::post('/staff/login', [AuthController::class, 'staffLogin'])
        ->middleware('throttle:10,15');

    Route::post('/customer/otp/request', [AuthController::class, 'customerOtpRequest'])
        ->middleware('throttle:5,10');

    Route::post('/customer/otp/verify', [AuthController::class, 'customerOtpVerify'])
        ->middleware('throttle:10,10');

    // Protected auth routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);
    });
});

// ── Staff Protected Routes ─────────────────────────────────────────────────
Route::middleware(['auth:sanctum', 'throttle:300,1'])->group(function () {

    // Dashboard
    Route::get('/dashboard/summary', [DashboardController::class, 'summary']);

    // Push notifications (staff inbox + device token)
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::patch('/notifications/read-all', [NotificationController::class, 'markAllRead']);
    Route::patch('/notifications/{uuid}/read', [NotificationController::class, 'markRead']);
    Route::post('/device-token', [NotificationController::class, 'registerDevice']);

    // Service Jobs
    Route::apiResource('jobs', ServiceJobController::class)->parameters(['jobs' => 'uuid']);
    Route::patch('/jobs/{uuid}/status', [ServiceJobController::class, 'updateStatus']);
    Route::get('/jobs/{uuid}/inspections', [ServiceJobController::class, 'showInspection']);
    Route::post('/jobs/{uuid}/inspections', [ServiceJobController::class, 'storeInspection']);
    Route::post('/jobs/{uuid}/inspections/photos', [ServiceJobController::class, 'uploadInspectionPhoto']);
    Route::get('/jobs/{uuid}/inspections/compare', [ServiceJobController::class, 'compareInspections']);
    Route::get('/jobs/{uuid}/inspections/pdf', [ServiceJobController::class, 'inspectionPdf']);
    Route::get('/jobs/{uuid}/estimate', [JobEstimateController::class, 'show']);
    Route::put('/jobs/{uuid}/estimate', [JobEstimateController::class, 'update']);
    Route::post('/jobs/{uuid}/estimate/send', [JobEstimateController::class, 'send']);
    Route::post('/jobs/{uuid}/estimate/approve', [JobEstimateController::class, 'approve']);
    Route::post('/jobs/{uuid}/estimate/reject', [JobEstimateController::class, 'reject']);
    Route::get('/jobs/{uuid}/tasks', [JobTaskController::class, 'index']);
    Route::post('/jobs/{uuid}/tasks', [JobTaskController::class, 'store']);
    Route::patch('/jobs/{uuid}/tasks/{taskId}', [JobTaskController::class, 'update']);
    Route::delete('/jobs/{uuid}/tasks/{taskId}', [JobTaskController::class, 'destroy']);

    Route::get('/service-categories', [ServiceCategoryController::class, 'index']);

    // Customers
    Route::apiResource('customers', CustomerController::class)->parameters(['customers' => 'uuid'])->except(['destroy']);
    Route::get('/customers/{uuid}/vehicles', [CustomerController::class, 'vehicles']);
    Route::get('/customers/{uuid}/service-history', [CustomerController::class, 'serviceHistory']);

    // Vehicles
    Route::apiResource('vehicles', VehicleController::class)->parameters(['vehicles' => 'uuid'])->except(['destroy']);
    Route::patch('/vehicles/{uuid}/odometer', [VehicleController::class, 'updateOdometer']);
    Route::get('/vehicles/{uuid}/documents', [VehicleDocumentController::class, 'index']);
    Route::post('/vehicles/{uuid}/documents', [VehicleDocumentController::class, 'store']);

    // Service Bays
    Route::get('/staff/technicians', [StaffController::class, 'technicians']);
    Route::get('/staff', [StaffController::class, 'index']);
    Route::post('/staff', [StaffController::class, 'store']);
    Route::get('/staff/{uuid}', [StaffController::class, 'show']);
    Route::patch('/staff/{uuid}', [StaffController::class, 'update']);

    Route::get('/inspection-templates', [InspectionTemplateController::class, 'index']);
    Route::get('/service-bays', [ServiceBayController::class, 'index']);
    Route::patch('/service-bays/{uuid}/status', [ServiceBayController::class, 'updateStatus']);

    // Invoices
    Route::apiResource('invoices', InvoiceController::class)->parameters(['invoices' => 'uuid'])->only(['index', 'show', 'store']);
    Route::post('/invoices/{uuid}/payments', [InvoiceController::class, 'recordPayment']);

    // Inventory
    Route::get('/inventory', [InventoryController::class, 'index']);
    Route::get('/inventory/{uuid}', [InventoryController::class, 'show']);
    Route::post('/inventory', [InventoryController::class, 'store']);
    Route::patch('/inventory/{uuid}/stock', [InventoryController::class, 'adjustStock']);

    // Payment methods
    Route::get('/payment-methods', [PaymentMethodController::class, 'index']);
});
