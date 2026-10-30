# Field test 2026-10-29 — offline driver day

Input for the ODD plan. A Moto G6 was driven over adb against the local `marilin-web` server
(`adb reverse tcp:8000 tcp:80`, `API_BASE_URL=http://localhost:8000/api/v1`). Offline meant
Wi-Fi and mobile data off and the reverse port removed. Backend contract from the `marilin-web`
session (branch `dev`, code read only).

**What already works offline:** visit with a cash or credit sale, partial debt payment, container
return, reschedule, new customer, cold start (when today's route is already stored). On reconnect
all 19 queued changes were accepted with no rejections.

Each item has an ID used by the ODD plan:

| Prefix | Meaning |
| --- | --- |
| `D#` | You must decide before work starts |
| `B#` | Belongs to the backend or needs an answer from `marilin-web` |
| `F#` | Can be fixed without further decisions |

---

## 1. Decisions for you (`D#`)

Every decision lists a recommendation. Answering "recommendation" is enough.

**Answers (2026-10-29):**

| ID | Answer |
| --- | --- |
| D1 | b) warn and allow |
| D2 | b) clear "connect to download today's route" message |
| D3 | b) hold dependent records until their visit is closed |
| D5 | Keep the Salta list. Customers must be from Salta; `marilin-web` will move the customer data from Jujuy to Salta. F16 is dropped. |
| D7 | a) outcome and amount |
| D4 | b) keep it separate. During a visit the debt banner opens the payment sheet; outside the route the driver opens the customer profile and records the payment there. F15 is dropped. |
| D6 | a) remove the badge |

| ID | Question | Options | Recommendation | Blocks |
| --- | --- | --- | --- | --- |
| D1 | Selling more than the truck stock: what happens? Today 50 Bidón could be sold with 38 on the truck. The server never blocks; stock may go negative. | a) block · b) warn and allow · c) nothing | **b** — a real truck can carry stock the app does not know about | F1 |
| D2 | Starting a day offline with no route for today | a) show the last stored route with an "outdated" banner · b) empty screen with a clear "connect to download today's route" message | **b** — a past route could not be pushed anyway (server only accepts today's route); just say it clearly | F6 |
| D3 | Payments/sales/containers made during an open visit can be pushed before the visit exists, and then lose the visit link forever (`lib/features/sync/push/references.dart:16`). | a) create the visit row when the stop is opened · b) hold dependent records in the outbox until their visit is closed | **b** — smaller, keeps the visit insert-only model, no schema change | F2 |
| D4 | Collect old debt inside a sale ("Debe $34.000 de antes" is shown but cannot be paid there) | a) add "collect previous debt" to the payment step · b) keep it separate (the debt banner already opens a payment sheet) | **a** — one flow for the driver; the server already accepts free payments | F15 |
| D5 | Neighborhood list is hardcoded for Salta (`salta_neighborhoods.dart`) but customers are in Jujuy | a) swap to a Jujuy list · b) free text · c) catalog from the server (B4) | **a** now, **c** later | F16 |
| D6 | The "9" badge on the Clientes tab (customer count) looks like a notification | a) remove · b) show only something actionable (e.g. customers with unsent changes) | **a** | F14 |
| D7 | What should a closed stop show in the route list? | a) outcome + amount (e.g. "Venta $5.700 · Efectivo", "No quiso · Cobró $2.000 · Devolvió 3") · b) outcome only | **a** | F3 |

## 2. Backend / `marilin-web` (`B#`)

| ID | Item | Why it matters for mobile |
| --- | --- | --- |
| B1 | ~~Sale date timezone~~ **Resolved, no bug:** `ClientTime::parse` converts to `America/Argentina/Buenos_Aires` (`config/app.php:69`) before the stock route lookup. Keep sending UTC with `Z`. | — |
| B2 | Pull/bootstrap never return visits, sales, payments, container movements. | A reinstalled phone cannot rebuild the work done today. Mobile must never lose its DB (logout already keeps it, `auth_controller.dart:93`) |
| B3 | No push for: preferences, more than one address, visit edit, sale/payment cancel, truck loads, customer disable. | Mobile does **not** build these until the server supports them |
| B4 | Neighborhood catalog | Needed for D5 option c |
| B5 | End-of-day close (cash, truck stock, containers) | Does not exist on either side; needs a product definition first |

**Backend decisions (2026-10-29, from `marilin-web`):**

- Seed customers move to Salta: yes.
- B2: yes. Bootstrap will include today's visits and sales.
- B3: yes. Push support is being planned. Mobile builds each item once its server contract exists.
- B4: yes. The server will serve a Salta neighborhood catalog, built from the mobile list (`saltaNeighborhoods`, 398 names, sent verbatim).
- B5: postponed.

