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
| Warning | `MarilinColors.warning` | Pending, caution, amber notices |

**Runtime access:** `MarilinTokens.of(context)` for `ThemeExtension` fields and text styles (`titleLarge`, `subtitle`).

**Sales module:** `SalesTokens` via `Theme.of(context).extension<SalesTokens>()` — primary/destructive mirror `MarilinColors`.

## Theme

- Global themes: `AppTheme.lightTheme` and `AppTheme.darkTheme` in `lib/core/theme/app.theme.dart`, built from `MarilinTokens.light` / `MarilinTokens.dark`
- Material 3. Light is the default; the driver can choose dark (or follow the phone) in the profile. Dark is neutral near-black with the same blue accent, never industrial
- Status colors in dark: `tokens.vivid(color)` for text and icons, `tokens.soft(color)` for pastel washes
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
| Driver avatar | `ProfileAvatar` (`lib/features/profile/widgets/profile_avatar.dart`): route header at 54dp, profile at 88dp |

## Rules for new UI

1. Do **not** introduce new hex primaries; extend `MarilinColors` if a semantic is missing. `test/core/theme/no_raw_colors_test.dart` fails on any `Color(0x…)` outside `lib/core/theme/`.
2. Prefer `Theme.of(context).colorScheme` / `MarilinTokens.of` over inline `Color(0x…)`.
3. Touch targets ≥ 48dp; primary actions ≥ 52–56dp.
4. Copy: Spanish (Rioplatense), code: English.
5. Cards: white surface, subtle border, elevation 0 (see `SURFACE.md`).

## Session / identity (UI)

- Repartidor display name: `AuthState.displayName` (secure storage), used on route header greeting and avatar initials.
- Profile entry point: the identity row (avatar + greeting) on the route screen opens `ProfileScreen`. The navigation bar stays at four operational tabs; the profile is not a tab.
- `ProfileScreen` sections: identity, sync status (reuses `HistorySyncStatusCard`), theme card, sign out with a pending-changes notice.
