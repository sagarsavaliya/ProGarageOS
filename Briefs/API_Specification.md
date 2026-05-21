# 🚗 GarageFlow SaaS — API Specification
> **Version**: 1.0.0 | **Base URL**: `https://api.garageflow.in/v1`  
> **Auth**: Laravel Sanctum (Staff: Bearer Token + PIN; Customer: Bearer Token + OTP)  
> **Format**: JSON | **Timezone**: Per tenant (`Asia/Kolkata` default) | **Currency**: Per tenant (`INR` default)  
> **Multi-Tenancy**: All tenant-scoped endpoints resolve `tenant_id` from authenticated token context. Never pass `tenant_id` as a query param from the client.

---

## 📋 Table of Contents

1. [Global Conventions](#global-conventions)
2. [Authentication APIs](#1-authentication-apis)
3. [Tenant & Subscription APIs](#2-tenant--subscription-apis)
4. [User & Access Management APIs](#3-user--access-management-apis)
5. [Customer APIs](#4-customer-apis)
6. [Vehicle APIs](#5-vehicle-apis)
7. [Service Operations APIs](#6-service-operations-apis)
8. [Job Management APIs](#7-job-management-apis)
9. [Inspection APIs](#8-inspection-apis)
10. [Inventory & Supply Chain APIs](#9-inventory--supply-chain-apis)
11. [Billing & Payment APIs](#10-billing--payment-apis)
12. [Scheduling & Appointment APIs](#11-scheduling--appointment-apis)
13. [Notification APIs](#12-notification-apis)
14. [Loyalty & Retention APIs](#13-loyalty--retention-apis)
15. [Feedback & Review APIs](#14-feedback--review-apis)
16. [Customer Mobile App APIs](#15-customer-mobile-app-apis)
17. [Audit & System APIs](#16-audit--system-apis)
18. [WebSocket Events Reference](#17-websocket-events-reference)
19. [Error Reference](#18-error-reference)

---

## Global Conventions

### Request Headers
```http
Authorization: Bearer {sanctum_token}
Accept: application/json
Content-Type: application/json
X-App-Version: 1.0.0
X-Platform: web | ios | android
```

### Standard Pagination (All list endpoints)
```
GET /resource?page=1&per_page=25&sort=created_at&direction=desc
```

### Standard Success Envelope
```json
{
  "success": true,
  "data": {},
  "meta": {
    "current_page": 1,
    "per_page": 25,
    "total": 150,
    "last_page": 6
  },
  "message": "Resource fetched successfully."
}
```

### Standard Error Envelope
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The given data was invalid.",
    "details": {
      "phone_primary": ["The phone primary field is required."]
    }
  }
}
```

### UUID vs ID Policy
- **All public-facing API routes use `uuid`** — never expose internal integer `id`.
- Internal FKs resolved server-side from uuid.
### Rate Limiting & Retry Behaviour

All endpoints are subject to Laravel throttle middleware. Limits vary by endpoint sensitivity:

| Endpoint Group | Limit | Window |
|----------------|-------|--------|
| `POST /auth/customer/otp/request` | 5 requests | 10 minutes per phone |
| `POST /auth/staff/login` | 10 requests | 15 minutes per IP |
| All authenticated staff endpoints | 300 requests | 1 minute per token |
| All authenticated customer endpoints | 60 requests | 1 minute per token |
| `POST /webhooks/payments/{gateway}` | 500 requests | 1 minute per IP (HMAC verified) |

When a rate limit is exceeded, the API returns `429 Too Many Requests` with the following headers and error body:

**Response Headers (always present on `429`)**
```http
HTTP/1.1 429 Too Many Requests
Retry-After: 47
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1746268920
```

- `Retry-After` — seconds the client **must** wait before retrying. Flutter app must read this header and implement exponential back-off with jitter; never retry without honouring this value.
- `X-RateLimit-Limit` — total requests allowed in the current window.
- `X-RateLimit-Remaining` — requests remaining before limiting triggers.
- `X-RateLimit-Reset` — Unix timestamp when the window resets.

**Error Body**
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMITED",
    "message": "Too many requests. Please wait 47 seconds before retrying.",
    "retry_after_seconds": 47
  }
}
```

**Flutter / Mobile Client Implementation Note**
The `dio` interceptor in the Flutter app must inspect the `Retry-After` header on every `429` response and schedule the retry accordingly. Do not use a fixed retry delay — always derive wait time from the header. OTP request screens must surface a countdown timer driven by `Retry-After` rather than a static "please wait" message.

**Laravel Implementation**
```php
// In RouteServiceProvider or api.php
Route::middleware(['throttle:otp'])->group(fn() => ...);
// ThrottleRequests middleware automatically appends Retry-After,
// X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset headers.
// Ensure the custom JSON response shape is enforced via Handler::render().
```
---

## 1. Authentication APIs

### Staff Authentication (Web Dashboard / Admin)

#### `POST /auth/staff/login`
Authenticate staff (owner, technician, admin) with email/phone + PIN.

**Request Payload**
```json
{
  "login": "sagar@garagepro.in",
  "pin": "482917"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "token": "2|abc123xyz...",
    "token_type": "Bearer",
    "expires_at": "2026-06-03T10:00:00Z",
    "user": {
      "uuid": "usr_01J2K9M...",
      "first_name": "Sagar",
      "last_name": "Patel",
      "email": "sagar@garagepro.in",
      "phone": "+919876543210",
      "is_platform_admin": false,
      "is_support_agent": false,
      "tenant": {
        "uuid": "tnt_01J2K9...",
        "business_name": "Patel Auto Works",
        "status": "active",
        "currency": "INR",
        "timezone": "Asia/Kolkata"
      },
      "roles": ["owner"],
      "permissions": ["jobs.create", "invoices.manage", "staff.manage"],
      "last_login_at": "2026-05-01T08:23:00Z"
    }
  }
}
```

**Error Response `401`**
```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Invalid PIN or credentials. 2 attempts remaining."
  }
}
```

---

#### `POST /auth/staff/logout`
Revoke current Sanctum token.

**Request**: No body required.

**Success Response `200`**
```json
{
  "success": true,
  "message": "Logged out successfully."
}
```

---

#### `POST /auth/staff/pin/change`
Change staff PIN (requires current PIN verification).

**Request Payload**
```json
{
  "current_pin": "482917",
  "new_pin": "719284",
  "new_pin_confirmation": "719284"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "message": "PIN updated successfully.",
  "data": {
    "pin_last_changed_at": "2026-05-03T09:15:00Z"
  }
}
```

---

### Customer Authentication (Flutter App)

#### `POST /auth/customer/otp/request`
Send OTP to customer's primary phone for login/registration.

**Request Payload**
```json
{
  "phone": "+919876543210"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "message": "OTP sent successfully.",
  "data": {
    "otp_expires_in_seconds": 120,
    "masked_phone": "+91*****3210",
    "is_new_customer": false
  }
}
```

---

#### `POST /auth/customer/otp/verify`
Verify OTP and return auth token. Creates customer record if new.

**Request Payload**
```json
{
  "phone": "+919876543210",
  "otp": "847291",
  "device_token": "fcm_token_abc123...",
  "platform": "android",
  "app_version": "1.2.0"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "token": "5|cust_token_xyz...",
    "token_type": "Bearer",
    "is_new_customer": false,
    "customer": {
      "uuid": "cst_01J2K9M...",
      "first_name": "Rahul",
      "last_name": "Mehta",
      "phone_primary": "+919876543210",
      "email": "rahul@example.com",
      "preferred_language": "en",
      "marketing_opt_in": false,
      "is_p_wa_enabled": true
    }
  }
}
```

---

## 2. Tenant & Subscription APIs

### Tenant Management

#### `POST /platform/tenants`
*(Platform Admin only)* Create a new garage tenant.

**Request Payload**
```json
{
  "business_name": "Patel Auto Works",
  "business_type": "single",
  "currency": "INR",
  "timezone": "Asia/Kolkata",
  "country_code": "IN",
  "owner": {
    "first_name": "Sagar",
    "last_name": "Patel",
    "email": "sagar@patelauto.in",
    "phone": "+919876543210",
    "pin": "482917"
  },
  "plan_uuid": "plan_01J2K9M..."
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "tenant": {
      "uuid": "tnt_01J2K9...",
      "business_name": "Patel Auto Works",
      "business_type": "single",
      "status": "trial",
      "currency": "INR",
      "timezone": "Asia/Kolkata",
      "country_code": "IN",
      "created_at": "2026-05-03T09:00:00Z"
    },
    "subscription": {
      "uuid": "sub_01J2K9...",
      "status": "trialing",
      "trial_ends_at": "2026-05-17T09:00:00Z",
      "plan": {
        "name": "Starter",
        "billing_cycle": "monthly"
      }
    }
  }
}
```

---

#### `GET /tenant/profile`
Get current tenant's profile (resolves from auth token).

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "tnt_01J2K9...",
    "business_name": "Patel Auto Works",
    "business_type": "single",
    "status": "active",
    "currency": "INR",
    "timezone": "Asia/Kolkata",
    "country_code": "IN",
    "subscription": {
      "status": "active",
      "plan_name": "Growth",
      "current_period_end": "2026-06-03T00:00:00Z",
      "max_users": 20,
      "max_locations": 3
    },
    "created_at": "2026-01-10T00:00:00Z"
  }
}
```

---

#### `PUT /tenant/profile`
Update tenant business details.

**Request Payload**
```json
{
  "business_name": "Patel Auto Works Pvt Ltd",
  "timezone": "Asia/Kolkata",
  "currency": "INR"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "tnt_01J2K9...",
    "business_name": "Patel Auto Works Pvt Ltd",
    "updated_at": "2026-05-03T10:30:00Z"
  },
  "message": "Tenant profile updated successfully."
}
```

---

### Subscription Plans

#### `GET /platform/subscription-plans`
List all public subscription plans.

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "plan_01J2K9...",
      "name": "Starter",
      "slug": "starter",
      "price": 999.00,
      "billing_cycle": "monthly",
      "trial_days": 14,
      "max_locations": 1,
      "max_users": 5,
      "status": "active",
      "features": ["Job Management", "Basic Invoicing", "Customer App"]
    },
    {
      "uuid": "plan_02J2K9...",
      "name": "Growth",
      "slug": "growth",
      "price": 2499.00,
      "billing_cycle": "monthly",
      "trial_days": 14,
      "max_locations": 3,
      "max_users": 20,
      "status": "active",
      "features": ["Everything in Starter", "Inventory Management", "Loyalty Program", "Analytics"]
    }
  ]
}
```

---

#### `POST /tenant/subscription/upgrade`
Upgrade or change the current tenant subscription plan.

**Request Payload**
```json
{
  "plan_uuid": "plan_02J2K9...",
  "billing_cycle": "yearly"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "subscription_uuid": "sub_01J2K9...",
    "status": "active",
    "plan_name": "Growth",
    "billing_cycle": "yearly",
    "current_period_end": "2027-05-03T00:00:00Z",
    "gateway_subscription_id": "sub_razorpay_abc123"
  },
  "message": "Subscription upgraded successfully."
}
```

---

## 3. User & Access Management APIs

#### `GET /users`
List all staff users for the current tenant.

**Query Params**: `?role=technician&is_active=true&search=rahul`

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "usr_01J2K9M...",
      "first_name": "Rahul",
      "last_name": "Shah",
      "email": "rahul@patelauto.in",
      "phone": "+919876540001",
      "roles": ["technician"],
      "skills": [
        { "name": "Engine Repair", "proficiency_level": "expert" },
        { "name": "AC Service", "proficiency_level": "intermediate" }
      ],
      "is_active": true,
      "last_login_at": "2026-05-02T18:00:00Z"
    }
  ],
  "meta": { "current_page": 1, "per_page": 25, "total": 8 }
}
```

---

#### `POST /users`
Create a new staff member.

**Request Payload**
```json
{
  "first_name": "Arjun",
  "last_name": "Patel",
  "email": "arjun@patelauto.in",
  "phone": "+919876540002",
  "pin": "193847",
  "roles": ["technician"],
  "skill_uuids": ["skl_01J2...", "skl_02J2..."]
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "usr_03J2K9M...",
    "first_name": "Arjun",
    "last_name": "Patel",
    "email": "arjun@patelauto.in",
    "phone": "+919876540002",
    "roles": ["technician"],
    "created_at": "2026-05-03T09:00:00Z"
  },
  "message": "Staff member created successfully."
}
```

---

#### `GET /users/{uuid}`
Get a single staff member with skills and recent jobs.

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "usr_01J2K9M...",
    "first_name": "Rahul",
    "last_name": "Shah",
    "email": "rahul@patelauto.in",
    "phone": "+919876540001",
    "roles": ["technician"],
    "pin_last_changed_at": "2026-04-01T00:00:00Z",
    "skills": [
      {
        "uuid": "skl_01J2...",
        "name": "Engine Repair",
        "code": "ENGINE_REPAIR",
        "proficiency_level": "expert",
        "years_experience": 5,
        "is_verified": true
      }
    ],
    "performance_summary": {
      "jobs_completed_this_month": 42,
      "avg_rating": 4.6,
      "on_time_completion_rate": 0.87
    }
  }
}
```

---

#### `PUT /users/{uuid}`
Update staff member details or roles.

**Request Payload**
```json
{
  "first_name": "Rahul",
  "last_name": "Shah",
  "roles": ["technician", "service_advisor"],
  "skill_uuids": ["skl_01J2...", "skl_03J2..."]
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "usr_01J2K9M...",
    "roles": ["technician", "service_advisor"],
    "updated_at": "2026-05-03T10:00:00Z"
  }
}
```

---

#### `DELETE /users/{uuid}`
Soft-delete a staff member.

**Success Response `200`**
```json
{
  "success": true,
  "message": "Staff member deactivated successfully."
}
```

---

#### `PUT /users/{uuid}/skills`
Replace the full skill set for a staff member. Existing skill assignments not in the new list are removed.

**Request Payload**
```json
{
  "skills": [
    {
      "skill_uuid": "skl_01J2...",
      "proficiency_level": "expert",
      "years_experience": 5,
      "is_verified": true
    },
    {
      "skill_uuid": "skl_03J2...",
      "proficiency_level": "intermediate",
      "years_experience": 2,
      "is_verified": false
    }
  ]
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "usr_01J2K9M...",
    "skills": [
      {
        "uuid": "skl_01J2...",
        "name": "Engine Repair",
        "code": "ENGINE_REPAIR",
        "proficiency_level": "expert",
        "years_experience": 5,
        "is_verified": true
      },
      {
        "uuid": "skl_03J2...",
        "name": "Brake Systems",
        "code": "BRAKE_SYS",
        "proficiency_level": "intermediate",
        "years_experience": 2,
        "is_verified": false
      }
    ],
    "updated_at": "2026-05-03T11:00:00Z"
  },
  "message": "Technician skills updated successfully."
}
```

**Error Response `422`** *(skill_uuid does not exist or is inactive)*
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The given data was invalid.",
    "details": {
      "skills.1.skill_uuid": ["The selected skill does not exist or is inactive."]
    }
  }
}
```

---
### Skills

#### `GET /skills`
List all master skills (global + tenant-specific).

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "skl_01J2...",
      "name": "Engine Repair",
      "code": "ENGINE_REPAIR",
      "category": "Mechanical",
      "is_active": true
    },
    {
      "uuid": "skl_02J2...",
      "name": "AC Gas Refill",
      "code": "AC_GAS",
      "category": "Air Conditioning",
      "is_active": true
    }
  ]
}
```

---

## 4. Customer APIs

#### `GET /customers`
List all customers linked to the current tenant's garage.

**Query Params**: `?search=rahul&sort=last_visited_at&has_vehicle=true`

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "cst_01J2K9M...",
      "first_name": "Rahul",
      "last_name": "Mehta",
      "phone_primary": "+919876543210",
      "email": "rahul@example.com",
      "preferred_language": "en",
      "garage_profile": {
        "loyalty_points": 1250,
        "total_spent": 48500.00,
        "visit_count": 7,
        "last_visited_at": "2026-04-15T10:00:00Z",
        "preferred_technician": {
          "uuid": "usr_01J2K9M...",
          "name": "Rahul Shah"
        }
      },
      "vehicles_count": 2,
      "is_active": true
    }
  ],
  "meta": { "current_page": 1, "per_page": 25, "total": 120 }
}
```

---

#### `POST /customers`
Create or link a new customer to this tenant's garage. If `phone_primary` already exists globally, links the existing customer record.

**Request Payload**
```json
{
  "first_name": "Priya",
  "last_name": "Joshi",
  "phone_primary": "+919876540099",
  "phone_secondary": null,
  "email": "priya@example.com",
  "preferred_language": "hi",
  "marketing_opt_in": true,
  "is_p_wa_enabled": true,
  "internal_notes": "VIP customer, referred by owner"
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "cst_04J2K9M...",
    "first_name": "Priya",
    "last_name": "Joshi",
    "phone_primary": "+919876540099",
    "email": "priya@example.com",
    "is_new_global_customer": true,
    "garage_profile": {
      "loyalty_points": 0,
      "total_spent": 0.00,
      "visit_count": 0
    }
  },
  "message": "Customer created and linked to garage."
}
```

---

#### `GET /customers/{uuid}`
Get a single customer with full garage profile, vehicles, and recent jobs.

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "cst_01J2K9M...",
    "first_name": "Rahul",
    "last_name": "Mehta",
    "phone_primary": "+919876543210",
    "phone_secondary": null,
    "email": "rahul@example.com",
    "preferred_language": "en",
    "marketing_opt_in": false,
    "is_p_wa_enabled": true,
    "garage_profile": {
      "internal_notes": "Prefers Saturday appointments",
      "loyalty_points": 1250,
      "total_spent": 48500.00,
      "visit_count": 7,
      "last_visited_at": "2026-04-15T10:00:00Z",
      "preferred_technician": {
        "uuid": "usr_01J2K9M...",
        "name": "Rahul Shah"
      }
    },
    "vehicles": [
      {
        "uuid": "vhc_01J2K9M...",
        "registration_number": "GJ01AB1234",
        "maker": "Maruti Suzuki",
        "model": "Swift",
        "year": 2020,
        "fuel_type": "petrol",
        "color": "White",
        "odometer_reading": 42500
      }
    ],
    "recent_jobs": [
      {
        "uuid": "job_01J2K9M...",
        "job_number": "JOB-2026-0042",
        "status": "delivered",
        "created_at": "2026-04-15T09:00:00Z"
      }
    ]
  }
}
```

---

#### `PUT /customers/{uuid}`
Update customer contact or garage-level details.

**Request Payload**
```json
{
  "email": "rahul.mehta@example.com",
  "preferred_language": "en",
  "internal_notes": "Prefers Saturday appointments. Handle with care.",
  "preferred_technician_uuid": "usr_01J2K9M..."
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "cst_01J2K9M...",
    "email": "rahul.mehta@example.com",
    "garage_profile": {
      "internal_notes": "Prefers Saturday appointments. Handle with care.",
      "preferred_technician": { "uuid": "usr_01J2K9M...", "name": "Rahul Shah" }
    },
    "updated_at": "2026-05-03T10:00:00Z"
  }
}
```

---

## 5. Vehicle APIs

#### `GET /customers/{customer_uuid}/vehicles`
List all vehicles for a specific customer.

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "vhc_01J2K9M...",
      "registration_number": "GJ01AB1234",
      "chassis_number": "MA3FJEB1S00123456",
      "engine_number": "K12BN1234567",
      "maker": "Maruti Suzuki",
      "model": "Swift",
      "variant": "VXi",
      "year": 2020,
      "color": "Pearl Arctic White",
      "fuel_type": "petrol",
      "transmission": "manual",
      "body_type": "hatchback",
      "vehicle_class": "LMV",
      "emission_norms": "BS6",
      "odometer_reading": 42500,
      "gps_tracking_consent": false,
      "odometer_review_status": "none",
      "registration_date": "2020-03-15",
      "registration_validity": "2035-03-14",
      "fitness_validity": null,
      "insurance_expiry": "2027-03-14",
      "is_active": true,
      "photo_url": "https://r2.garageflow.in/vehicles/vhc_01J2.jpg",
      "compliance_alerts": [
        { "type": "puc", "status": "expired", "expiry": "2026-03-01" }
      ]
    }
  ]
}
```

---

#### `POST /customers/{customer_uuid}/vehicles`
Register a new vehicle for a customer.

**Request Payload**
```json
{
  "registration_number": "GJ01CD5678",
  "chassis_number": "MA3FJEB1S00654321",
  "engine_number": "K12BN7654321",
  "maker": "Maruti Suzuki",
  "model": "Baleno",
  "variant": "Delta",
  "year": 2022,
  "color": "Nexa Blue",
  "fuel_type": "petrol",
  "transmission": "manual",
  "body_type": "hatchback",
  "vehicle_class": "LMV",
  "emission_norms": "BS6",
  "registration_date": "2022-07-20",
  "registration_validity": "2037-07-19",
  "odometer_reading": 18000,
  "gps_tracking_consent": false
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "vhc_02J2K9M...",
    "registration_number": "GJ01CD5678",
    "maker": "Maruti Suzuki",
    "model": "Baleno",
    "year": 2022,
    "odometer_reading": 18000,
    "compliance_alerts": [],
    "created_at": "2026-05-03T09:30:00Z"
  },
  "message": "Vehicle registered successfully."
}
```

---

#### `PUT /vehicles/{uuid}`
Update vehicle details or tracking consent.

**Request Payload**
```json
{
  "color": "Midnight Blue",
  "odometer_reading": 19500,
  "gps_tracking_consent": true,
  "insurance_expiry": "2028-07-19"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "vhc_02J2K9M...",
    "odometer_reading": 19500,
    "gps_tracking_consent": true,
    "updated_at": "2026-05-03T10:00:00Z"
  }
}
```

---

#### `GET /vehicles/{uuid}/documents`
List all compliance documents for a vehicle.

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "vdoc_01J2...",
      "document_type": "insurance",
      "document_number": "POL/2024/GJ/123456",
      "issuing_authority": "National Insurance Co.",
      "issue_date": "2024-03-15",
      "expiry_date": "2027-03-14",
      "file_url": "https://r2.garageflow.in/docs/vdoc_01J2.pdf",
      "is_verified": true,
      "is_active": true,
      "status": "valid",
      "days_to_expiry": 315
    },
    {
      "uuid": "vdoc_02J2...",
      "document_type": "puc",
      "document_number": "PUC/GJ01AB1234/2026",
      "expiry_date": "2026-03-01",
      "is_verified": true,
      "status": "expired",
      "days_to_expiry": -63
    }
  ]
}
```

