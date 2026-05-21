# GarageFlow Design System v1.0
> Paste the **Master System Block** into every Claude design prompt. The system is designed to be AI-readable — structured constraints that produce consistent, on-brand output without back-and-forth.

---

## Master System Block (Copy-Paste into Claude Prompts)

```
Design System: GarageFlow SaaS — Garage Operations Platform

AESTHETIC DIRECTION:
Calm, composed, minimal. Like a premium clinic or a Swiss watch dial.
No excitement, no noise — just clarity and trust.

TYPOGRAPHY:
- Font: DM Sans (UI), DM Mono (codes, numbers, IDs)
- Weights: 300 (hero), 400 (body), 500 (labels/bold) — never 600+
- Heading: letter-spacing -0.02em, weight 300
- Labels: letter-spacing +0.06em, uppercase, weight 500

COLOR PALETTE:
- Background: #F7F9FB (page), #FFFFFF (surface), #EEF2F6 (dividers)
- Primary action: Sky-600 #0A7DBF, hover Sky-800 #065E91
- Text primary: #0A0E14, secondary: #566076, muted: #8898AA
- Border: #DDE5EC (default), #B8C5D0 (hover/focus)
- Success/Delivered: Teal #138878, Sage #1E7F3C
- Warning/Pending: Amber #C07A08 on #FEF7EC
- Error/Expired: Rose #C01E1E on #FEF0F0
- Loyalty/Premium: Violet #4F46C8 on #F0EFFE

BORDER RADIUS: 4px(micro) · 6px(badge) · 10px(button/input) · 16px(card) · 24px(modal)
SPACING: 4px base grid. Card padding: 20–24px. Page padding: 48px.
BORDER: Always 0.5px, never 1px+ except focus ring (3px sky glow).
SHADOW: Feather-light. sm: 0 1px 3px rgba(10,14,20,.06). md: 0 4px 12px rgba(10,14,20,.08)

MOTION — THE FEATHER PRINCIPLE:
Every animation settles like a feather — weightless, unhurried.
- Card reveal: translateY(8px→0) + opacity · 380ms · cubic-bezier(0.16,1,0.3,1)
- Modal open: scale(0.97→1) + translateY(12px→0) · 240ms · cubic-bezier(0.25,1,0.5,1)
- Button press: scale(0.97) · 80ms · ease-in, release 140ms · cubic-bezier(0.34,1.56,0.64,1)
- Status change: opacity + scale(0.85→1) · 140ms · spring
- Page transition: opacity 0→1 + translateY(6px→0) · 380ms · ease-feather
- List stagger: 30ms delay per item, max 8 items
- NEVER: bounce on data cards, loops on loaded content, animations >600ms

JOB STATUS COLORS:
draft→neutral · intake_inspection→neutral · estimate_pending→amber
estimate_approved→sky · in_progress→sky · qc_pending→teal
ready_for_delivery→teal · delivered→sage · cancelled→rose · on_hold→slate

COMPONENT RULES:
- Job card: white surface, 0.5px border, 16px radius, 2px progress bar at bottom
- Stat card: no shadow, muted label above, light-weight number below
- Buttons: 36px height, 10px radius, 500 weight — no uppercase labels
- Input: 36px height, 10px radius, 0.5px border, focus=sky glow 3px
- Badge: pill shape, always has colored dot + semantic color pair
- Sidebar: Slate-900 background, 240px wide, sky-600 active item
- Tables: 0.5px row dividers, no heavy borders, sticky DM Mono header

DO:
✓ Light surfaces with ink-scale text
✓ Sky family for every interactive element
✓ Teal for GPS/delivery/completion flows
✓ Amber for anything needing attention
✓ Generous whitespace — never crowd the UI
✓ DM Mono for all alphanumeric codes and amounts in tables
✓ Skeleton loading states before data arrives
✓ Compound motion (transform + opacity together always)

DO NOT:
✗ Dark backgrounds except sidebar and hero sections
✗ Gradients on interactive components
✗ Bold above 500 weight
✗ Colorful icon sets (use simple outline SVGs, ink-3 color)
✗ Toast notifications with heavy colored backgrounds
✗ Animations without transform+opacity pairing
✗ Border-radius below 4px on any visible element
```

