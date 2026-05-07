---
name: Vibe Social
colors:
  surface: '#0f0b3c'
  surface-dim: '#0f0b3c'
  surface-bright: '#363364'
  surface-container-lowest: '#0a0538'
  surface-container-low: '#181445'
  surface-container: '#1c1949'
  surface-container-high: '#262454'
  surface-container-highest: '#312f5f'
  on-surface: '#e3dfff'
  on-surface-variant: '#cbc3d7'
  inverse-surface: '#e3dfff'
  inverse-on-surface: '#2d2a5b'
  outline: '#958ea0'
  outline-variant: '#494454'
  surface-tint: '#d0bcff'
  primary: '#d0bcff'
  on-primary: '#3c0091'
  primary-container: '#a078ff'
  on-primary-container: '#340080'
  inverse-primary: '#6d3bd7'
  secondary: '#ffb0cd'
  on-secondary: '#640039'
  secondary-container: '#aa0266'
  on-secondary-container: '#ffbad3'
  tertiary: '#4cd7f6'
  on-tertiary: '#003640'
  tertiary-container: '#009eb9'
  on-tertiary-container: '#002f38'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e9ddff'
  primary-fixed-dim: '#d0bcff'
  on-primary-fixed: '#23005c'
  on-primary-fixed-variant: '#5516be'
  secondary-fixed: '#ffd9e4'
  secondary-fixed-dim: '#ffb0cd'
  on-secondary-fixed: '#3e0022'
  on-secondary-fixed-variant: '#8c0053'
  tertiary-fixed: '#acedff'
  tertiary-fixed-dim: '#4cd7f6'
  on-tertiary-fixed: '#001f26'
  on-tertiary-fixed-variant: '#004e5c'
  background: '#0f0b3c'
  on-background: '#e3dfff'
  surface-variant: '#312f5f'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.08em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin: 20px
---

## Brand & Style

This design system is engineered to evoke high-energy social interaction and playfulness. Targeted at Gen Z and young gamers, the brand personality is expressive, loud, and unapologetically digital. The aesthetic combines **Glassmorphism** with **Retro/Vaporwave** influences, utilizing translucent layers and glowing neon accents to create a sense of depth and excitement. 

The emotional response should be one of "digital dopamine"—using high-saturation colors and tactile feedback to make every interaction feel like a win. Motion and micro-interactions are central to the brand, where elements bounce, pulse, and glow to signify life within the app.

## Colors

The palette is anchored by a "Deep Cosmic Purple" dark mode base, which provides a high-contrast foundation for neon elements. 

- **Primary (Electric Violet):** Used for main actions and branding.
- **Secondary (Hot Pink):** Used for social notifications, hearts, and high-energy triggers.
- **Tertiary (Neon Cyan):** Reserved for interactive game elements and status indicators.
- **Neon Accent (Lemon Lime):** Used sparingly for critical CTAs or "level-up" moments to ensure they pop against the purple backgrounds.

Gradients should predominantly flow from Primary to Secondary at a 135-degree angle to create a sense of forward motion.

## Typography

The design system utilizes **Plus Jakarta Sans** for its friendly, open counters and modern, rounded terminals. 

- **Display & Headlines:** Use extra-bold weights with slight negative letter spacing to create a "chunky" and impactful social feel.
- **Body Text:** Maintained at medium weights (500) to ensure readability against dark, vibrant backgrounds. 
- **Labels:** Uppercase styles are used for navigation and small metadata to provide a structured contrast to the organic shapes of the UI.

## Layout & Spacing

This design system uses a **Fluid Grid** model optimized for mobile-first interaction. The layout relies on a 4-column structure for most content cards, with 16px gutters. 

Outer margins are set to 20px to prevent the high-energy components from feeling cramped against the screen edges. Spacing follows a 4px baseline rhythm, but leans heavily toward larger "breathable" gaps (16px+) between distinct functional groups to maintain clarity amidst the vibrant color palette.

## Elevation & Depth

Hierarchy is established through **Ambient Glows** and **Glassmorphism** rather than traditional grey shadows. 

1. **Base Layer:** Deep Purple (#1E1B4B).
2. **Surface Layer:** Semi-transparent purple with a 10% white overlay and 20px backdrop blur.
3. **Elevated Layer:** Floating elements use "Colored Shadows"—a diffused drop shadow that inherits the color of the element (e.g., a Pink button casts a soft pink glow).
4. **Interactive State:** When pressed, elements should appear to sink (inner shadow) or expand with a glowing outer stroke.

## Shapes

The shape language is defined by extreme roundedness to reinforce the playful and friendly "toy-like" vibe. 

- **Containers & Cards:** Use a minimum radius of 24px.
- **Buttons:** Always pill-shaped (fully rounded) to encourage tapping.
- **Inputs:** Use a 20px radius to match the overall softness.
- **Iconography:** Icons should be enclosed in "squircle" containers or circles with thick, rounded strokes (2px minimum).

## Components

- **Buttons:** Primary buttons use a vibrant gradient (Purple to Pink) with a soft glow shadow. Secondary buttons use a thick 2px neon stroke with no fill.
- **Chips:** Small, pill-shaped tags used for game categories or interests. Use semi-transparent fills with high-contrast text.
- **Cards:** Glassmorphic backgrounds with a subtle 1px white border at 10% opacity to define edges against the deep purple background.
- **Lists:** Items are separated by generous spacing (12px) rather than divider lines, appearing as individual floating modules.
- **Input Fields:** Darker than the background with a bright neon "focus" stroke. Labels float above the field in a bold, condensed format.
- **Avatars:** Always circular with a 3px gradient border to indicate "Online" or "In-Game" status.
- **Game Tiles:** Large-format squares with 32px rounded corners, featuring edge-to-edge imagery and a frosted bottom bar for titles.