---

#### `POST /vehicles/{uuid}/documents`
Upload a new compliance document.

**Request Payload** *(multipart/form-data)*
```
document_type: "puc"
document_number: "PUC/GJ01AB1234/2026-NEW"
issuing_authority: "RTO Rajkot"
issue_date: "2026-05-03"
expiry_date: "2026-11-02"
file: [binary PDF/image]
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "vdoc_03J2...",
    "document_type": "puc",
    "document_number": "PUC/GJ01AB1234/2026-NEW",
    "expiry_date": "2026-11-02",
    "file_url": "https://r2.garageflow.in/docs/vdoc_03J2.pdf",
    "ocr_extracted_data": {
      "vehicle_reg": "GJ01AB1234",
      "valid_until": "2026-11-02"
    },
    "is_verified": false,
    "status": "valid"
  }
}
```

---

#### `GET /vehicles/{uuid}/mileage-logs`
Get consent-based odometer history.

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "mlog_01J2...",
      "recorded_at": "2026-04-15T09:00:00Z",
      "odometer_value_km": 42500,
      "previous_value_km": 39200,
      "gps_delta_km": 3300,
      "source": "job_intake",
      "review_status": "confirmed"
    },
    {
      "uuid": "mlog_02J2...",
      "recorded_at": "2026-03-10T14:00:00Z",
      "odometer_value_km": 39200,
      "previous_value_km": 35000,
      "source": "customer_approved",
      "review_status": "confirmed"
    }
  ]
}
```

---

#### `POST /vehicles/{uuid}/mileage-logs`
Record a new odometer entry (job intake or admin override).

**Request Payload**
```json
{
  "odometer_value_km": 44200,
  "source": "job_intake",
  "recorded_at": "2026-05-03T09:15:00Z"
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "mlog_03J2...",
    "odometer_value_km": 44200,
    "previous_value_km": 42500,
    "gps_delta_km": 1700,
    "source": "job_intake",
    "review_status": "confirmed",
    "recorded_at": "2026-05-03T09:15:00Z"
  }
}
```

---

## 6. Service Operations APIs

### Service Categories

#### `GET /service-categories`
List all tenant service categories.

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "scat_01J2...",
      "name": "General Service",
      "code": "GEN_SERVICE",
      "default_duration_min": 120,
      "requires_intake_inspection": true,
      "requires_approval": false,
      "is_billable": true,
      "sort_order": 1,
      "is_active": true,
      "items_count": 12
    },
    {
      "uuid": "scat_02J2...",
      "name": "AC Service",
      "code": "AC_SERVICE",
      "default_duration_min": 90,
      "requires_intake_inspection": true,
      "requires_approval": true,
      "is_billable": true,
      "sort_order": 2,
      "is_active": true,
      "items_count": 5
    }
  ]
}
```

