# Design System — Marilin Mobile

Companion to `SURFACE.md` (visual direction) and `PRODUCT.md` (product constraints).  
**Mode:** Operate — repartidor executing route stops under glare, vibration, and offline gaps.

## Tokens (source of truth)

Implementation: `lib/core/theme/marilin_tokens.dart`

| Token | Constant | Usage |
| --- | --- | --- |
| Scaffold background | `MarilinColors.scaffoldMuted` (`#F8FAFC`) | All primary tabs and visit flow |
| Surface / cards | `MarilinColors.surface` | Cards, sheets, footer bars |
| Primary action | `MarilinColors.brandBlue` (`#2563EB`) | Filled buttons, nav indicator, links |
| Headings / chrome | `MarilinColors.brandNavy` (`#0D1B3E`) | Titles, AppBar foreground |
| Muted text | `MarilinColors.textMuted` | Subtitles, section labels |
| Border | `MarilinColors.border` | Card outlines, dividers |
| Success | `MarilinColors.success` | Done stops, confirmations |
| Destructive | `MarilinColors.destructive` | Debt, errors |
| Accent | `MarilinColors.accent` | Secondary emphasis (sales) |

**Runtime access:** `MarilinTokens.of(context)` for `ThemeExtension` fields and text styles (`titleLarge`, `subtitle`).

**Sales module:** `SalesTokens` via `Theme.of(context).extension<SalesTokens>()` — primary/destructive mirror `MarilinColors`.

## Theme

- Global theme: `AppTheme.lightTheme` in `lib/core/theme/app.theme.dart`
- Material 3, light only (no dark/industrial)
- `scaffoldBackgroundColor` = `MarilinColors.scaffoldMuted`
- Primary buttons / FAB / nav: `brandBlue`
- Minimum primary button height: 56dp (theme); sticky footers must respect safe area

## Layout patterns

| Pattern | Widget / location |
| --- | --- |
| Tab screen title | `ScreenHeader` (`lib/core/widgets/screen_header.dart`) |
| Visit sections | `VisitSectionHeader` (`lib/features/visits/presentation/widgets/visit_section_header.dart`) |
| Visit mode toggle | `VisitModeSelector` (`visit_mode_selector.dart`) |
| Visit primary CTA | `VisitStickyFooter` (`visit_sticky_footer.dart`) — logic in screen |
| Visit customer block | `VisitCustomerCard` (`visit_customer_card.dart`) |
| Visit debt / custody | `VisitDebtBanner`, `VisitCustodyBanner` |
| Container return dialog | `StandaloneContainerReturnDialog` in `visit_container_return_dialog.dart` |
| Empty states | `EmptyState` |

## Rules for new UI

1. Do **not** introduce new hex primaries; extend `MarilinColors` if a semantic is missing.
2. Prefer `Theme.of(context).colorScheme` / `MarilinTokens.of` over inline `Color(0x…)`.
3. Touch targets ≥ 48dp; primary actions ≥ 52–56dp.
4. Copy: Spanish (Rioplatense), code: English.
5. Cards: white surface, subtle border, elevation 0 (see `SURFACE.md`).

## Session / identity (UI)

- Repartidor display name: `AuthState.displayName` (secure storage), used on route header greeting and avatar initials.