---

## Color System

### Neutral Ink Scale
| Token | Hex | Usage |
|-------|-----|-------|
| ink-0 | #0A0E14 | Primary text, headings |
| ink-1 | #1C2230 | Body text |
| ink-2 | #364052 | Secondary body text |
| ink-3 | #566076 | Muted text |
| ink-4 | #8898AA | Placeholder, captions |
| ink-5 | #B8C5D0 | Disabled text |
| ink-6 | #DDE5EC | Default border |
| ink-7 | #EEF2F6 | Hover border, dividers |
| ink-8 | #F7F9FB | Page background |
| ink-9 | #FFFFFF | Card/surface background |

### Brand Color Ramps

#### Sky — Primary Actions
| Stop | Hex | Usage |
|------|-----|-------|
| 50 | #E8F4FD | Focus ring bg, hover surface |
| 100 | #BEE0F8 | Highlight |
| 200 | #90C8F2 | Soft accent |
| 400 | #2BB0ED | Progress bar fill |
| 600 | #0A7DBF | **Primary button, link, active state** |
| 800 | #065E91 | Button hover, dark link |
| 900 | #033D61 | High-contrast, dark sidebar accent |

#### Teal — Completion & GPS
| Stop | Hex | Usage |
|------|-----|-------|
| 50 | #EBF7F5 | Tag background |
| 400 | #26B8A8 | Progress fill (delivery) |
| 600 | #138878 | **Delivered badge, GPS confirmed** |
| 800 | #076358 | Text on teal bg |

#### Sage — Positive / Paid
| Stop | Hex | Usage |
|------|-----|-------|
| 50 | #EBF5EE | Success surface |
| 400 | #3BAD5B | Check icons |
| 600 | #1E7F3C | **Paid, approved, loyalty earned** |

#### Amber — Attention / Warning
| Stop | Hex | Usage |
|------|-----|-------|
| 50 | #FEF7EC | Warning background |
| 400 | #F0A018 | Low stock dot |
| 600 | #C07A08 | **Pending approval, estimate awaiting** |

#### Rose — Error / Danger
| Stop | Hex | Usage |
|------|-----|-------|
| 50 | #FEF0F0 | Error surface |
| 400 | #EF4444 | Delete icon |
| 600 | #C01E1E | **Overdue invoice, expired document** |

#### Violet — Loyalty & Premium
| Stop | Hex | Usage |
|------|-----|-------|
| 50 | #F0EFFE | Loyalty surface |
| 400 | #7C71F0 | Points progress |
| 600 | #4F46C8 | **Loyalty program, platform admin** |

#### Slate — Navigation & Structure
| Stop | Hex | Usage |
|------|-----|-------|
| 900 | #102A43 | **Sidebar background** |
| 800 | #243B53 | Sidebar hover |
| 600 | #486581 | Sidebar muted text |

---

### Job Status → Color Map
| Status | Badge Color | Dot |
|--------|-------------|-----|
| draft | neutral (ink-7) | ink-4 |
| intake_inspection | neutral | ink-4 |
| estimate_pending | amber-50 / amber-800 | amber-400 |
| estimate_approved | sky-50 / sky-800 | sky-400 |
| in_progress | sky-50 / sky-800 | sky-600 |
| qc_pending | teal-50 / teal-800 | teal-400 |
| ready_for_delivery | teal-50 / teal-800 | teal-600 |
| delivered | sage-50 / sage-800 | sage-400 |
| cancelled | rose-50 / rose-800 | rose-400 |
| on_hold | slate-100 / slate-800 | slate-400 |

---

## Typography

### Font Stack
```css
/* Primary UI */
font-family: 'DM Sans', -apple-system, sans-serif;

/* Codes, IDs, amounts */
font-family: 'DM Mono', 'Cascadia Code', monospace;
```

