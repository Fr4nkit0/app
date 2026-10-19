# Product

<!-- impeccable:product-schema 1 -->

## Platform

mobile (Android / iOS)

## Stack

Flutter, Dart (Null Safety), Riverpod (State Management & DI), Drift (Local SQLite), Material 3 Expressive.

## Users

**Repartidores (delivery drivers):** Mobile users running a **route-based distribution shift** from the truck — not generic field sales or office admin. They operate from truck cabs under direct sunlight with wet or gloved hands, confirm stop-by-stop deliveries, record bottle exchanges (full vs. empty returns), follow the day’s route sequence, and collect payments between stops.

## Product Purpose

A robust, offline-capable mobile companion for water and soda distribution drivers. Success means flawless route execution, zero data loss when offline, fast data entry for inventory exchanges, and clear daily settlement numbers (cash close).

## Positioning

A specialized, high-efficiency operational tool tailored specifically for the physical constraints of water/soda distribution (handling returnable bottles and dispensers) on the road, strictly integrated with the Marilin Web backend.

## Operating Context

- **Truck Cab & Street:** High-glare, vibrating environment where speed and clear tap targets are critical to confirm stops quickly without disrupting the route. Network connectivity is unreliable, meaning the app must function correctly offline and sync when possible.

## Capabilities and Constraints

- **Capabilities:** Turn-by-turn route overview, customer drop-offs (fulls vs. empties), payment collection, daily cash close (cierre de caja), and real-time inventory tracking on the truck.
- **Constraints:** 
  - Must provide an extremely robust, touch-friendly mobile interface for drivers that prevents data entry errors under sub-optimal physical conditions.
  - Requires rock-solid local persistence (Drift) and state management (Riverpod) to guarantee zero data loss during offline operations.
  - No direct heavy logic in UI widgets; strict separation of presentation and business logic.

## Brand Commitments

- Spanish (Rioplatense) for the UI copy and user interactions.
- English for the source code (classes, variables, tables).
- Professional, clear, and direct tone.
- Aesthetic contract: "The Premium SaaS" (light, clean, highly readable, no dark/industrial themes).

## Evidence on Hand

- Flutter scaffolded with Riverpod and Drift.
- Aesthetic constraints mapped in `SURFACE.md` and `DESIGN.md`.
- Strict architecture rules defined in `AGENTS.md`.

## Product Principles

1. **Repartidor-First Mobile Ergonomics:** The mobile interface must be foolproof for route execution, with large touch targets, high contrast, and readable typography (Premium SaaS contract).
2. **Offline-First Resilience:** The app must assume the internet is always dropping. Operations must save locally first (Drift) and sync seamlessly without blocking the repartidor on the route.
3. **Clarity over Decoration:** The UI must prioritize speed of data entry and readability over aesthetic flourishes, while maintaining the clean, floating SaaS look.
4. **Strict Structural Integrity:** UI widgets must be dumb. Business logic lives in Riverpod providers and repositories. No direct database access from views.