---

#### `POST /service-categories`
Create a new service category.

**Request Payload**
```json
{
  "name": "Body Work",
  "code": "BODY_WORK",
  "default_duration_min": 480,
  "requires_intake_inspection": true,
  "requires_approval": true,
  "is_billable": true,
  "sort_order": 5
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "scat_05J2...",
    "name": "Body Work",
    "code": "BODY_WORK",
    "default_duration_min": 480,
    "is_active": true
  }
}
```

---

### Service Items

#### `GET /service-categories/{category_uuid}/items`
List all service items under a category.

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "sitm_01J2...",
      "name": "Engine Oil Change (5W-30)",
      "code": "OIL_CHANGE_5W30",
      "default_price": 850.00,
      "default_labor_minutes": 30,
      "requires_parts": true,
      "is_package": false,
      "tax_applicable": true,
      "sort_order": 1,
      "is_active": true,
      "required_skills": [
        { "uuid": "skl_01J2...", "name": "Engine Repair", "is_primary": true }
      ]
    },
    {
      "uuid": "sitm_02J2...",
      "name": "Air Filter Replacement",
      "code": "AIR_FILTER",
      "default_price": 450.00,
      "default_labor_minutes": 15,
      "requires_parts": true,
      "is_package": false,
      "tax_applicable": true,
      "sort_order": 2,
      "is_active": true
    }
  ]
}
```

---

#### `POST /service-categories/{category_uuid}/items`
Add a new service item.

**Request Payload**
```json
{
  "name": "Brake Pad Replacement",
  "code": "BRAKE_PAD",
  "default_price": 2200.00,
  "default_labor_minutes": 45,
  "requires_parts": true,
  "is_package": false,
  "tax_applicable": true,
  "sort_order": 3,
  "skill_uuids": [
    { "uuid": "skl_03J2...", "is_primary": true }
  ]
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "sitm_03J2...",
    "name": "Brake Pad Replacement",
    "code": "BRAKE_PAD",
    "default_price": 2200.00,
    "default_labor_minutes": 45,
    "is_active": true
  }
}
```

---

### Service Bays

#### `GET /service-bays`
List all service bays with real-time availability.

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "bay_01J2...",
      "name": "Bay 1 - General Lift",
      "code": "BAY01",
      "bay_type": "general_lift",
      "capacity_concurrent": 1,
      "equipment_features": ["2-post lift", "oil drain"],
      "status": "occupied",
      "current_job": {
        "uuid": "job_01J2...",
        "job_number": "JOB-2026-0042",
        "customer_name": "Rahul Mehta",
        "estimated_completion_at": "2026-05-03T14:00:00Z"
      },
      "is_active": true
    },
    {
      "uuid": "bay_02J2...",
      "name": "Bay 2 - AC & Diagnostic",
      "code": "BAY02",
      "bay_type": "diagnostic",
      "capacity_concurrent": 1,
      "status": "available",
      "current_job": null,
      "is_active": true
    }
  ]
}
```

---

#### `PUT /service-bays/{uuid}/status`
Update bay status (manual override).

**Request Payload**
```json
{
  "status": "maintenance",
  "reason": "Hydraulic fluid leak - servicing in progress"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "bay_01J2...",
    "status": "maintenance",
    "updated_at": "2026-05-03T10:15:00Z"
  }
}
```

---

#### `GET /service-bays/availability`
Get real-time availability across all active bays for a given date and time window. Used by scheduling UI and appointment booking to prevent double-allocation.

**Query Params**: `?date=2026-05-05&start_time=09:00&end_time=18:00&bay_type=general_lift`

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "date": "2026-05-05",
    "window": { "start_time": "09:00", "end_time": "18:00" },
    "bays": [
      {
        "uuid": "bay_01J2...",
        "name": "Bay 1 - General Lift",
        "code": "BAY01",
        "bay_type": "general_lift",
        "slots": [
          {
            "start_time": "09:00",
            "end_time": "11:00",
            "is_available": false,
            "reason": "job",
            "job_uuid": "job_01J2...",
            "job_number": "JOB-2026-0042"
          },
          {
            "start_time": "11:00",
            "end_time": "13:00",
            "is_available": true,
            "reason": null,
            "job_uuid": null,
            "job_number": null
          },
          {
            "start_time": "13:00",
            "end_time": "18:00",
            "is_available": false,
            "reason": "maintenance",
            "job_uuid": null,
            "job_number": null
          }
        ]
      },
      {
        "uuid": "bay_02J2...",
        "name": "Bay 2 - AC & Diagnostic",
        "code": "BAY02",
        "bay_type": "diagnostic",
        "slots": [
          {
            "start_time": "09:00",
            "end_time": "18:00",
            "is_available": true,
            "reason": null,
            "job_uuid": null,
            "job_number": null
          }
        ]
      }
    ],
    "summary": {
      "total_bays": 2,
      "fully_available_bays": 1,
      "partially_available_bays": 1,
      "unavailable_bays": 0
    }
  }
}
```

**Notes**
- Slot granularity defaults to 2-hour blocks. Pass `?slot_duration_minutes=60` to override.
- `reason` values: `job` (active job in bay), `appointment` (pre-booked slot), `maintenance` (manual status override), `reserved`.
- Results exclude bays with `status='maintenance'` unless `?include_maintenance=true` is passed.

---

## 7. Job Management APIs

#### `GET /jobs`
List all service jobs with filters.

**Query Params**: `?status=in_progress&priority=urgent&technician_uuid=xxx&date_from=2026-05-01&date_to=2026-05-31`

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "job_01J2K9M...",
      "job_number": "JOB-2026-0042",
      "status": "in_progress",
      "priority": "urgent",
      "customer": {
        "uuid": "cst_01J2...",
        "name": "Rahul Mehta",
        "phone": "+919876543210"
      },
      "vehicle": {
        "uuid": "vhc_01J2...",
        "registration_number": "GJ01AB1234",
        "make_model": "Maruti Swift 2020",
        "fuel_type": "petrol"
      },
      "primary_technician": {
        "uuid": "usr_01J2...",
        "name": "Rahul Shah"
      },
      "service_bay": {
        "uuid": "bay_01J2...",
        "name": "Bay 1 - General Lift"
      },
      "service_categories": ["General Service", "AC Service"],
      "estimated_amount": 4850.00,
      "approval_status": "approved",
      "scheduled_start_at": "2026-05-03T09:00:00Z",
      "estimated_completion_at": "2026-05-03T14:00:00Z",
      "actual_start_at": "2026-05-03T09:15:00Z",
      "tasks_summary": {
        "total": 5,
        "completed": 2,
        "in_progress": 1,
        "pending": 2
      }
    }
  ],
  "meta": { "current_page": 1, "per_page": 25, "total": 38 }
}
```