### Type Scale
| Role | Size | Weight | Tracking | Line Height | Usage |
|------|------|--------|----------|-------------|-------|
| Display | 36–42px | 300 | -0.025em | 1.15 | Page headers, hero |
| Title | 24px | 400 | -0.015em | 1.3 | Section heads |
| Heading | 18px | 500 | -0.01em | 1.4 | Card titles |
| Subheading | 15px | 500 | 0 | 1.5 | Sidebar items |
| Body | 14px | 400 | 0 | 1.7 | Paragraphs, descriptions |
| Small | 13px | 400 | 0 | 1.6 | Table rows, line items |
| Label | 11px | 500 | +0.06em | 1.4 | Section labels, table headers |
| Micro | 10px | 500 | +0.08em | 1.3 | Timestamps, meta |
| Mono | 13px | 400 | 0 | 1.5 | JOB-xxx, INV-xxx, amounts |

### Rules
- **Never use font-weight above 500** in the UI
- Numeric displays (KPIs, totals): `font-variant-numeric: tabular-nums`
- Job numbers, VINs, invoice numbers: DM Mono always
- Amounts in tables: DM Mono, right-aligned
- Amounts in cards (large KPI): DM Sans, weight 300

---

## Spacing

### Scale (4px base grid)
| Token | Value | Usage |
|-------|-------|-------|
| space-1 | 4px | Icon–label gap |
| space-2 | 8px | Badge padding, tight gap |
| space-3 | 12px | List item gap, form stack |
| space-4 | 16px | Section gap, button padding |
| space-5 | 20px | Card padding (compact) |
| space-6 | 24px | Card padding (standard) |
| space-8 | 32px | Between card groups |
| space-10 | 40px | Section bottom margin |
| space-12 | 48px | Page horizontal padding |
| space-16 | 64px | Hero section padding |

### Border Radius
| Token | Value | Usage |
|-------|-------|-------|
| r-xs | 4px | Code chips, progress bars, tooltips |
| r-sm | 6px | Badges, compact buttons |
| r-md | 10px | Buttons, inputs, dropdowns |
| r-lg | 16px | Cards, modals, panels |
| r-xl | 24px | Full-page modals, hero sections |
| r-full | 9999px | Pills, avatars, toggle switches |

### Shadow Scale
```css
--shadow-sm: 0 1px 3px rgba(10,14,20,0.06), 0 1px 2px rgba(10,14,20,0.04);
--shadow-md: 0 4px 12px rgba(10,14,20,0.08), 0 2px 4px rgba(10,14,20,0.04);
--shadow-lg: 0 8px 32px rgba(10,14,20,0.10), 0 4px 8px rgba(10,14,20,0.05);
--shadow-focus: 0 0 0 3px rgba(43,176,237,0.25);
```
- **Flat (default)**: border only, no shadow
- **sm**: Used on buttons, active table rows
- **md**: Card on hover, elevated dropdowns
- **lg**: Modals, popovers, command palette
- **focus**: All interactive element focus states

---

## Motion System — The Feather Principle

> Every animation should feel like a feather settling — unhurried, weightless, confident. Motion earns trust. It never competes for attention.

### Easing Curves
```css
--ease-feather:      cubic-bezier(0.16, 1, 0.3, 1);    /* Card reveals, page loads */
--ease-out-quart:    cubic-bezier(0.25, 1, 0.5, 1);    /* Modal open, hover states */
--ease-spring:       cubic-bezier(0.34, 1.56, 0.64, 1); /* Button release, badge pop */
--ease-in-out-quart: cubic-bezier(0.77, 0, 0.18, 1);   /* Drawer, panel slide */
```

### Duration Scale
```css
--dur-instant:  80ms;   /* Checkbox, radio, icon swap */
--dur-fast:     140ms;  /* Button hover, tooltip, badge */
--dur-normal:   240ms;  /* Modal, dropdown, tab switch */
--dur-slow:     380ms;  /* Card reveal, page transition */
--dur-glacial:  600ms;  /* Hero entrance, onboarding */
```

