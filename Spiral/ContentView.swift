//
//  ContentView.swift
//  Spiral
//
//  Enhanced with Metal GPU acceleration
//

import SwiftUI
import Metal
import MetalKit

// MARK: - Metal Renderer
class MetalRenderer: NSObject, ObservableObject {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var computePipelineState: MTLComputePipelineState!
    private var renderPipelineState: MTLRenderPipelineState!
    private var particleBuffer: MTLBuffer!
    private var uniformBuffer: MTLBuffer!
    
    struct Particle {
        var position: SIMD2<Float>
        var velocity: SIMD2<Float>
        var color: SIMD4<Float>
        var life: Float
        var size: Float
    }
    
    struct Uniforms {
        var time: Float
        var deltaTime: Float
        var particleCount: Int32
        var orbitRadius: Float
        var rotationSpeed: Float
        var screenSize: SIMD2<Float>
        var shapeMode: Int32
        var growthFactor: Float
        var complexity: Float
        var morphSpeed: Float
    }
    
    @Published var particleCount: Int = 2000 {
        didSet {
            setupParticles()
        }
    }
    @Published var shapeMode: Int = 0
    @Published var growthFactor: Float = 1.0
    @Published var complexity: Float = 1.0
    @Published var morphSpeed: Float = 1.0
    
    override init() {
        super.init()
        setupMetal()
        setupPipelines()
        setupParticles()
    }
    
    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        print("Metal Device: \(device.name)")
        print("Supports GPU Family 3: \(device.supportsFeatureSet(.iOS_GPUFamily3_v1))")
        print("Supports GPU Family 4: \(device.supportsFeatureSet(.iOS_GPUFamily4_v1))")
    }
    
    private func setupPipelines() {
        let library = device.makeDefaultLibrary()!
        
        // Compute pipeline for particle simulation
        let computeFunction = library.makeFunction(name: "updateParticles")!
        do {
            computePipelineState = try device.makeComputePipelineState(function: computeFunction)
        } catch {
            fatalError("Failed to create compute pipeline state: \(error)")
        }
        
        // Render pipeline for particle rendering
        let vertexFunction = library.makeFunction(name: "particleVertexShader")!
        let fragmentFunction = library.makeFunction(name: "particleFragmentShader")!
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            fatalError("Failed to create render pipeline state: \(error)")
        }
    }
    
    private func setupParticles() {
        let bufferSize = particleCount * MemoryLayout<Particle>.stride
        particleBuffer = device.makeBuffer(length: bufferSize, options: .storageModeShared)
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: .storageModeShared)
        
        // Initialize particles
        let particlePointer = particleBuffer.contents().bindMemory(to: Particle.self, capacity: particleCount)
        for i in 0..<particleCount {
            let angle = Float(i) / Float(particleCount) * 2.0 * Float.pi
            let radius = Float.random(in: 50...150)
            
            particlePointer[i] = Particle(
                position: SIMD2<Float>(cos(angle) * radius, sin(angle) * radius),
                velocity: SIMD2<Float>(Float.random(in: -2...2), Float.random(in: -2...2)),
                color: SIMD4<Float>(
                    Float.random(in: 0.5...1.0),
                    Float.random(in: 0.5...1.0),
                    Float.random(in: 0.5...1.0),
                    0.8
                ),
                life: Float.random(in: 0.5...2.0),
                size: Float.random(in: 2...8)
            )
        }
    }
    
    func update(time: Float, deltaTime: Float, rotationSpeed: Float, screenSize: CGSize, shapeMode: Int, growthFactor: Float, complexity: Float, morphSpeed: Float) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        // Update uniforms
        let uniformPointer = uniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
        uniformPointer[0] = Uniforms(
            time: time,
            deltaTime: deltaTime,
            particleCount: Int32(particleCount),
            orbitRadius: 100.0,
            rotationSpeed: rotationSpeed,
            screenSize: SIMD2<Float>(Float(screenSize.width), Float(screenSize.height)),
            shapeMode: Int32(shapeMode),
            growthFactor: growthFactor,
            complexity: complexity,
            morphSpeed: morphSpeed
        )
        
        // Compute shader execution
        computeEncoder.setComputePipelineState(computePipelineState)
        computeEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(uniformBuffer, offset: 0, index: 1)
        
        let threadsPerGroup = MTLSize(width: 32, height: 1, depth: 1)
        let numThreadgroups = MTLSize(
            width: (particleCount + threadsPerGroup.width - 1) / threadsPerGroup.width,
            height: 1,
            depth: 1
        )
        
        computeEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    func render(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - Metal View
struct MetalView: UIViewRepresentable {
    @ObservedObject var renderer: MetalRenderer
    @Binding var rotationSpeed: Double
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 120
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.rotationSpeed = Float(rotationSpeed)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(renderer: renderer)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        let renderer: MetalRenderer
        var rotationSpeed: Float = 0.0
        private var startTime: CFTimeInterval = 0
        private var lastTime: CFTimeInterval = 0
        
        init(renderer: MetalRenderer) {
            self.renderer = renderer
            super.init()
            startTime = CACurrentMediaTime()
            lastTime = startTime
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle size changes
        }
        
        func draw(in view: MTKView) {
            let currentTime = CACurrentMediaTime()
            let time = Float(currentTime - startTime)
            let deltaTime = Float(currentTime - lastTime)
            lastTime = currentTime
            
            renderer.update(
                time: time,
                deltaTime: deltaTime,
                rotationSpeed: rotationSpeed,
                screenSize: view.drawableSize,
                shapeMode: Int(renderer.shapeMode),
                growthFactor: renderer.growthFactor,
                complexity: renderer.complexity,
                morphSpeed: renderer.morphSpeed
            )
            
            renderer.render(in: view)
        }
    }
}

