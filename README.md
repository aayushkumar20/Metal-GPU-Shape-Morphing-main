# Spiral - Advanced Shape Morphing System

## Overview
**Spiral** is a SwiftUI application that leverages **Metal** for GPU-accelerated particle system rendering and shape morphing. It creates visually stunning animations by morphing particles between various complex shapes such as spirals, mandalas, galaxies, and neural network-inspired patterns. The app provides an interactive interface for real-time control over animation parameters and GPU performance monitoring.

- **Platforms:** iOS & macOS  
- **Technologies:** SwiftUI + Metal  
- **Rendering:** GPU-accelerated using Metal compute & render pipelines

## Features

- 🚀 **GPU-Accelerated Particle System:** Efficiently renders thousands of particles using Metal.
- 🌐 **Dynamic Shape Morphing:** 23 complex shape functions, from natural to AI-inspired patterns.
- 🎛 **Interactive Controls:** Adjust particle count, shape, morph speed, and more with sliders.
- 📊 **Real-Time Performance Monitoring:** Simulated FPS, compute time, and memory usage display.
- 🎨 **Customizable Visuals:** Dynamic colors, sizes, and visual effects via advanced fragment shaders.
- 🔄 **Smooth Transitions:** Interpolates particles for seamless morphing between shapes.

## Prerequisites

- **Xcode:** Version 16 or later  
- **Swift:** Version 5.5 or later  
- **macOS:** Ventura 13.0+  
- **iOS:** iOS 16.0+  
- **Hardware:** Metal-compatible iOS or macOS device

## Installation

```bash
# Clone the repository
git clone https://github.com/aayushkumar20/Metal-GPU-Shape-Morphing.git
cd spiral
```

1. Open `Spiral.xcodeproj` in Xcode.
2. Select the desired target (iOS/macOS).
3. Choose a simulator or device.
4. Build & run using `Cmd + R`.

## Usage

### 🎬 Launch the App
- A Metal-powered view renders the particle system with controls below.

### 🎚 Adjust Parameters
| Parameter        | Range / Options                            |
|------------------|--------------------------------------------|
| Particles        | 500 to 90,000                              |
| Shape            | 23 types (e.g., Spiral, Galaxy, Transformer) |
| Growth Factor    | 0.1 to 5.0                                 |
| Complexity       | 0.1 to 3.0                                 |
| Morph Speed      | 0.1 to 5.0                                 |
| Rotation Speed   | 0.0 to 10.0                                |

### 📈 Monitor Performance
- View real-time FPS, compute time, and memory usage (simulated).

### 🧪 Experiment
- Combine shapes and parameters for creative animations.
- Observe how particle count impacts GPU performance.

## Project Structure

| File / Folder           | Description                                                                 |
|-------------------------|-----------------------------------------------------------------------------|
| `ContentView.swift`     | Main SwiftUI interface; manages state, Metal renderer, and control panel.  |
| `Shaders.metal`         | Metal shader code with shape logic, compute, and fragment shaders.         |
| `GPUPerformanceMonitor` | Simulates performance metrics for UI display.                             |
| `AdvancedControlsView`  | SwiftUI view for adjusting parameters and monitoring performance.          |

## Technical Details

### 🔧 Metal Implementation

- **Compute Pipeline:**  
  `updateParticles` updates position, velocity, size, and color.

- **Render Pipeline:**  
  `particleVertexShader` & `particleFragmentShader` handle visual effects like:
  - Chromatic aberration  
  - Multi-layer rendering  
  - Sparkle/shimmer

- **Shape Generation:**  
  23 functions for shapes like:
  - 🌻 Natural (Spiral, Sunflower, Flower)  
  - 🔬 Scientific (DNA, Quantum Field)  
  - 🧠 Neural (CNN, RNN, Transformer, GNN)

### 🧩 SwiftUI Integration

- Uses `@StateObject`, `@ObservedObject` for reactive UI updates.
- Embeds `MTKView` with `UIViewRepresentable`/`NSViewRepresentable`.

### ⚙️ Performance Optimization

- GPU-accelerated particle updates and rendering.
- Shared memory buffers for CPU–GPU efficiency.
- High refresh support (up to 120 FPS on ProMotion devices).

## Known Issues

- ⚠️ **Older Devices:** Slowdowns may occur at >50,000 particles.
- 🧪 **Simulated Metrics:** GPU metrics are simulated; replace with actual Metal diagnostics in production.

## Contributing

I welcome contributions to enhance and expand **Spiral - GPU Shape Morphing**!

1. **Fork** this repository: [Metal-GPU-Shape-Morphing](https://github.com/aayushkumar20/Metal-GPU-Shape-Morphing.git)
2. **Create a new branch** for your feature or bugfix:  
   ```bash
   git checkout -b my-feature
   ```
3. **Make your changes** — whether it's a bug fix, new shape, performance improvement, or UI enhancement.
4. **Commit your work** with a meaningful message:  
   ```bash
   git commit -m "Add: Custom L-system fractal shape"
   ```
5. **Push to your forked repo:**  
   ```bash
   git push origin my-feature
   ```
6. **Submit a Pull Request** with a detailed description of what you’ve added or fixed.

## Future Enhancements

- ✅ Full support for all shape-to-shape transitions.
- 🔊 Audio-reactive particle animations.
- 🧠 Add fractals, attractors, and L-system-based shapes.
- ⚙️ Optimize shaders for lower-end devices.
- 📉 Integrate Metal performance counters for real GPU stats.

## License

This project is licensed under the [Apache License 2.0](LICENSE).

## Acknowledgments

- Inspired by generative art, particle physics, and neural systems.
- Built with ❤️ using **SwiftUI** and **Metal**.
- Thanks to the Apple developer and Metal communities for guidance and resources.