---

#### `POST /jobs`
Create a new service job (job card opening).

**Request Payload**
```json
{
  "customer_uuid": "cst_01J2K9M...",
  "vehicle_uuid": "vhc_01J2K9M...",
  "priority": "normal",
  "service_category_uuids": ["scat_01J2...", "scat_02J2..."],
  "primary_category_uuid": "scat_01J2...",
  "odometer_at_intake": 44200,
  "fuel_level": "three_quarter",
  "primary_technician_uuid": "usr_01J2K9M...",
  "assigned_bay_uuid": "bay_01J2...",
  "scheduled_start_at": "2026-05-03T09:00:00Z",
  "estimated_completion_at": "2026-05-03T14:00:00Z",
  "handover_notes": "Customer wants AC gas refill done if time permits.",
  "created_by": "usr_admin_01J2..."
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "job_02J2K9M...",
    "job_number": "JOB-2026-0043",
    "status": "draft",
    "priority": "normal",
    "customer": { "uuid": "cst_01J2...", "name": "Rahul Mehta" },
    "vehicle": { "uuid": "vhc_01J2...", "registration_number": "GJ01AB1234" },
    "odometer_at_intake": 44200,
    "fuel_level": "three_quarter",
    "inspection_required": true,
    "estimated_amount": 0.00,
    "approval_status": "pending",
    "tasks": [],
    "created_at": "2026-05-03T09:00:00Z"
  },
  "message": "Job card created. Proceed to intake inspection."
}
```

---

#### `GET /jobs/{uuid}`
Get full job details including tasks, inspection records, and billing summary.

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "job_01J2K9M...",
    "job_number": "JOB-2026-0042",
    "status": "in_progress",
    "priority": "urgent",
    "customer": {
      "uuid": "cst_01J2...",
      "name": "Rahul Mehta",
      "phone": "+919876543210",
      "loyalty_points": 1250
    },
    "vehicle": {
      "uuid": "vhc_01J2...",
      "registration_number": "GJ01AB1234",
      "make_model": "Maruti Swift 2020",
      "odometer_at_intake": 42500,
      "compliance_alerts": [
        { "type": "puc", "status": "expired" }
      ]
    },
    "service_categories": [
      { "uuid": "scat_01J2...", "name": "General Service", "is_primary": true }
    ],
    "tasks": [
      {
        "uuid": "task_01J2...",
        "name": "Engine Oil Change (5W-30)",
        "source": "planned",
        "status": "completed",
        "assigned_technician": { "uuid": "usr_01J2...", "name": "Rahul Shah" },
        "estimated_price": 850.00,
        "final_price": 850.00,
        "labor_minutes": 30,
        "is_billable": true,
        "requires_customer_approval": false
      },
      {
        "uuid": "task_02J2...",
        "name": "Brake Pad Replacement (Rear)",
        "source": "discovered",
        "status": "pending_approval",
        "estimated_price": 2200.00,
        "requires_customer_approval": true,
        "liability_flag": "none"
      }
    ],
    "inspection_summary": {
      "intake_completed": true,
      "delivery_completed": false,
      "damage_flags": 1
    },
    "billing_summary": {
      "estimated_amount": 4850.00,
      "approval_status": "pending",
      "customer_approved_at": null,
      "invoice_uuid": null
    },
    "timeline": {
      "scheduled_start_at": "2026-05-03T09:00:00Z",
      "actual_start_at": "2026-05-03T09:15:00Z",
      "estimated_completion_at": "2026-05-03T14:00:00Z",
      "actual_completion_at": null
    }
  }
}
```

---

#### `PUT /jobs/{uuid}/status`
Transition job workflow status.

**Request Payload**
```json
{
  "status": "ready_for_delivery",
  "notes": "All tasks completed. QC passed."
}
```

**Allowed Transitions**
```
draft → intake_inspection → estimate_pending → estimate_approved → in_progress → qc_pending → ready_for_delivery → delivered
                                             ↘ estimate_rejected (loop back)
Any state → cancelled | on_hold
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "job_01J2K9M...",
    "status": "ready_for_delivery",
    "status_changed_at": "2026-05-03T13:45:00Z"
  },
  "message": "Job status updated. Customer notified via WhatsApp."
}
```

---

### Job Tasks

#### `POST /jobs/{job_uuid}/tasks`
Add a task to an existing job (discovered during service, upsell, etc.).

**Request Payload**
```json
{
  "service_item_uuid": "sitm_03J2...",
  "name": "Brake Pad Replacement (Rear)",
  "source": "discovered",
  "estimated_price": 2200.00,
  "labor_minutes": 45,
  "assigned_technician_uuid": "usr_01J2...",
  "requires_customer_approval": true,
  "liability_flag": "none",
  "is_billable": true,
  "description": "Rear brake pads worn below 2mm. Replacement recommended."
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "task_02J2...",
    "name": "Brake Pad Replacement (Rear)",
    "source": "discovered",
    "status": "pending_approval",
    "estimated_price": 2200.00,
    "requires_customer_approval": true,
    "notification_sent": true
  },
  "message": "Task added. Customer approval request sent."
}
```

---

#### `PUT /jobs/{job_uuid}/tasks/{task_uuid}/status`
Update individual task status.

**Request Payload**
```json
{
  "status": "in_progress",
  "notes": "Started brake pad replacement"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "task_02J2...",
    "status": "in_progress",
    "updated_at": "2026-05-03T11:00:00Z"
  }
}
```

---

#### `POST /jobs/{job_uuid}/estimate/send`
Finalize estimate and send to customer for approval.

**Request Payload**
```json
{
  "channel": "whatsapp",
  "notes_to_customer": "Your vehicle inspection is complete. Please review the estimate and approve to proceed.",
  "validity_hours": 24
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "estimated_amount": 4850.00,
    "tasks_requiring_approval": 1,
    "estimate_sent_at": "2026-05-03T10:30:00Z",
    "estimate_valid_until": "2026-05-04T10:30:00Z",
    "approval_link": "https://app.garageflow.in/approve/est_token_abc123"
  }
}
```

---

#### `POST /jobs/{job_uuid}/estimate/approve`
*(Customer-facing)* Customer approves estimate (via app or link).

**Request Payload**
```json
{
  "approved_task_uuids": ["task_01J2...", "task_02J2..."],
  "rejected_task_uuids": [],
  "customer_signature": "data:image/png;base64,iVBORw0KGgo...",
  "approval_token": "est_token_abc123"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "approval_status": "approved",
    "customer_approved_at": "2026-05-03T10:45:00Z",
    "approved_amount": 4850.00,
    "job_status": "in_progress"
  },
  "message": "Estimate approved. Work order released to technicians."
}
```

---

## 8. Inspection APIs

#### `GET /inspection-templates`
List all active inspection templates.

**Query Params**: `?phase=intake&is_mandatory=true`

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "itpl_01J2...",
      "name": "Front Bumper Condition",
      "code": "FRONT_BUMPER",
      "component_name": "Front Bumper",
      "component_category": "Exterior",
      "expected_condition": "no_damage",
      "is_mandatory": true,
      "requires_photo": true,
      "sort_order": 1,
      "is_active": true
    },
    {
      "uuid": "itpl_02J2...",
      "name": "Windshield Condition",
      "code": "WINDSHIELD",
      "component_name": "Windshield",
      "component_category": "Glass",
      "expected_condition": "no_cracks",
      "is_mandatory": true,
      "requires_photo": false,
      "sort_order": 2
    }
  ]
}
```

---

#### `GET /jobs/{job_uuid}/inspection`
Get all inspection records for a job (intake + delivery).

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "intake": [
      {
        "uuid": "irec_01J2...",
        "template_uuid": "itpl_01J2...",
        "component_name": "Front Bumper",
        "component_category": "Exterior",
        "condition_status": "minor_scratch",
        "severity": "low",
        "notes": "3cm scratch on left side",
        "media_urls": ["https://r2.garageflow.in/inspect/irec_01J2_1.jpg"],
        "inspected_by": { "uuid": "usr_01J2...", "name": "Rahul Shah" },
        "customer_acknowledged": true,
        "acknowledged_at": "2026-05-03T09:20:00Z"
      }
    ],
    "delivery": [],
    "damage_comparison": {
      "new_damage_detected": false,
      "flagged_items": []
    }
  }
}
```

---

#### `POST /jobs/{job_uuid}/inspection`
Submit inspection records (bulk — entire checklist at once).

**Request Payload**
```json
{
  "inspection_phase": "intake",
  "records": [
    {
      "template_uuid": "itpl_01J2...",
      "condition_status": "minor_scratch",
      "severity": "low",
      "notes": "3cm scratch on left side of front bumper",
      "media_urls": ["https://r2.garageflow.in/inspect/tmp_photo_1.jpg"]
    },
    {
      "template_uuid": "itpl_02J2...",
      "condition_status": "ok",
      "severity": null,
      "notes": null,
      "media_urls": []
    }
  ],
  "signature_url": "https://r2.garageflow.in/signatures/job_02J2_intake.png",
  "customer_acknowledged": true
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "inspection_phase": "intake",
    "total_records": 2,
    "flagged_items": 1,
    "completed_at": "2026-05-03T09:20:00Z",
    "job_status_advanced_to": "estimate_pending"
  },
  "message": "Intake inspection completed. Job advanced to estimate pending."
}
```

---

#### `POST /jobs/{job_uuid}/inspection/upload-media`
Upload inspection photo to S3/R2 and get URL.

**Request Payload** *(multipart/form-data)*
```
file: [binary image]
phase: "intake"
component_code: "FRONT_BUMPER"
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "url": "https://r2.garageflow.in/inspect/tmp_photo_abc123.jpg",
    "expires_at": "2026-05-03T11:00:00Z"
  }
}
```

---

## 9. Inventory & Supply Chain APIs

### Inventory

#### `GET /inventory`
List all inventory items with stock levels.

**Query Params**: `?low_stock=true&category_uuid=xxx&search=oil`

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "inv_01J2...",
      "sku": "LUB-5W30-1L",
      "name": "Engine Oil 5W-30 (1 Litre)",
      "brand": "Castrol",
      "category": { "uuid": "pcat_01J2...", "name": "Lubricants" },
      "unit_of_measure": "litre",
      "cost_price": 320.00,
      "selling_price": 450.00,
      "stock_on_hand": 24,
      "low_stock_threshold": 10,
      "reorder_quantity": 50,
      "is_low_stock": false,
      "preferred_vendor": { "uuid": "vnd_01J2...", "name": "Castrol Distributor GJ" },
      "is_active": true
    }
  ],
  "meta": { "current_page": 1, "per_page": 25, "total": 87 }
}
```