### Animation Recipes
```css
/* Card reveal */
@keyframes cardReveal {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}
animation: cardReveal 380ms cubic-bezier(0.16, 1, 0.3, 1) both;

/* Modal enter */
@keyframes modalEnter {
  from { opacity: 0; transform: translateY(12px) scale(0.97); }
  to   { opacity: 1; transform: translateY(0) scale(1); }
}
animation: modalEnter 240ms cubic-bezier(0.25, 1, 0.5, 1) both;

/* Notification slide in */
@keyframes notifSlide {
  from { opacity: 0; transform: translateX(120%); }
  to   { opacity: 1; transform: translateX(0); }
}
animation: notifSlide 380ms cubic-bezier(0.16, 1, 0.3, 1) both;

/* List stagger */
.list-item:nth-child(1) { animation-delay: 0ms; }
.list-item:nth-child(2) { animation-delay: 30ms; }
.list-item:nth-child(3) { animation-delay: 60ms; }
/* Cap at 8 items × 30ms = 240ms max */

/* Button interaction */
.btn:active { transform: scale(0.97); transition: transform 80ms ease-in; }
.btn:not(:active) { transition: transform 140ms cubic-bezier(0.34,1.56,0.64,1); }

/* Status badge pop (only on change) */
@keyframes badgePop {
  from { opacity: 0; transform: scale(0.85); }
  to   { opacity: 1; transform: scale(1); }
}
.badge-new { animation: badgePop 140ms cubic-bezier(0.34,1.56,0.64,1) both; }

/* Skeleton shimmer */
@keyframes shimmer {
  from { background-position: 200% center; }
  to   { background-position: -200% center; }
}
.skeleton {
  background: linear-gradient(90deg, #EEF2F6 25%, #F7F9FB 50%, #EEF2F6 75%);
  background-size: 200% auto;
  animation: shimmer 1.8s linear infinite;
}

/* Progress bar fill */
.progress-fill {
  transition: width 600ms cubic-bezier(0.16, 1, 0.3, 1);
  transition-delay: 100ms;
}
```

### Flutter Equivalents
```dart
// ease-feather
Curves.easeOutExpo  // closest match

// ease-out-quart
Curves.easeOut

// ease-spring
const SpringDescription(mass: 1, stiffness: 200, damping: 20)

// Standard durations
const kInstant  = Duration(milliseconds: 80);
const kFast     = Duration(milliseconds: 140);
const kNormal   = Duration(milliseconds: 240);
const kSlow     = Duration(milliseconds: 380);
const kGlacial  = Duration(milliseconds: 600);

// Card reveal
AnimatedOpacity + SlideTransition, duration: kSlow, curve: Curves.easeOutExpo

// List stagger
Future.delayed(Duration(milliseconds: index * 30), () => setState(...))
```

### Animation Rules
| Rule | Detail |
|------|--------|
| Always pair | Transform + opacity. Never animate color alone. |
| Max stagger | 8 items × 30ms. Beyond 8 → batch reveal |
| Reduced motion | `@media (prefers-reduced-motion: reduce)` → disable all |
| No loops | No infinite animations on loaded content (only skeletons/spinners) |
| Performance | `will-change: transform, opacity` on animated elements |
| No bounce | `ease-spring` only for micro-interactions (button release, badge pop) — never for cards or navigation |

---

## Component Specifications

### Button
```css
/* Base */
height: 36px;
padding: 0 16px;
border-radius: 10px;       /* r-md */
font-size: 13px;
font-weight: 500;
font-family: 'DM Sans';
transition: all 140ms cubic-bezier(0.25, 1, 0.5, 1);

/* Primary */
background: #0A7DBF;       /* sky-600 */
color: #ffffff;
box-shadow: var(--shadow-sm);

/* Secondary */
background: #ffffff;
border: 0.5px solid #8898AA;  /* ink-4 */
color: #364052;               /* ink-2 */

/* Ghost */
background: transparent;
color: #0A7DBF;               /* sky-600 */

/* Sizes */
.btn-sm: height 28px, font-size 12px, padding 0 10px, radius 6px
.btn-lg: height 44px, font-size 14px, padding 0 24px, radius 16px
```