## 3. Fixes I can make (`F#`)

Grouped into candidate work units for the ODD plan. Evidence is from the device and the code.

### Data correctness (high priority)

| ID | Problem | Evidence | Depends on |
| --- | --- | --- | --- |
| F1 | Selling does not decrement local truck stock. The pull appliers assume unsent sales already did. | Device: 38/20 stayed after selling 3+1; 35/19 only after sync. `product_applier.dart:81`, `truck_inventory_applier.dart:44` | D1 |
| F2 | Records made during an open visit can lose their visit link (see D3) | `references.dart:16`, `payment_pusher.dart:57` | D3 |
| F4 | Floor "PB" is lost: mobile sends `int.tryParse`, server accepts a string | `customer_pusher.dart:92-95`, server `CustomerPusher.php:151-167` | — |
| F5 | A customer created offline ends up with **two** local addresses after sync (one with "PB", one empty) | Device DB: 2 rows in `customer_addresses` for "Prueba Offline"; the address applier does not match the locally created row | — |
| F7 | Validate `total == Σ quantity × unit_price` before saving a sale (the server's only hard reject). A rejected sale stays stuck in the outbox. | Server `SalePusher.php:128-138` | — |
| F8 | Check that sale price resolution matches the server (active agreement on the sale date, latest `valid_from`, then highest id; else product price) | Server `PriceResolver.php:17-28` | — |

### Showing what happened (route, visit, history)

| ID | Problem | Evidence |
| --- | --- | --- |
| F3 | Closed stops in the route show only ✓ or "Reprogramada"; no outcome or amount | Device: Calisaya, Hotel and Tolaba look identical |
| F9 | A closed visit always says "Parada completada con éxito", even for "No quiso" | Device: Tolaba "No quiso" with a payment |
| F10 | The REGISTRO section in the visit lists only sales; payments and returns made during the visit are missing | Device: Tolaba payment of $2.000 and the return of 2+1 not listed |
| F11 | A rescheduled visit says "Visita reprogramada para hoy" without the new time | Device |
| F12 | History: visit rows say "Visita registrada" without the outcome; credit sales are not marked; "Parada actualizada" duplicates the visit row | Device |
| F13 | Debt sign is inconsistent: "-$35.900" in the visit, "Debe $35.900" in lists | Device |

### Offline feedback

| ID | Problem | Evidence |
| --- | --- | --- |
| F6 | No route for today offline → empty screen with no message | `sync_service.dart:77-89`, `drift_route_repository.dart:38` (depends on D2) |
| F17 | Offline sync status shows "Falló" in red. It should read as "Sin conexión · N guardados en el teléfono" | Device |

### UI polish

| ID | Problem |
| --- | --- |
| F14 | Remove the customer-count badge from the Clientes tab (D6) |
| ~~F15~~ | Dropped: debt is collected from the visit banner or the customer profile (D4) |
| ~~F16~~ | Dropped: the Salta list stays (D5) |
| F18 | New-customer wizard: Back discards everything without confirmation |
| F19 | New-customer wizard: Enter on name does not move to phone; with the keyboard open, Siguiente sits under the fields |
| F20 | Time picker is in English (AM/PM, Cancel/OK): add the `es` localization delegates |
| F21 | The new-customer button covers the WhatsApp button of the last customer card |
| F22 | Sale step 1 subtitle "Elegí el cliente…" appears when the customer is already chosen |
| F23 | Profile theme selector wraps "Sistema"/"Oscuro" onto two lines |
| F24 | Plural: "1 pendientes" in the route progress |
| F25 | Remove `deleteCustomer`: the server always rejects it (`customer_pusher.dart:15,41`) |
| F26 | Customer edit screen + use case with a transaction (name, phone, one address); the server applies last-write-wins by `modified_at` |

## 4. Out of scope until the backend supports it

Sale/payment cancel, visit edit, multiple addresses, preferences push, truck loads from the app,
customer disable, skipping or moving a stop to another day (server only handles today's route,
one reschedule per stop, ADR 0002).

## 5. Suggested ODD order

1. F1, F2, F4, F5, F7, F8: data correctness. F1 and F2 need D1 and D3 answered.
2. F3, F9, F10, F11, F12, F13: show what happened.
3. F6, F17: offline feedback. F6 needs D2 answered.
4. F14–F26: polish and customer edit.

Test data left in the local server: customer "Prueba Offline" (id 25), 2 sales, 2 payments,
4 visits, 2 reschedules, container movements for Calisaya, Hotel and Tolaba.