---

#### `POST /inventory`
Add a new inventory item.

**Request Payload**
```json
{
  "sku": "BRK-PAD-FRT-SWIFT",
  "name": "Brake Pad Front - Maruti Swift (Set of 4)",
  "brand": "TVS Girling",
  "category_uuid": "pcat_02J2...",
  "unit_of_measure": "set",
  "cost_price": 680.00,
  "selling_price": 950.00,
  "tax_rate_uuid": "tax_01J2...",
  "stock_on_hand": 8,
  "low_stock_threshold": 3,
  "reorder_quantity": 10,
  "preferred_vendor_uuid": "vnd_02J2...",
  "requires_serial_warranty": false
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "inv_02J2...",
    "sku": "BRK-PAD-FRT-SWIFT",
    "name": "Brake Pad Front - Maruti Swift (Set of 4)",
    "stock_on_hand": 8,
    "is_active": true,
    "created_at": "2026-05-03T09:00:00Z"
  }
}
```

---

#### `PUT /inventory/{uuid}/stock-adjust`
Manual stock adjustment (receiving, shrinkage, correction).

**Request Payload**
```json
{
  "adjustment_type": "addition",
  "quantity": 10,
  "reason": "Received stock from vendor PO-2026-0018",
  "reference": "PO-2026-0018"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "inv_01J2...",
    "previous_stock": 14,
    "adjustment": 10,
    "stock_on_hand": 24,
    "adjusted_at": "2026-05-03T10:00:00Z"
  }
}
```

---

### Vendors

#### `GET /vendors`
List all vendors.

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "vnd_01J2...",
      "name": "Castrol Distributor GJ",
      "code": "CASTROL-GJ",
      "vendor_type": "parts_supplier",
      "contact_name": "Mahesh Trivedi",
      "contact_phone": "+919876501234",
      "contact_email": "mahesh@castrol-gj.in",
      "payment_terms": "net_30",
      "credit_limit": 50000.00,
      "current_balance": 12400.00,
      "rating": 4.5,
      "average_lead_time_days": 2,
      "is_preferred": true,
      "is_active": true
    }
  ]
}
```

---

### Purchase Orders

#### `POST /purchase-orders`
Create a new purchase order.

**Request Payload**
```json
{
  "vendor_uuid": "vnd_01J2...",
  "expected_delivery_date": "2026-05-06",
  "notes": "Urgent restock — brake pads critically low",
  "items": [
    {
      "inventory_item_uuid": "inv_02J2...",
      "quantity_ordered": 10,
      "unit_cost": 680.00,
      "tax_rate_uuid": "tax_01J2..."
    },
    {
      "inventory_item_uuid": "inv_03J2...",
      "quantity_ordered": 5,
      "unit_cost": 320.00,
      "tax_rate_uuid": "tax_01J2..."
    }
  ]
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "po_01J2...",
    "po_number": "PO-2026-0018",
    "status": "pending",
    "vendor": { "uuid": "vnd_01J2...", "name": "Castrol Distributor GJ" },
    "subtotal": 8400.00,
    "tax_total": 1512.00,
    "grand_total": 9912.00,
    "expected_delivery_date": "2026-05-06",
    "payment_status": "unpaid",
    "items_count": 2,
    "created_at": "2026-05-03T09:00:00Z"
  }
}
```

---
#### `GET /purchase-orders`
List all purchase orders with filters.

**Query Params**: `?status=pending&vendor_uuid=xxx&date_from=2026-05-01&date_to=2026-05-31`

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "po_01J2...",
      "po_number": "PO-2026-0018",
      "status": "partially_received",
      "vendor": {
        "uuid": "vnd_01J2...",
        "name": "Castrol Distributor GJ",
        "vendor_type": "parts_supplier"
      },
      "order_date": "2026-05-03",
      "expected_delivery_date": "2026-05-06",
      "actual_delivery_date": null,
      "subtotal": 8400.00,
      "tax_total": 1512.00,
      "grand_total": 9912.00,
      "payment_status": "unpaid",
      "items_count": 2,
      "items_received_count": 1,
      "created_by": { "uuid": "usr_admin_01J2...", "name": "Sagar Patel" },
      "created_at": "2026-05-03T09:00:00Z"
    }
  ],
  "meta": { "current_page": 1, "per_page": 25, "total": 14 }
}
```

---
#### `PUT /purchase-orders/{uuid}/receive`
Mark purchase order items as received (supports partial receipts).

**Request Payload**
```json
{
  "items": [
    {
      "po_item_uuid": "poi_01J2...",
      "quantity_received": 10
    },
    {
      "po_item_uuid": "poi_02J2...",
      "quantity_received": 3
    }
  ],
  "notes": "2 units of item 2 backordered — will arrive separately"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "po_01J2...",
    "po_number": "PO-2026-0018",
    "status": "partially_received",
    "stock_updates": [
      { "sku": "BRK-PAD-FRT-SWIFT", "previous": 8, "added": 10, "new": 18 },
      { "sku": "LUB-5W30-1L", "previous": 14, "added": 3, "new": 17 }
    ]
  }
}
```

---

## 10. Billing & Payment APIs

### Invoices

#### `GET /jobs/{job_uuid}/invoice`
Get the invoice for a specific job.

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "inv_01J2...",
    "invoice_number": "INV-2026-0089",
    "type": "final",
    "status": "partially_paid",
    "issued_date": "2026-05-03",
    "due_date": "2026-05-10",
    "customer": { "uuid": "cst_01J2...", "name": "Rahul Mehta" },
    "vehicle": { "registration_number": "GJ01AB1234" },
    "items": [
      {
        "uuid": "iitm_01J2...",
        "line_type": "service",
        "name": "Engine Oil Change (5W-30)",
        "quantity": 1.00,
        "unit_price": 850.00,
        "tax_amount": 153.00,
        "discount_amount": 0.00,
        "total_amount": 1003.00,
        "is_taxable": true
      },
      {
        "uuid": "iitm_02J2...",
        "line_type": "part",
        "name": "Engine Oil 5W-30 (4L)",
        "quantity": 4.00,
        "unit_price": 450.00,
        "tax_amount": 324.00,
        "discount_amount": 0.00,
        "total_amount": 2124.00,
        "is_taxable": true
      },
      {
        "uuid": "iitm_03J2...",
        "line_type": "discount",
        "name": "Loyalty Points Redemption",
        "quantity": 1.00,
        "unit_price": -250.00,
        "tax_amount": 0.00,
        "discount_amount": 0.00,
        "total_amount": -250.00,
        "is_taxable": false
      }
    ],
    "subtotal": 4850.00,
    "tax_total": 873.00,
    "discount_total": 250.00,
    "grand_total": 5473.00,
    "amount_paid": 2000.00,
    "balance_due": 3473.00,
    "customer_pay_amount": 5473.00,
    "insurance_claim_amount": 0.00,
    "pdf_url": "https://r2.garageflow.in/invoices/INV-2026-0089.pdf",
    "qr_code_url": "https://r2.garageflow.in/qr/INV-2026-0089.png"
  }
}
```

---

#### `POST /jobs/{job_uuid}/invoice`
Generate invoice from a completed job.

**Request Payload**
```json
{
  "type": "final",
  "issued_date": "2026-05-03",
  "due_date": "2026-05-10",
  "loyalty_points_to_redeem": 250,
  "customer_notes": "Thank you for choosing Patel Auto Works!",
  "terms_conditions": "Payment due within 7 days. No liability for pre-existing damage.",
  "manual_items": [
    {
      "line_type": "manual",
      "name": "Wheel Balancing",
      "quantity": 4,
      "unit_price": 75.00,
      "tax_rate_uuid": "tax_01J2...",
      "is_taxable": true
    }
  ]
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "inv_02J2...",
    "invoice_number": "INV-2026-0090",
    "status": "draft",
    "grand_total": 5473.00,
    "loyalty_points_redeemed": 250,
    "pdf_url": null,
    "created_at": "2026-05-03T13:50:00Z"
  },
  "message": "Invoice created as draft. Review and send to customer."
}
```

---

#### `POST /invoices/{uuid}/send`
Send invoice to customer and lock it as immutable.

**Request Payload**
```json
{
  "channel": "whatsapp",
  "send_email": true
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "inv_02J2...",
    "invoice_number": "INV-2026-0090",
    "status": "sent",
    "pdf_url": "https://r2.garageflow.in/invoices/INV-2026-0090.pdf",
    "sent_at": "2026-05-03T14:00:00Z"
  }
}
```

---

### Payments

#### `POST /invoices/{invoice_uuid}/payments`
Record a payment against an invoice.

**Request Payload**
```json
{
  "payment_method_uuid": "pm_01J2...",
  "payment_type": "customer_pay",
  "amount": 3473.00,
  "reference_number": "UPI/2026/GJ/123456",
  "notes": "Final payment via UPI",
  "paid_at": "2026-05-03T14:15:00Z"
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "pay_01J2...",
    "amount": 3473.00,
    "status": "success",
    "payment_type": "customer_pay",
    "reference_number": "UPI/2026/GJ/123456",
    "invoice_status": "paid",
    "balance_due": 0.00,
    "loyalty_points_earned": 347,
    "paid_at": "2026-05-03T14:15:00Z"
  },
  "message": "Payment recorded. Invoice marked as paid. 347 loyalty points credited."
}
```

---

#### `POST /invoices/{invoice_uuid}/payments/gateway/initiate`
Initiate an online payment via Razorpay/PhonePe/Cashfree.

**Request Payload**
```json
{
  "payment_method_uuid": "pm_razorpay_01J2...",
  "amount": 3473.00,
  "return_url": "https://app.garageflow.in/payment/callback"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "gateway_order_id": "order_MNOPQabc123",
    "gateway_key": "rzp_live_abc123",
    "amount_paise": 347300,
    "currency": "INR",
    "prefill": {
      "name": "Rahul Mehta",
      "email": "rahul@example.com",
      "contact": "+919876543210"
    }
  }
}
```

---

#### `POST /webhooks/payments/{gateway}`
Webhook endpoint for payment gateway callbacks. *(Public — HMAC verified)*

**Request Payload** *(Razorpay example)*
```json
{
  "event": "payment.captured",
  "payload": {
    "payment": {
      "entity": {
        "id": "pay_MNOPQabc123",
        "order_id": "order_MNOPQabc123",
        "amount": 347300,
        "status": "captured"
      }
    }
  }
}
```

**Success Response `200`**
```json
{ "status": "ok" }
```

---

### Tax Rates

#### `GET /tax-rates`
List all configured tax rates.

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "tax_01J2...",
      "name": "GST 18%",
      "code": "GST18",
      "tax_type": "gst",
      "rate_percentage": 18.00,
      "is_compound": true,
      "component_breakdown": {
        "CGST": 9.00,
        "SGST": 9.00
      },
      "applicable_to": "both",
      "effective_from": "2017-07-01",
      "effective_to": null,
      "is_active": true,
      "is_default": true
    },
    {
      "uuid": "tax_02J2...",
      "name": "GST 5%",
      "code": "GST5",
      "tax_type": "gst",
      "rate_percentage": 5.00,
      "is_compound": true,
      "component_breakdown": { "CGST": 2.50, "SGST": 2.50 },
      "applicable_to": "services",
      "is_active": true,
      "is_default": false
    }
  ]
}
```