### Input Field
```css
height: 36px;
padding: 0 12px;
border: 0.5px solid #DDE5EC;   /* ink-6 */
border-radius: 10px;            /* r-md */
font-size: 13px;
font-family: 'DM Sans';
background: #ffffff;
color: #0A0E14;

/* Focus */
border-color: #2BB0ED;          /* sky-400 */
box-shadow: 0 0 0 3px rgba(43,176,237,0.25);
outline: none;

/* Error */
border-color: #EF4444;          /* rose-400 */
box-shadow: 0 0 0 3px rgba(239,68,68,0.15);

/* Hint text */
font-size: 11px;
color: #8898AA;                 /* ink-4 */
margin-top: 4px;
```

### Job Card
```css
background: #ffffff;
border: 0.5px solid #DDE5EC;
border-radius: 16px;         /* r-lg */
padding: 16px 20px;

/* Hover */
box-shadow: 0 4px 12px rgba(10,14,20,0.08);
transform: translateY(-2px);
border-color: #B8C5D0;       /* ink-5 */
transition: all 240ms cubic-bezier(0.16, 1, 0.3, 1);

/* Progress bar at bottom */
height: 3px;
background: linear-gradient(90deg, #2BB0ED, #26B8A8);  /* sky → teal */
border-radius: 2px;
```

### Badge / Status Chip
```css
display: inline-flex;
align-items: center;
gap: 4px;
padding: 3px 8px;
border-radius: 9999px;      /* full pill */
font-size: 11px;
font-weight: 500;

/* Dot indicator */
.dot { width: 5px; height: 5px; border-radius: 50%; }

/* Color pairs (bg / text / dot) */
neutral:  #EEF2F6 / #566076 / #8898AA
info:     #E8F4FD / #065E91 / #2BB0ED
warning:  #FEF7EC / #8A5602 / #F0A018
success:  #EBF5EE / #0E5C26 / #3BAD5B
danger:   #FEF0F0 / #8A1010 / #EF4444
teal:     #EBF7F5 / #076358 / #26B8A8
violet:   #F0EFFE / #312E8A / #7C71F0
```

### Stat / KPI Card
```css
background: #ffffff;
border: 0.5px solid #DDE5EC;
border-radius: 16px;
padding: 20px;

/* Label */
font-size: 11px; font-weight: 500;
letter-spacing: 0.04em; text-transform: uppercase;
color: #8898AA;              /* ink-4 */

/* Value */
font-size: 28px; font-weight: 300;
letter-spacing: -0.02em;
color: #0A0E14;
font-variant-numeric: tabular-nums;

/* Delta */
font-size: 12px; font-weight: 500;
.up { color: #1E7F3C; }      /* sage-600 */
.down { color: #C01E1E; }    /* rose-600 */
```

### Sidebar Navigation
```css
width: 240px;
background: #102A43;         /* slate-900 */
padding: 20px;
height: 100vh;

/* Nav item */
padding: 8px 10px;
border-radius: 6px;          /* r-sm */
font-size: 13px;
color: rgba(255,255,255,0.5);
transition: all 140ms ease;

/* Active */
background: #0A7DBF;         /* sky-600 */
color: #ffffff;

/* Hover */
background: rgba(255,255,255,0.06);
color: rgba(255,255,255,0.8);
```

### Data Table
```css
/* Header row */
font-size: 11px; font-weight: 500;
letter-spacing: 0.05em; text-transform: uppercase;
color: #8898AA;
padding: 8px 12px;
border-bottom: 0.5px solid #DDE5EC;
position: sticky; top: 0;
background: #ffffff;

/* Body row */
font-size: 13px;
padding: 12px;
border-bottom: 0.5px solid #EEF2F6;   /* ink-7 */
transition: background 80ms ease;

/* Row hover */
background: #F7F9FB;         /* ink-8 */

/* Monospace cells (job numbers, amounts) */
font-family: 'DM Mono';
```

---

## Layout Patterns

### Web Dashboard
- Left sidebar: 240px fixed, Slate-900 bg
- Main content: flex-1, ink-8 bg, 48px horizontal padding
- Max content width: 1280px
- Top bar: 52px height, white, 0.5px bottom border
- Content grid: 4-col stats → full-width table/list

### Job Detail Page
- Layout: 65% main / 35% sidebar (two-column)
- Main: job header → task list → inspection gallery → audit log
- Sidebar: billing summary → customer card → loyalty widget → quick actions
- Mobile: stacked single column, CTA sticky at bottom

