# Design System Foundation

Brand identity is **TBD**. Begin with semantic tokens and platform conventions so visual decisions remain adaptable.

- **Typography:** semantic roles (large title through caption), Dynamic Type, readable line length, no fixed-size assumptions.
- **Spacing:** a small named scale for inset, stack, section, and touch-target rhythm.
- **Corner radius:** semantic component roles rather than arbitrary per-screen values.
- **Colors:** background, surface, primary/secondary text, accent, success, warning, destructive, and confidence/provenance states; never communicate meaning by color alone.
- **Elevation:** minimal hierarchy using platform materials/shadows with high-contrast fallbacks.
- **Components:** buttons, fields, cards, source/evidence rows, status badges, banners, empty/error states, calendar items, review controls, and confirmation surfaces.

Components support light/dark mode, increased contrast, Reduce Transparency/Motion, RTL layout, localization expansion, and Dynamic Type. Prefer native SwiftUI controls and minimum platform touch targets. A final palette, typeface, icon language, token values, and component catalog are **TBD**.

## Current proposed visual direction

Calm, warm, trustworthy consumer productivity styling: generous spacing, restrained elevated surfaces, limited shadows, system-adaptive color, and clear hierarchy. Semantic tokens now include primary/secondary/tertiary text, background/surface, accent and soft accent, success/warning/destructive pairs, and divider. Typography roles cover screen/section/card titles, body/secondary body, metadata, and button labels. `SurfaceCard` plus primary/secondary button styles reduce duplication without forming a general UI framework.

Review decisions use text, icons, borders, and restrained semantic fills—never color alone. Evidence appears as an explicit source disclosure in an inset surface. These are **Proposed** product tokens, not final branding.