// MARK: - GPU Performance Monitor
class GPUPerformanceMonitor: ObservableObject {
    @Published var frameRate: Double = 0.0
    @Published var computeTime: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    
    private var frameCount = 0
    private var lastUpdateTime = CACurrentMediaTime()
    
    func updateFrameRate() {
        frameCount += 1
        let currentTime = CACurrentMediaTime()
        
        if currentTime - lastUpdateTime >= 1.0 {
            frameRate = Double(frameCount) / (currentTime - lastUpdateTime)
            frameCount = 0
            lastUpdateTime = currentTime
            
            // Simulate GPU metrics (in a real app, you'd use Metal performance shaders)
            computeTime = Double.random(in: 0.5...2.5)
            memoryUsage = Double.random(in: 200...800)
        }
    }
}

// MARK: - Advanced Controls
struct AdvancedControlsView: View {
    @ObservedObject var renderer: MetalRenderer
    @Binding var rotationSpeed: Double
    @ObservedObject var performanceMonitor: GPUPerformanceMonitor
    
    let shapeNames = ["Spiral", "Flower", "Mandala", "Galaxy", "DNA", "Fractal", "Neural", "Plasma",
                      "Phoenix", "Crystal", "Tornado", "Quantum", "Dragon", "Sunflower", "Magnetic", "Mandelbrot",
                      "Lightning", "Celestial", "CNN", "RNN", "GNN", "Transformer", "Autoencoder"]
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Metal GPU Shape Morphing")
                .font(.headline)
                .foregroundColor(.cyan)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Particles: \(renderer.particleCount)")
                Slider(
                    value: Binding(
                        get: { Double(renderer.particleCount) },
                        set: { renderer.particleCount = Int($0) }
                    ),
                    in: 500...90000,
                    step: 1000
                )
                .accentColor(.cyan)
                
                Text("Shape: \(shapeNames[min(renderer.shapeMode, shapeNames.count - 1)])")
                Slider(
                    value: Binding(
                        get: { Double(renderer.shapeMode) },
                        set: { renderer.shapeMode = Int($0) }
                    ),
                    in: 0...22,
                    step: 1
                )
                .accentColor(.purple)
                
                Text("Growth Factor: \(renderer.growthFactor, specifier: "%.1f")")
                Slider(
                    value: Binding(
                        get: { Double(renderer.growthFactor) },
                        set: { renderer.growthFactor = Float($0) }
                    ),
                    in: 0.1...5.0,
                    step: 0.1
                )
                .accentColor(.green)
                
                Text("Complexity: \(renderer.complexity, specifier: "%.1f")")
                Slider(
                    value: Binding(
                        get: { Double(renderer.complexity) },
                        set: { renderer.complexity = Float($0) }
                    ),
                    in: 0.1...3.0,
                    step: 0.1
                )
                .accentColor(.orange)
                
                Text("Morph Speed: \(renderer.morphSpeed, specifier: "%.1f")")
                Slider(
                    value: Binding(
                        get: { Double(renderer.morphSpeed) },
                        set: { renderer.morphSpeed = Float($0) }
                    ),
                    in: 0.1...5.0,
                    step: 0.1
                )
                .accentColor(.red)
                
                Text("Rotation Speed: \(rotationSpeed, specifier: "%.1f")")
                Slider(value: $rotationSpeed, in: 0...10, step: 0.1)
                    .accentColor(.blue)
            }
            
            // Performance metrics
            VStack(alignment: .leading, spacing: 5) {
                Text("GPU Performance")
                    .font(.subheadline)
                    .foregroundColor(.green)
                
                HStack {
                    Text("FPS:")
                    Spacer()
                    Text("\(performanceMonitor.frameRate, specifier: "%.1f")")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Compute Time:")
                    Spacer()
                    Text("\(performanceMonitor.computeTime, specifier: "%.2f")ms")
                        .foregroundColor(.yellow)
                }
                
                HStack {
                    Text("GPU Memory:")
                    Spacer()
                    Text("\(performanceMonitor.memoryUsage, specifier: "%.0f")MB")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(10)
        }
        .padding()
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var renderer = MetalRenderer()
    @StateObject private var performanceMonitor = GPUPerformanceMonitor()
    @State private var rotationSpeed: Double = 1.0
    
    var body: some View {
        ScrollView {
            VStack {
                
                MetalView(renderer: renderer, rotationSpeed: $rotationSpeed)
                    .frame(height: 400)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.cyan, lineWidth: 2)
                    )
                    .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
                        performanceMonitor.updateFrameRate()
                    }
                
                AdvancedControlsView(
                    renderer: renderer,
                    rotationSpeed: $rotationSpeed,
                    performanceMonitor: performanceMonitor
                )
                
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.black, .gray.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}