---

### Payment Methods

#### `GET /payment-methods`
List all active payment methods for the tenant.

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "pm_01J2...",
      "name": "UPI / PhonePe",
      "code": "UPI",
      "type": "digital",
      "gateway_provider": "phonepe",
      "requires_reference": true,
      "is_active": true,
      "sort_order": 1
    },
    {
      "uuid": "pm_02J2...",
      "name": "Cash",
      "code": "CASH",
      "type": "cash",
      "gateway_provider": null,
      "requires_reference": false,
      "is_active": true,
      "sort_order": 2
    }
  ]
}
```

---

## 11. Scheduling & Appointment APIs

#### `GET /appointments`
List appointments with filters.

**Query Params**: `?date=2026-05-05&status=booked&technician_uuid=xxx`

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "apt_01J2...",
      "appointment_number": "APT-2026-0015",
      "status": "confirmed",
      "scheduled_date": "2026-05-05",
      "start_time": "10:00:00",
      "end_time": "12:00:00",
      "source": "customer_app",
      "customer": { "uuid": "cst_01J2...", "name": "Rahul Mehta", "phone": "+919876543210" },
      "vehicle": { "uuid": "vhc_01J2...", "registration_number": "GJ01AB1234" },
      "service_category": { "uuid": "scat_01J2...", "name": "General Service" },
      "assigned_technician": { "uuid": "usr_01J2...", "name": "Rahul Shah" },
      "assigned_bay": { "uuid": "bay_01J2...", "name": "Bay 1" },
      "notes": "Customer requested oil change + tyre pressure check",
      "customer_acknowledged": true
    }
  ],
  "meta": { "current_page": 1, "per_page": 25, "total": 12 }
}
```

---

#### `POST /appointments`
Book a new appointment.

**Request Payload**
```json
{
  "customer_uuid": "cst_01J2...",
  "vehicle_uuid": "vhc_01J2...",
  "service_category_uuid": "scat_01J2...",
  "scheduled_date": "2026-05-05",
  "start_time": "10:00",
  "end_time": "12:00",
  "assigned_technician_uuid": "usr_01J2...",
  "assigned_bay_uuid": "bay_01J2...",
  "source": "staff_dashboard",
  "notes": "Customer requested oil change + tyre pressure check"
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "apt_02J2...",
    "appointment_number": "APT-2026-0016",
    "status": "booked",
    "scheduled_date": "2026-05-05",
    "start_time": "10:00:00",
    "end_time": "12:00:00",
    "reminder_scheduled_at": "2026-05-04T10:00:00Z"
  },
  "message": "Appointment booked. Reminder will be sent 24 hours before."
}
```

---

#### `PUT /appointments/{uuid}/check-in`
Convert appointment to a service job on customer arrival.

**Request Payload**
```json
{
  "odometer_at_intake": 44200,
  "fuel_level": "half"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "appointment_uuid": "apt_01J2...",
    "appointment_status": "checked_in",
    "job": {
      "uuid": "job_03J2...",
      "job_number": "JOB-2026-0044",
      "status": "intake_inspection"
    }
  },
  "message": "Customer checked in. Job card JOB-2026-0044 created."
}
```

---

#### `GET /appointments/availability`
Check slot availability for a date and bay/technician.

**Query Params**: `?date=2026-05-05&bay_uuid=bay_01J2...&duration_minutes=120`

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "date": "2026-05-05",
    "bay": { "uuid": "bay_01J2...", "name": "Bay 1" },
    "available_slots": [
      { "start_time": "08:00", "end_time": "10:00", "is_available": true },
      { "start_time": "10:00", "end_time": "12:00", "is_available": false, "reason": "booked" },
      { "start_time": "12:00", "end_time": "14:00", "is_available": true },
      { "start_time": "14:00", "end_time": "16:00", "is_available": true },
      { "start_time": "16:00", "end_time": "18:00", "is_available": true }
    ]
  }
}
```

---

## 12. Notification APIs

#### `GET /notification-templates`
List all notification templates.

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "ntpl_01J2...",
      "event_code": "job_status_updated",
      "name": "Job Status Update",
      "channel": "whatsapp",
      "subject": null,
      "template_body": "Hi {{customer_name}}, your vehicle {{registration_number}} is now {{job_status}}. Estimated completion: {{estimated_time}}.",
      "is_active": true
    },
    {
      "uuid": "ntpl_02J2...",
      "event_code": "mileage_due",
      "name": "Service Due Reminder (Mileage)",
      "channel": "push",
      "template_body": "Your {{vehicle}} is due for service. Current odometer: {{odometer}}km. Book now.",
      "is_active": true
    }
  ]
}
```

---

#### `PUT /notification-templates/{uuid}`
Update a notification template.

**Request Payload**
```json
{
  "template_body": "Hi {{customer_name}}, great news! Your {{make_model}} ({{registration_number}}) is ready for pickup at Patel Auto Works. Please arrive by {{closing_time}}. — Patel Auto Works Team",
  "is_active": true
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "ntpl_01J2...",
    "event_code": "job_status_updated",
    "template_body": "Hi {{customer_name}}, great news!...",
    "updated_at": "2026-05-03T10:00:00Z"
  }
}
```

---

#### `POST /notification-templates`
Create a custom notification template for a new event code or an additional channel variant of an existing event.

**Request Payload**
```json
{
  "event_code": "appointment_reminder_24h",
  "name": "Appointment Reminder (24h)",
  "channel": "whatsapp",
  "subject": null,
  "template_body": "Hi {{customer_name}}, reminder: your vehicle {{registration_number}} is booked for service at {{garage_name}} tomorrow at {{appointment_time}}. Reply CONFIRM to acknowledge or call us at {{garage_phone}} to reschedule.",
  "is_active": true
}
```

**Field Notes**
- `event_code` must match a registered system event or a tenant-defined custom event. System codes are read-only; tenant codes use prefix `custom_`.
- `channel` accepts: `whatsapp`, `sms`, `email`, `push`. One template per `(event_code, channel)` combination per tenant.
- `template_body` supports mustache-style variables: `{{customer_name}}`, `{{registration_number}}`, `{{garage_name}}`, `{{garage_phone}}`, `{{appointment_time}}`, `{{estimated_completion}}`, `{{job_number}}`, `{{invoice_total}}`, `{{loyalty_points}}`.

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "ntpl_03J2...",
    "event_code": "appointment_reminder_24h",
    "name": "Appointment Reminder (24h)",
    "channel": "whatsapp",
    "subject": null,
    "template_body": "Hi {{customer_name}}, reminder: your vehicle...",
    "is_active": true,
    "created_at": "2026-05-03T10:00:00Z"
  },
  "message": "Notification template created successfully."
}
```

**Error Response `409`** *(duplicate channel for event_code)*
```json
{
  "success": false,
  "error": {
    "code": "DUPLICATE_RESOURCE",
    "message": "A template for event 'appointment_reminder_24h' on channel 'whatsapp' already exists. Update the existing template instead."
  }
}
```

---

#### `GET /notifications`
List all sent notifications with delivery status.

**Query Params**: `?customer_uuid=xxx&channel=whatsapp&status=delivered&date_from=2026-05-01`

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "notif_01J2...",
      "event_code": "job_status_updated",
      "channel": "whatsapp",
      "recipient": "+919876543210",
      "status": "delivered",
      "sent_at": "2026-05-03T13:45:00Z",
      "reference_type": "service_job",
      "reference_uuid": "job_01J2..."
    }
  ]
}
```

---

## 13. Loyalty & Retention APIs

#### `GET /loyalty-program`
Get the current tenant's loyalty program configuration.

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "lp_01J2...",
    "name": "Patel Points",
    "earning_mode": "spend_based",
    "points_per_amount": 1.00,
    "min_spend_threshold": 500.00,
    "redemption_rate": 0.25,
    "min_points_to_redeem": 100,
    "max_discount_percent": 15,
    "points_expiry_days": 365,
    "stack_with_other_discounts": false,
    "is_active": true
  }
}
```

---

#### `PUT /loyalty-program`
Update loyalty program configuration.

**Request Payload**
```json
{
  "name": "Patel Rewards",
  "points_per_amount": 1.00,
  "min_spend_threshold": 300.00,
  "redemption_rate": 0.25,
  "min_points_to_redeem": 100,
  "max_discount_percent": 20,
  "points_expiry_days": 365
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "lp_01J2...",
    "name": "Patel Rewards",
    "updated_at": "2026-05-03T10:00:00Z"
  }
}
```

---

#### `GET /customers/{customer_uuid}/loyalty`
Get customer loyalty balance and transaction history.

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "current_balance": 1250,
    "lifetime_earned": 2480,
    "lifetime_redeemed": 1100,
    "expiring_soon": {
      "points": 350,
      "expires_at": "2026-08-01T00:00:00Z"
    },
    "transactions": [
      {
        "uuid": "ltxn_01J2...",
        "type": "earned",
        "points": 485,
        "balance_after": 1250,
        "description": "Earned on Invoice INV-2026-0089",
        "reference_type": "invoice",
        "reference_uuid": "inv_01J2...",
        "created_at": "2026-04-15T14:30:00Z"
      },
      {
        "uuid": "ltxn_02J2...",
        "type": "redeemed",
        "points": -250,
        "balance_after": 765,
        "description": "Redeemed on Invoice INV-2026-0077",
        "reference_type": "invoice",
        "reference_uuid": "inv_prev...",
        "created_at": "2026-03-10T11:00:00Z"
      }
    ]
  }
}
```

