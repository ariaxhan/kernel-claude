# /design --variant=spatial

3D datascape aesthetic. Living geometry in navigable space. Data as physical objects.

---

<spatial_aesthetic>
**Metaphor:** Diving into a living organism's internal landscape. Data isn't abstract—it's spatially embodied, reachable, touchable.

## Typography

Minimal text in 3D space. When used: light-weight sans (Space Grotesk, IBM Plex) for labels floating near objects. HUD-style overlays use monospace at small sizes. High contrast against dark fog.

## Color

**Type-specific chromatic system** (each data type has distinct visual signature):
- Medicine/healing: Bright green #4ade80, emissive 0.2-0.6
- Energy/fuel: Bright orange #ff6b00, pulsing emission
- Toxin/danger: Violet #7c3aed on dark #1a1025, dispersing particles
- Material/solid: Amber-gold #f59e0b, metallic shimmer

**Temperature encoding** (for relationships/flow):
- Cold: Blue-cyan spectrum (distant, weak)
- Hot: Orange-red spectrum (close, strong)

**Depth encoding:**
- Healthy data floats higher (positive Y)
- Toxic/damaged data sinks lower
- Older data recedes into fog (negative Z)

## Motion

**Organic physics** (not UI transitions):
- Objects bob gently: `sin(time*0.001 + x) * 0.05`
- Clouds pulse: `0.3 + sin(time*0.003) * 0.4`
- Particles drift downward continuously
- Metallic elements shimmer: `0.1 + sin(time*0.002) * 0.05`

**Interaction:**
- Hover: scale 1.15x, emissive boost 2-3x
- Select: scale 1.3x, glow intensifies
- Transition: ~300ms ease-water

**Camera movement:**
- Depth-driven: camera descends as user scrolls
- Fog compresses with depth (25→10 units far plane)
- Creates pressure sensation of diving

## Backgrounds (3D Environment)

**Fog is critical:**
- Color: #0a1628 (deep void blue)
- Near: 5 units, Far: 10-25 units (depth-responsive)
- Objects fade to black as they recede—oceanic pressure feel

**Water surface (if applicable):**
- Custom GLSL shader with two-layer wave system
- Cursor-reactive ripples
- Fresnel edge effect, transparency 0.7

**Lighting:**
- Ambient: 0.2-0.4 intensity (depth-dependent)
- Directional: soft, position [5,10,5]
- Self-emitting objects (bioluminescent independence)

## Geometry

**Low-poly + high-meaning:**
- Spheres for particles (16×16 segments)
- Octahedra for solid/material data (6-faced, crystalline)
- Circles for floating/organic (32 segments)
- Clustered small spheres for clouds/dispersed data

**Stratification:**
- Y-axis = health/quality (good floats, bad sinks)
- X-axis = category/layer
- Z-axis = age (older recedes)

## Components (HUD/Overlay)

**Minimal 2D overlay on 3D:**
- Semi-transparent panels: rgba(10,22,40,0.8) + backdrop-blur
- Thin borders: rgba(255,255,255,0.1)
- Accent glow on active elements
- Keyboard shortcuts displayed subtly

**Progress indicators:**
- SVG rings with stroke-dashoffset animation
- Color shifts based on value thresholds

## Anti-Patterns

- Flat UI overlays that ignore 3D depth
- Uniform lighting (use self-illumination)
- Static objects (everything should move subtly)
- Dense text in 3D space
- Ignoring fog/atmosphere
- Harsh edges (use soft glow, blur)
</spatial_aesthetic>

---

## Tech Stack

```
Three.js / React Three Fiber / Threlte
Custom GLSL shaders for water/materials
Pointer raycasting for interaction
requestAnimationFrame for continuous motion
```

## Tokens

```css
:root {
  --spatial-bg: #0a1628;
  --fog-near: 5; --fog-far: 25;
  --glow-green: #4ade80; --glow-orange: #ff6b00;
  --glow-violet: #7c3aed; --glow-amber: #f59e0b;
  --surface-dark: #1a1025;
}
```