### Flutter Customer App
- Bottom nav: 5 tabs (Home, My Cars, Jobs, Appointments, Profile)
- Content: single column, 16px horizontal padding
- Job progress: large vehicle card → task timeline → sticky approve/reject bar
- Safe area: respect iOS/Android system insets

### Modal
```css
/* Overlay */
background: rgba(10,14,20,0.4);
backdrop-filter: blur(4px);

/* Modal panel */
background: #ffffff;
border-radius: 24px;           /* r-xl */
box-shadow: var(--shadow-lg);
max-width: 560px; width: 100%;
padding: 32px;

/* Header */
font-size: 18px; font-weight: 500;
border-bottom: 0.5px solid #EEF2F6;
padding-bottom: 16px; margin-bottom: 24px;

/* Footer */
display: flex; justify-content: flex-end; gap: 8px;
border-top: 0.5px solid #EEF2F6;
padding-top: 20px; margin-top: 24px;
```

---

## Screen-Specific Prompt Suffixes

Append these to the Master System Block when prompting Claude for specific screens:

### Job Dashboard
```
Screen: Job Management Dashboard
Layout: Fixed sidebar (use system sidebar spec) + main content.
Show: 4 KPI stat cards at top (Today's jobs, Revenue MTD, Pending approvals, Low stock alerts).
Then: Filterable job list table — columns: Job#(mono), Customer, Vehicle, Status badge, Technician avatar+name, Bay, Estimated completion, Actions.
Filter panel: Status multiselect, Date range, Technician, Priority.
Empty state: "No jobs match your filters" with clear filters button.
No charts on this view.
```

### Job Detail
```
Screen: Job Detail Page
Layout: 65/35 two-column.
Left column (65%): Job header card (job number, vehicle, customer, status badge, priority chip) → Task list (each task: checkbox, name, assigned tech, status badge, price, expand arrow) → Estimate section (itemized, approval CTA) → Inspection photo grid (2 per row, phase tabs) → Audit timeline.
Right column (35%): Billing summary card (subtotal/tax/total, payment status, pay button) → Customer card (name, phone, loyalty points, visit count) → Vehicle compliance alerts → Quick actions (WhatsApp, Call, Print invoice).
```

### Customer App — Job Progress
```
Screen: Customer App — Job Progress (Flutter, 375px width)
Top: Large vehicle illustration card (registration plate, make/model, color chip).
Below: Current status indicator with icon and label (large, centered).
Timeline: Vertical stepper — each step has icon, label, time, optional task detail chip.
Pending approval: Highlighted task card with estimated cost, Approve/Decline buttons, digital signature field.
Technician chip: Avatar circle, name, "your technician" label.
Sticky bottom CTA: "Approve All Pending" primary button (if any pending).
WhatsApp chat button floating right.
```

### Invoice Screen
```
Screen: Invoice / Bill View
Full-width white card (no sidebar).
Header: Garage name (large) + logo placeholder left, Invoice number (DM Mono) + issued date + status badge right.
Customer block: Name, phone, vehicle registration, job number.
Line items table: Name, Qty, Rate, Tax%, Amount — right-aligned amounts in DM Mono. Alternating ink-8 rows.
Totals block: Right-aligned — Subtotal, GST (CGST + SGST breakdown), Discount, Grand Total (larger, sky-600).
Footer: Loyalty points earned + QR code for payment + Download PDF button + Share on WhatsApp button.
Watermark "PAID" in sage-200 diagonal if status=paid.
```

### Loyalty Widget
```
Widget: Customer Loyalty Points (embeds in job detail sidebar and customer app profile)
Color family: Violet throughout.
Top: "Patel Rewards" program name + current balance (large, weight 300).
Progress bar: Thin (3px), violet-400, shows progress to next tier with milestone label.
Expiry notice: Amber chip "350 pts expiring Aug 2026" if applicable.
Recent transactions: 3 rows — type dot (earned/redeemed), description, points (+/-), date — DM Mono for amounts.
Redeem CTA button: Ghost violet style with "Redeem points" label.
```

---

## CSS Variables — Full Token Sheet