---

#### `POST /customers/{customer_uuid}/loyalty/adjust`
*(Admin only)* Manual loyalty point adjustment.

**Request Payload**
```json
{
  "type": "adjusted",
  "points": 200,
  "description": "Goodwill points for delayed service on job JOB-2026-0032",
  "reference_type": "service_job",
  "reference_uuid": "job_prev..."
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "ltxn_03J2...",
    "type": "adjusted",
    "points": 200,
    "balance_after": 1450,
    "created_at": "2026-05-03T10:00:00Z"
  }
}
```

---

## 14. Feedback & Review APIs

#### `POST /jobs/{job_uuid}/feedback/request`
Send feedback request to customer after delivery.

**Request Payload**
```json
{
  "channel": "whatsapp"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "fbk_01J2...",
    "status": "requested",
    "sent_at": "2026-05-03T15:00:00Z",
    "feedback_link": "https://app.garageflow.in/feedback/fbk_token_xyz"
  }
}
```

---

#### `POST /feedback/{feedback_uuid}/submit`
*(Customer-facing)* Submit feedback/rating.

**Request Payload**
```json
{
  "rating_overall": 5,
  "rating_breakdown": {
    "service_quality": 5,
    "technician_behavior": 5,
    "timeliness": 4,
    "value_for_money": 5
  },
  "comments": "Excellent service! Rahul was very professional and explained everything clearly.",
  "channel": "customer_app",
  "feedback_token": "fbk_token_xyz"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "fbk_01J2...",
    "rating_overall": 5,
    "status": "submitted",
    "submitted_at": "2026-05-03T15:30:00Z",
    "loyalty_points_earned": 50
  },
  "message": "Thank you for your feedback! 50 bonus points credited."
}
```

---

#### `GET /feedback`
List all feedback reviews with filters.

**Query Params**: `?status=needs_attention&rating_max=3&technician_uuid=xxx`

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "fbk_02J2...",
      "job_uuid": "job_prev...",
      "customer": { "name": "Priya Joshi", "phone": "+919876540099" },
      "technician": { "uuid": "usr_02J2...", "name": "Arjun Patel" },
      "rating_overall": 2,
      "rating_breakdown": {
        "service_quality": 2,
        "timeliness": 1,
        "value_for_money": 3
      },
      "comments": "Waited 3 hours extra. Not happy.",
      "status": "needs_attention",
      "submitted_at": "2026-04-20T17:00:00Z"
    }
  ]
}
```

---

#### `POST /feedback/{uuid}/respond`
Staff responds to a customer review.

**Request Payload**
```json
{
  "response_text": "Dear Priya, we sincerely apologize for the delay. We've taken steps to improve our scheduling. Please allow us to make it right on your next visit."
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "fbk_02J2...",
    "status": "resolved",
    "response_text": "Dear Priya, we sincerely apologize...",
    "responded_by": { "uuid": "usr_admin_01J2...", "name": "Sagar Patel" },
    "response_at": "2026-05-03T11:00:00Z"
  }
}
```

---

## 15. Customer Mobile App APIs

> All endpoints prefixed with `/customer/` are authenticated via customer OTP token and are scoped to the customer's own data.

#### `GET /customer/profile`
Get current customer's own profile.

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "cst_01J2...",
    "first_name": "Rahul",
    "last_name": "Mehta",
    "phone_primary": "+919876543210",
    "email": "rahul@example.com",
    "preferred_language": "en",
    "marketing_opt_in": false,
    "is_p_wa_enabled": true
  }
}
```

---

#### `GET /customer/vehicles`
Get all vehicles belonging to the customer.

*(Same structure as staff Vehicle List, but scoped to authenticated customer)*

---

#### `GET /customer/jobs`
Get customer's job history across all garages.

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "job_01J2...",
      "job_number": "JOB-2026-0042",
      "garage_name": "Patel Auto Works",
      "status": "delivered",
      "vehicle_registration": "GJ01AB1234",
      "service_categories": ["General Service"],
      "actual_completion_at": "2026-04-15T14:00:00Z",
      "invoice_total": 5473.00
    }
  ]
}
```

---

#### `GET /customer/jobs/{uuid}/progress`
Real-time job progress for the customer app.

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "job_01J2...",
    "job_number": "JOB-2026-0042",
    "status": "in_progress",
    "status_label": "Service in Progress",
    "garage": {
      "name": "Patel Auto Works",
      "phone": "+912816123456",
      "address": "Plot 12, GIDC, Rajkot - 360004"
    },
    "vehicle": { "registration_number": "GJ01AB1234", "make_model": "Maruti Swift 2020" },
    "primary_technician": { "name": "Rahul Shah", "avatar_url": null },
    "tasks": [
      { "name": "Engine Oil Change", "status": "completed" },
      { "name": "Air Filter Check", "status": "in_progress" },
      { "name": "Brake Pad Replacement", "status": "pending_approval", "requires_your_approval": true, "estimated_cost": 2200.00 }
    ],
    "estimated_completion_at": "2026-05-03T14:00:00Z",
    "approval_required": true
  }
}
```

---

#### `POST /customer/jobs/{uuid}/tasks/{task_uuid}/approve`
Customer approves or rejects a task from the app.

**Request Payload**
```json
{
  "decision": "approved",
  "signature": "data:image/png;base64,iVBORw0KGgo..."
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "task_uuid": "task_02J2...",
    "decision": "approved",
    "decided_at": "2026-05-03T11:00:00Z"
  },
  "message": "Task approved. Technician notified."
}
```

---

#### `GET /customer/vehicles/{uuid}/service-reminders`
Get upcoming service reminders for a vehicle.

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "vehicle": {
      "uuid": "vhc_01J2...",
      "registration_number": "GJ01AB1234",
      "make_model": "Maruti Swift 2020",
      "current_odometer": 44200
    },
    "next_service": {
      "due_in_km": 800,
      "due_km": 45000,
      "due_date": "2026-06-15",
      "urgency": "upcoming"
    },
    "preferences": {
      "preferred_interval_km": 5000,
      "preferred_interval_months": 6,
      "reminder_channel": "push",
      "advance_notice_km": 500
    }
  }
}
```

---

#### `PUT /customer/vehicles/{uuid}/service-preferences`
Customer updates their service interval preferences.

**Request Payload**
```json
{
  "preferred_interval_km": 5000,
  "preferred_interval_months": 6,
  "reminder_channel": "whatsapp",
  "advance_notice_days": 7,
  "advance_notice_km": 500,
  "is_active": true
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "vehicle_uuid": "vhc_01J2...",
    "preferred_interval_km": 5000,
    "reminder_channel": "whatsapp",
    "updated_at": "2026-05-03T10:00:00Z"
  }
}
```

---

#### `POST /customer/vehicles/{uuid}/odometer/confirm`
Customer confirms GPS-estimated odometer reading.

**Request Payload**
```json
{
  "odometer_value_km": 44200,
  "source": "customer_approved",
  "decision": "confirmed"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "uuid": "mlog_new_01J2...",
    "odometer_value_km": 44200,
    "source": "customer_approved",
    "review_status": "confirmed",
    "vehicle_odometer_updated_to": 44200
  }
}
```

---

#### `POST /customer/sessions/register`
Register or refresh FCM/APNS device token.

**Request Payload**
```json
{
  "device_token": "fcm_new_token_xyz123...",
  "platform": "android",
  "app_version": "1.3.0"
}
```

**Success Response `200`**
```json
{
  "success": true,
  "message": "Device session registered."
}
```

---

#### `POST /customer/engagement/track`
Track customer engagement event (behavioral intelligence).

**Request Payload**
```json
{
  "event_type": "viewed_job_progress",
  "reference_type": "service_job",
  "reference_uuid": "job_01J2...",
  "metadata": {
    "time_spent_seconds": 45,
    "screen": "job_detail"
  }
}
```

**Success Response `200`**
```json
{
  "success": true,
  "message": "Event tracked."
}
```

---

#### `GET /customer/appointments`
Get customer's upcoming and past appointments.

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "apt_01J2...",
      "appointment_number": "APT-2026-0015",
      "status": "confirmed",
      "garage_name": "Patel Auto Works",
      "garage_address": "Plot 12, GIDC, Rajkot",
      "scheduled_date": "2026-05-05",
      "start_time": "10:00",
      "vehicle_registration": "GJ01AB1234",
      "service_category": "General Service"
    }
  ]
}
```

---

#### `POST /customer/appointments`
Book an appointment from the customer app.

**Request Payload**
```json
{
  "garage_uuid": "tnt_01J2...",
  "vehicle_uuid": "vhc_01J2...",
  "service_category_uuid": "scat_01J2...",
  "scheduled_date": "2026-05-10",
  "preferred_start_time": "11:00",
  "notes": "Please check AC too"
}
```

**Success Response `201`**
```json
{
  "success": true,
  "data": {
    "uuid": "apt_03J2...",
    "appointment_number": "APT-2026-0017",
    "status": "booked",
    "scheduled_date": "2026-05-10",
    "start_time": "11:00",
    "garage_name": "Patel Auto Works"
  },
  "message": "Appointment booked! You'll receive a confirmation on WhatsApp."
}
```

---

## 16. Audit & System APIs

#### `GET /audit-logs`
*(Platform Admin / Owner only)* Query audit trail.

**Query Params**: `?action_type=invoice.sent&target_type=invoice&user_uuid=xxx&date_from=2026-05-01`

