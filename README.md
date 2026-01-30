# orbe

A minimal iOS image editor that transforms photos into living, breathing orbs using real-time Metal shaders.

## What it does

Drop in any image and watch it come alive inside a glass-like sphere with organic motion, light refraction, and edge reflections — all rendered on the GPU.

### Effects

- **Motion** — Wavy distortion with configurable speed, strength, frequency, and noise
- **Glow** — Inner luminosity and depth lighting
- **Lens** — Fisheye refraction for a 3D glass look
- **Edge** — Soft rim definition and vignette
- **Reflection** — Color bleed from opposite edges, like light bouncing inside glass

### Built with

- SwiftUI
- Metal Shaders (`[[ stitchable ]]`)
- PhotosUI

## Run

Open `orbe.xcodeproj` in Xcode and run on an iOS 17+ device or simulator.

## License

MIT — do whatever you want. See [LICENSE](LICENSE).
