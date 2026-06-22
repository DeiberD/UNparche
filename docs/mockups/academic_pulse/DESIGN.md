---
name: Academic Pulse
colors:
  surface: '#fef8f6'
  surface-dim: '#ded9d7'
  surface-bright: '#fef8f6'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f8f2f0'
  surface-container: '#f3edea'
  surface-container-high: '#ede7e5'
  surface-container-highest: '#e7e1df'
  on-surface: '#1d1b1a'
  on-surface-variant: '#454841'
  inverse-surface: '#32302f'
  inverse-on-surface: '#f6efed'
  outline: '#767870'
  outline-variant: '#c6c7be'
  surface-tint: '#5a6052'
  primary: '#282e22'
  on-primary: '#ffffff'
  primary-container: '#3e4437'
  on-primary-container: '#abb1a0'
  inverse-primary: '#c3c9b7'
  secondary: '#655b65'
  on-secondary: '#ffffff'
  secondary-container: '#eddeea'
  on-secondary-container: '#6c616b'
  tertiary: '#372a1a'
  on-tertiary: '#ffffff'
  tertiary-container: '#4e402f'
  on-tertiary-container: '#c0ac96'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dfe5d3'
  primary-fixed-dim: '#c3c9b7'
  on-primary-fixed: '#181d12'
  on-primary-fixed-variant: '#43493c'
  secondary-fixed: '#eddeea'
  secondary-fixed-dim: '#d0c2ce'
  on-secondary-fixed: '#211921'
  on-secondary-fixed-variant: '#4d444d'
  tertiary-fixed: '#f5dfc7'
  tertiary-fixed-dim: '#d8c3ac'
  on-tertiary-fixed: '#251a0b'
  on-tertiary-fixed-variant: '#534433'
  background: '#fef8f6'
  on-background: '#1d1b1a'
  surface-variant: '#e7e1df'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 57px
    fontWeight: '700'
    lineHeight: 64px
    letterSpacing: -0.25px
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  title-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.5px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.25px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.1px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  margin-mobile: 16px
  margin-desktop: 24px
  gutter: 16px
  touch-target: 48px
---

## Brand & Style

The design system is built for a vibrant university ecosystem, balancing the rigor of academic life with the high energy of social connection. It adopts a **Modern Material** aesthetic, heavily influenced by Material Design 3's focus on expressive color and adaptive layout, but refined with a sophisticated, organic palette.

The visual language emphasizes "The Parche"—the gathering spot. It uses large surface areas, generous tactile targets, and a clear information hierarchy to ensure the UI feels approachable during a quick walk between classes. The tone is smart, reliable, and spirited, favoring clarity over clutter to reduce cognitive load for busy students.

## Colors

The palette is derived from natural campus environments—stone, ivy, and dusk. 

- **Primary (Forest Green):** Used for main action buttons, active states, and brand identifiers. It signifies growth and campus activity.
- **Secondary (Muted Purple):** Applied to secondary actions, filtering chips, and academic-specific tags. It provides a scholarly contrast to the primary green.
- **Tertiary (Warm Taupe):** Utilized for accents, decorative elements, and subtle dividers to keep the interface grounded.
- **Neutral (Deep Charcoal):** Reserved for high-contrast typography and essential iconography to ensure maximum legibility.
- **Surface (Off-White):** The primary canvas. All cards and modals sit atop this warm base to prevent screen fatigue.

## Typography

This design system utilizes **Plus Jakarta Sans** for all levels of the hierarchy. Its modern, geometric curves and open counters provide a friendly yet professional appearance that scales perfectly from dense course lists to bold event headlines.

- **Headlines:** Use a bold weight to anchor the page. Headlines are "optical-first," meaning they should use tighter letter-spacing as they increase in size.
- **Body Text:** Standardized at 16px for primary reading to ensure accessibility for all students.
- **Labels:** Used for navigation items and small metadata. These use a medium weight to maintain visibility at smaller scales.

## Layout & Spacing

The system follows a **Fluid Grid** model based on an 8px square rhythm. 

- **Mobile:** Uses a 4-column grid with 16px side margins. Navigation is centered in a "Bottom App Bar" or "Navigation Bar" to keep primary actions within the natural sweep of the thumb.
- **Desktop:** Scales to a 12-column grid (max-width 1280px) with 24px margins. Content is organized into modular "Panes" that allow for multi-tasking (e.g., viewing a feed while keeping a calendar visible).
- **Safe Zones:** All interactive elements must maintain a minimum 48x48px touch target area to accommodate mobile-first usage.

## Elevation & Depth

In line with Material 3, depth is primarily communicated through **Tonal Layers** rather than heavy shadows.

- **Level 0 (Background):** The Off-White (#F5F5F0) base.
- **Level 1 (Cards/Surfaces):** Elements are slightly elevated using a subtle 5% opacity tint of the Primary color and a very soft, diffused shadow (Blur: 8px, Y: 2px, Opacity: 0.05).
- **Level 2 (Modals/Floating Action Buttons):** These use a higher tonal contrast and a more pronounced shadow to indicate they sit above the main flow.
- **Active State:** When pressed, elements lose their elevation (becoming "pressed" into the surface) or show a ripple effect to provide tactile feedback.

## Shapes

The shape language is defined by significant corner radii to evoke a sense of friendliness and safety.

- **Large Components (Cards, Modals):** Use a fixed 24px radius to create a soft, containerized look.
- **Medium Components (Buttons, Input Fields):** Use a 16px radius for a comfortable, pill-like feel.
- **Small Components (Chips, Tags):** Use a full-rounded (pill) shape for easy categorization and tapability.

## Components

- **Buttons:** Primary buttons are filled with Forest Green and use white text. Secondary buttons are outlined using the Warm Taupe color. Icons are encouraged in buttons for quicker visual recognition.
- **Cards:** The core of the system. Cards must have a 24px radius, no border, and a Level 1 elevation shadow. Content within cards should follow the 16px internal padding rule.
- **Chips:** Used for "Parche" tags (e.g., #StudyGroup, #Party). These use the Muted Purple as a background with 10% opacity and a darker purple for text.
- **Input Fields:** Outlined style with a 16px radius. The border color is Warm Taupe, changing to Forest Green on focus. Labels should float above the border when the field is active.
- **Navigation Bar:** A bottom-aligned bar with large icons and labels. The active state is indicated by a colored pill container behind the icon, consistent with Material 3 standards.
- **Course Lists:** Clean rows with 12px vertical spacing, using the Deep Charcoal for titles and Muted Purple for subtext/metadata.