**Success Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "uuid": "alog_01J2...",
      "action_type": "invoice.sent",
      "target_type": "invoice",
      "target_uuid": "inv_01J2...",
      "actor": { "uuid": "usr_admin_01J2...", "name": "Sagar Patel", "role": "owner" },
      "impersonator": null,
      "old_values": { "status": "draft" },
      "new_values": { "status": "sent" },
      "ip_address": "103.21.xx.xx",
      "created_at": "2026-05-03T14:00:00Z"
    }
  ],
  "meta": { "current_page": 1, "per_page": 50, "total": 1842 }
}
```

---

#### `GET /dashboard/summary`
Get tenant dashboard KPI summary.

**Query Params**: `?period=today | this_week | this_month | custom&date_from=xxx&date_to=xxx`

**Success Response `200`**
```json
{
  "success": true,
  "data": {
    "period": "this_month",
    "jobs": {
      "total": 94,
      "in_progress": 8,
      "completed": 82,
      "cancelled": 4,
      "avg_completion_hours": 3.8
    },
    "revenue": {
      "total_billed": 487500.00,
      "total_collected": 453200.00,
      "outstanding": 34300.00,
      "avg_job_value": 5186.00
    },
    "customers": {
      "new_this_period": 14,
      "returning": 80,
      "total_active": 387
    },
    "technicians": {
      "avg_jobs_per_day": 3.2,
      "top_performer": { "name": "Rahul Shah", "jobs_completed": 38, "avg_rating": 4.8 }
    },
    "inventory": {
      "low_stock_items": 3,
      "out_of_stock_items": 0
    }
  }
}
```

---

## 17. WebSocket Events Reference

All WebSocket channels use **Laravel Reverb** (Pusher-compatible). Staff dashboard subscribes via `pusher-js`; Flutter app subscribes via `pusher_channels_flutter`.

### Channel: `private-tenant.{tenant_uuid}`
> Scope: All staff in a garage tenant

| Event | Payload Summary | Trigger |
|-------|----------------|---------|
| `job.status.updated` | `{ job_uuid, job_number, new_status, customer_name }` | Job status transition |
| `job.task.added` | `{ job_uuid, task_uuid, task_name, requires_approval }` | New task added to job |
| `job.task.approved` | `{ job_uuid, task_uuid, decision }` | Customer approves/rejects task |
| `job.assigned` | `{ job_uuid, technician_uuid, bay_uuid }` | Job assignment changed |
| `inventory.low_stock` | `{ item_uuid, sku, stock_on_hand, threshold }` | Stock drops below threshold |
| `appointment.booked` | `{ appointment_uuid, appointment_number, customer_name, scheduled_date }` | New appointment created |
| `payment.received` | `{ invoice_uuid, amount, balance_due, invoice_status }` | Payment recorded/webhook |

**Example Payload**
```json
{
  "event": "job.status.updated",
  "data": {
    "job_uuid": "job_01J2...",
    "job_number": "JOB-2026-0042",
    "previous_status": "in_progress",
    "new_status": "ready_for_delivery",
    "updated_by": { "uuid": "usr_01J2...", "name": "Rahul Shah" },
    "updated_at": "2026-05-03T13:45:00Z"
  }
}
```

---

### Channel: `private-customer.{customer_uuid}`
> Scope: Individual customer (Flutter app)

| Event | Payload Summary | Trigger |
|-------|----------------|---------|
| `job.status.updated` | `{ job_uuid, status_label, estimated_completion }` | Any job status change |
| `job.task.approval_required` | `{ job_uuid, task_uuid, task_name, estimated_cost }` | Task needing customer approval |
| `job.ready_for_pickup` | `{ job_uuid, garage_name, garage_phone }` | Job status = ready_for_delivery |
| `odometer.confirmation_needed` | `{ vehicle_uuid, estimated_km, last_confirmed_km }` | GPS delta detected |
| `service.reminder` | `{ vehicle_uuid, due_km, due_date, urgency }` | Cron-triggered service due |
| `appointment.confirmed` | `{ appointment_uuid, scheduled_date, start_time }` | Appointment confirmed by staff |

---

## 18. Error Reference

### HTTP Status Codes

| Code | Meaning | Common Causes |
|------|---------|---------------|
| `200` | OK | Successful GET, PUT, PATCH |
| `201` | Created | Successful POST |
| `400` | Bad Request | Malformed JSON, missing required fields |
| `401` | Unauthorized | Invalid/expired token, wrong PIN |
| `403` | Forbidden | Insufficient role/permission for action |
| `404` | Not Found | Resource UUID does not exist or is soft-deleted |
| `409` | Conflict | Duplicate (customer phone, job number), slot collision |
| `422` | Unprocessable Entity | Validation failed (detailed `details` object returned) |
| `429` | Too Many Requests | OTP rate limit, API throttle. Always includes `Retry-After` header — see [Rate Limiting & Retry Behaviour](#rate-limiting--retry-behaviour) |Z
| `500` | Server Error | Unexpected server fault |

### Application Error Codes

| Error Code | Description |
|------------|-------------|
| `INVALID_CREDENTIALS` | Wrong email/PIN combination |
| `ACCOUNT_LOCKED` | Too many failed PIN attempts |
| `SUBSCRIPTION_EXPIRED` | Tenant subscription lapsed — no access |
| `PLAN_LIMIT_REACHED` | Max users/locations for plan exceeded |
| `INVALID_OTP` | OTP incorrect or expired |
| `OTP_RATE_LIMITED` | Too many OTP requests for this phone |
| `RATE_LIMITED` | Generic rate limit hit on authenticated endpoints; `Retry-After` header always present |
| `VALIDATION_ERROR` | One or more fields failed validation |
| `DUPLICATE_RESOURCE` | Entity with unique constraint already exists |
| `SLOT_CONFLICT` | Appointment time overlaps with existing booking |
| `DOCUMENT_EXPIRED` | Vehicle compliance document expired — blocks intake |
| `INSUFFICIENT_STOCK` | Part quantity not available in inventory |
| `INVOICE_IMMUTABLE` | Invoice already sent; edit via credit note only |
| `TASK_APPROVAL_REQUIRED` | Job cannot proceed — pending customer approval |
| `TENANT_SUSPENDED` | Garage account suspended — contact support |
| `GPS_CONSENT_REQUIRED` | GPS tracking action requires customer opt-in |

### Validation Error Example
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The given data was invalid.",
    "details": {
      "phone_primary": ["The phone primary field is required."],
      "registration_number": [
        "The registration number must be a valid Indian vehicle registration.",
        "The registration number has already been taken."
      ],
      "scheduled_date": ["The scheduled date must be a date after today."]
    }
  }
}
```

---

## Appendix A — Route Summary Index

| Domain | Method | Route | Auth |
|--------|--------|-------|------|
| **Auth** | POST | `/auth/staff/login` | Public |
| | POST | `/auth/staff/logout` | Staff |
| | POST | `/auth/staff/pin/change` | Staff |
| | POST | `/auth/customer/otp/request` | Public |
| | POST | `/auth/customer/otp/verify` | Public |
| **Tenant** | GET | `/tenant/profile` | Staff |
| | PUT | `/tenant/profile` | Owner |
| | POST | `/platform/tenants` | Platform Admin |
| | GET | `/platform/subscription-plans` | Public |
| | POST | `/tenant/subscription/upgrade` | Owner |
| **Users** | GET | `/users` | Staff |
| | POST | `/users` | Owner |
| | GET/PUT/DELETE | `/users/{uuid}` | Owner |
| | GET | `/skills` | Staff |
| **Customers** | GET/POST | `/customers` | Staff |
| | GET/PUT | `/customers/{uuid}` | Staff |
| **Vehicles** | GET/POST | `/customers/{uuid}/vehicles` | Staff |
| | PUT | `/vehicles/{uuid}` | Staff |
| | GET/POST | `/vehicles/{uuid}/documents` | Staff |
| | GET/POST | `/vehicles/{uuid}/mileage-logs` | Staff |
| **Service Ops** | GET/POST | `/service-categories` | Staff |
| | GET/POST | `/service-categories/{uuid}/items` | Staff |
| | GET | `/service-bays` | Staff |
| | PUT | `/service-bays/{uuid}/status` | Staff |
| **Jobs** | GET/POST | `/jobs` | Staff |
| | GET | `/jobs/{uuid}` | Staff |
| | PUT | `/jobs/{uuid}/status` | Staff |
| | POST | `/jobs/{uuid}/tasks` | Staff |
| | PUT | `/jobs/{uuid}/tasks/{uuid}/status` | Staff |
| | POST | `/jobs/{uuid}/estimate/send` | Staff |
| | POST | `/jobs/{uuid}/estimate/approve` | Customer |
| **Inspection** | GET | `/inspection-templates` | Staff |
| | GET/POST | `/jobs/{uuid}/inspection` | Staff |
| | POST | `/jobs/{uuid}/inspection/upload-media` | Staff |
| **Inventory** | GET/POST | `/inventory` | Staff |
| | PUT | `/inventory/{uuid}/stock-adjust` | Staff |
| | GET | `/vendors` | Staff |
| | POST | `/purchase-orders` | Staff |
| | PUT | `/purchase-orders/{uuid}/receive` | Staff |
| **Billing** | GET/POST | `/jobs/{uuid}/invoice` | Staff |
| | POST | `/invoices/{uuid}/send` | Staff |
| | POST | `/invoices/{uuid}/payments` | Staff |
| | POST | `/invoices/{uuid}/payments/gateway/initiate` | Staff |
| | POST | `/webhooks/payments/{gateway}` | Public (HMAC) |
| | GET | `/tax-rates` | Staff |
| | GET | `/payment-methods` | Staff |
| **Appointments** | GET/POST | `/appointments` | Staff |
| | PUT | `/appointments/{uuid}/check-in` | Staff |
| | GET | `/appointments/availability` | Staff/Customer |
| **Notifications** | GET | `/notification-templates` | Owner |
| | PUT | `/notification-templates/{uuid}` | Owner |
| | GET | `/notifications` | Staff |
| **Loyalty** | GET/PUT | `/loyalty-program` | Owner |
| | GET | `/customers/{uuid}/loyalty` | Staff |
| | POST | `/customers/{uuid}/loyalty/adjust` | Owner |
| **Feedback** | POST | `/jobs/{uuid}/feedback/request` | Staff |
| | POST | `/feedback/{uuid}/submit` | Customer (token) |
| | GET | `/feedback` | Staff |
| | POST | `/feedback/{uuid}/respond` | Staff |
| **Customer App** | GET | `/customer/profile` | Customer |
| | GET | `/customer/vehicles` | Customer |
| | GET | `/customer/jobs` | Customer |
| | GET | `/customer/jobs/{uuid}/progress` | Customer |
| | POST | `/customer/jobs/{uuid}/tasks/{uuid}/approve` | Customer |
| | GET | `/customer/vehicles/{uuid}/service-reminders` | Customer |
| | PUT | `/customer/vehicles/{uuid}/service-preferences` | Customer |
| | POST | `/customer/vehicles/{uuid}/odometer/confirm` | Customer |
| | POST | `/customer/sessions/register` | Customer |
| | POST | `/customer/engagement/track` | Customer |
| | GET/POST | `/customer/appointments` | Customer |
| **Audit** | GET | `/audit-logs` | Owner/Admin |
| | GET | `/dashboard/summary` | Staff |

---

*GarageFlow API Specification v1.0.0 — Generated from PRD v1.0.0*  
*Stack: Laravel 11 + Sanctum + OpenAPI 3.0 | Auto-generates Zod (React) + Dart models (Flutter) on CI*