```css
:root {
  /* Fonts */
  --font-ui:   'DM Sans', -apple-system, sans-serif;
  --font-mono: 'DM Mono', 'Cascadia Code', monospace;

  /* Ink scale */
  --ink-0: #0A0E14;
  --ink-1: #1C2230;
  --ink-2: #364052;
  --ink-3: #566076;
  --ink-4: #8898AA;
  --ink-5: #B8C5D0;
  --ink-6: #DDE5EC;
  --ink-7: #EEF2F6;
  --ink-8: #F7F9FB;
  --ink-9: #FFFFFF;

  /* Sky (primary) */
  --sky-50:  #E8F4FD; --sky-100: #BEE0F8; --sky-200: #90C8F2;
  --sky-400: #2BB0ED; --sky-600: #0A7DBF; --sky-800: #065E91; --sky-900: #033D61;

  /* Teal (delivery/GPS) */
  --teal-50:  #EBF7F5; --teal-100: #C2ECE6; --teal-200: #93DDD3;
  --teal-400: #26B8A8; --teal-600: #138878; --teal-800: #076358; --teal-900: #034239;

  /* Sage (success/paid) */
  --sage-50:  #EBF5EE; --sage-100: #C3E6CA; --sage-200: #95D3A2;
  --sage-400: #3BAD5B; --sage-600: #1E7F3C; --sage-800: #0E5C26;

  /* Amber (warning/pending) */
  --amber-50:  #FEF7EC; --amber-100: #FCE4B0; --amber-200: #F8C96C;
  --amber-400: #F0A018; --amber-600: #C07A08; --amber-800: #8A5602;

  /* Rose (error/danger) */
  --rose-50:  #FEF0F0; --rose-100: #FBCBCB; --rose-200: #F79898;
  --rose-400: #EF4444; --rose-600: #C01E1E; --rose-800: #8A1010;

  /* Violet (loyalty/premium) */
  --violet-50:  #F0EFFE; --violet-100: #D4D0FC; --violet-200: #B1ABF8;
  --violet-400: #7C71F0; --violet-600: #4F46C8; --violet-800: #312E8A;

  /* Slate (nav/structure) */
  --slate-50:  #F0F4F8; --slate-100: #D9E2EC; --slate-200: #BCCCDC;
  --slate-400: #829AB1; --slate-600: #486581; --slate-800: #243B53; --slate-900: #102A43;

  /* Radius */
  --r-xs:   4px;
  --r-sm:   6px;
  --r-md:   10px;
  --r-lg:   16px;
  --r-xl:   24px;
  --r-full: 9999px;

  /* Spacing */
  --space-1:  4px;   --space-2:  8px;   --space-3:  12px;
  --space-4:  16px;  --space-5:  20px;  --space-6:  24px;
  --space-8:  32px;  --space-10: 40px;  --space-12: 48px;
  --space-16: 64px;

  /* Shadow */
  --shadow-sm:    0 1px 3px rgba(10,14,20,0.06), 0 1px 2px rgba(10,14,20,0.04);
  --shadow-md:    0 4px 12px rgba(10,14,20,0.08), 0 2px 4px rgba(10,14,20,0.04);
  --shadow-lg:    0 8px 32px rgba(10,14,20,0.10), 0 4px 8px rgba(10,14,20,0.05);
  --shadow-focus: 0 0 0 3px rgba(43,176,237,0.25);

  /* Easing */
  --ease-feather:      cubic-bezier(0.16, 1, 0.3, 1);
  --ease-out-quart:    cubic-bezier(0.25, 1, 0.5, 1);
  --ease-spring:       cubic-bezier(0.34, 1.56, 0.64, 1);
  --ease-in-out-quart: cubic-bezier(0.77, 0, 0.18, 1);

  /* Duration */
  --dur-instant: 80ms;
  --dur-fast:    140ms;
  --dur-normal:  240ms;
  --dur-slow:    380ms;
  --dur-glacial: 600ms;
}
```

---

*GarageFlow Design System v1.0.0 — Maintained by Akshara Technologies*
*For use with Claude AI design generation, React 18 (Inertia.js), and Flutter 3.x*