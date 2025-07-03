//
//  Shaders.metal
//  Spiral - Advanced Shape Morphing System
//
//  GPU-accelerated particle system with dynamic shape generation
//

#include <metal_stdlib>
using namespace metal;

struct Particle {
    float2 position;
    float2 velocity;
    float4 color;
    float life;
    float size;
    float2 targetPosition;
    float phase;
    int shapeIndex;
};

struct Uniforms {
    float time;
    float deltaTime;
    int particleCount;
    float orbitRadius;
    float rotationSpeed;
    float2 screenSize;
    int shapeMode;
    float growthFactor;
    float complexity;
    float morphSpeed;
};

// MARK: - Shape Generation Functions

float2 generateSpiralPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    float angle = t * complexity * 12.0 * M_PI_F + time * 0.5;
    float radius = t * growthFactor * 120.0 * (1.0 + sin(time * 2.0) * 0.3);
    return float2(cos(angle) * radius, sin(angle) * radius);
}

float2 generateFlowerPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    float petals = 5.0 + complexity * 3.0;
    float angle = t * 2.0 * M_PI_F;
    float petalRadius = sin(angle * petals) * 0.8 + 0.2;
    float radius = petalRadius * growthFactor * 80.0 * (1.0 + sin(time * 3.0 + angle) * 0.4);
    float finalAngle = angle + time * 0.3;
    return float2(cos(finalAngle) * radius, sin(finalAngle) * radius);
}

float2 generateMandalaPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    float layers = 3.0 + complexity * 2.0;
    float angle = t * 2.0 * M_PI_F * layers;
    
    // Create multiple concentric patterns
    float layer = floor(t * layers);
    float layerT = fmod(t * layers, 1.0);
    float layerRadius = (layer + 1.0) * 25.0 * growthFactor;
    
    float patternRadius = layerRadius * (0.8 + 0.2 * sin(angle * 8.0 + time * 2.0));
    float finalAngle = angle + time * (0.5 + layer * 0.1);
    
    return float2(cos(finalAngle) * patternRadius, sin(finalAngle) * patternRadius);
}

float2 generateGalaxyPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    float arms = 2.0 + complexity;
    float angle = t * arms * 2.0 * M_PI_F;
    
    // Logarithmic spiral for galaxy arms
    float radius = t * growthFactor * 150.0;
    float spiralAngle = angle + log(1.0 + radius * 0.01) * 2.0 + time * 0.4;
    
    // Add perturbations for realistic galaxy structure
    float noise = sin(spiralAngle * 3.0) * cos(radius * 0.1) * 15.0;
    radius += noise;
    
    return float2(cos(spiralAngle) * radius, sin(spiralAngle) * radius);
}

float2 generateDNAPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    float height = (t - 0.5) * growthFactor * 200.0;
    float twist = t * complexity * 4.0 * M_PI_F + time * 2.0;
    
    // Double helix structure
    float strand = fmod(float(index), 2.0);
    float phase = strand * M_PI_F;
    float radius = 30.0 + sin(twist * 0.5) * 10.0;
    
    float x = cos(twist + phase) * radius;
    float y = height;
    
    return float2(x, y);
}

float2 generateFractalPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Mandelbrot-inspired fractal
    float2 c = float2(-0.7 + complexity * 0.3, 0.0);
    float2 z = float2(0.0);
    
    // Iterate fractal equation
    for (int i = 0; i < 8; i++) {
        float2 temp = float2(z.x * z.x - z.y * z.y + c.x, 2.0 * z.x * z.y + c.y);
        z = temp;
        if (length(z) > 2.0) break;
    }
    
    float angle = t * 2.0 * M_PI_F + time * 0.5;
    float radius = length(z) * growthFactor * 20.0;
    
    return float2(cos(angle) * radius, sin(angle) * radius);
}

float2 generateNeuralPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Neural network-like structure
    int layer = int(t * (3.0 + complexity));
    float nodeInLayer = fmod(t * (3.0 + complexity), 1.0);
    
    float x = (float(layer) - 1.5) * 80.0 * growthFactor;
    float y = (nodeInLayer - 0.5) * 150.0 * growthFactor;
    
    // Add connections animation
    float connection = sin(time * 3.0 + t * 20.0) * 20.0;
    x += connection;
    
    return float2(x, y);
}

float2 generatePlasmaPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    float angle = t * 2.0 * M_PI_F;
    
    // Plasma-like electromagnetic field
    float field1 = sin(angle * 3.0 + time * 2.0) * 50.0;
    float field2 = cos(angle * 5.0 + time * 1.5) * 30.0;
    float field3 = sin(angle * 7.0 + time * 3.0) * 20.0;
    
    float radius = (field1 + field2 + field3) * growthFactor + 40.0;
    float finalAngle = angle + time * 1.0;
    
    return float2(cos(finalAngle) * radius, sin(finalAngle) * radius);
}

float2 generatePhoenixPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Wing curve mathematics
    float wingSpan = t * M_PI_F;
    float featherLayer = floor(t * (4.0 + complexity));
    float featherPos = fmod(t * (4.0 + complexity), 1.0);
    
    // Main wing curve (using Bezier-like mathematics)
    float wingCurve = sin(wingSpan) * cos(wingSpan * 0.5);
    float x = wingCurve * (80.0 + featherLayer * 20.0) * growthFactor;
    float y = (featherPos - 0.5) * (60.0 + sin(time * 2.0 + wingSpan) * 20.0) * growthFactor;
    
    // Add feather detail
    float featherWave = sin(featherPos * 8.0 + time * 3.0) * 5.0;
    x += featherWave * sin(wingSpan);
    
    // Wing flapping animation
    float flapPhase = sin(time * 4.0) * 0.3;
    float rotation = flapPhase + wingSpan * 0.2;
    
    float cosR = cos(rotation);
    float sinR = sin(rotation);
    float2 rotated = float2(x * cosR - y * sinR, x * sinR + y * cosR);
    
    return rotated;
}

// Shape 9: Crystal Lattice - 3D crystalline structure projection
float2 generateCrystalPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Create 3D lattice points
    int gridSize = int(2.0 + complexity * 2.0);
    int x3d = index % gridSize;
    int y3d = (index / gridSize) % gridSize;
    int z3d = index / (gridSize * gridSize);
    
    // Convert to normalized coordinates
    float3 latticePos = float3(
        float(x3d) / float(gridSize) - 0.5,
        float(y3d) / float(gridSize) - 0.5,
        float(z3d) / float(gridSize) - 0.5
    );
    
    // Apply crystal growth
    latticePos *= growthFactor * 100.0;
    
    // Rotate the crystal in 3D space
    float rotX = time * 0.5;
    float rotY = time * 0.7;
    float rotZ = time * 0.3;
    
    // 3D rotation matrices
    float3 rotated = latticePos;
    
    // Rotate around Y axis
    float cosY = cos(rotY);
    float sinY = sin(rotY);
    rotated = float3(
        rotated.x * cosY + rotated.z * sinY,
        rotated.y,
        -rotated.x * sinY + rotated.z * cosY
    );
    
    // Rotate around X axis
    float cosX = cos(rotX);
    float sinX = sin(rotX);
    rotated = float3(
        rotated.x,
        rotated.y * cosX - rotated.z * sinX,
        rotated.y * sinX + rotated.z * cosX
    );
    
    // Project to 2D with perspective
    float perspective = 1.0 / (1.0 + rotated.z * 0.002);
    return float2(rotated.x * perspective, rotated.y * perspective);
}

// Shape 10: Tornado Vortex - Swirling atmospheric phenomenon
float2 generateTornadoPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Vertical height distribution
    float height = (t - 0.5) * growthFactor * 200.0;
    float heightNorm = (height + 100.0) / 200.0; // Normalize height for calculations
    
    // Tornado funnel shape (narrow at bottom, wide at top)
    float funnelRadius = (0.1 + heightNorm * heightNorm) * 60.0 * growthFactor;
    
    // Spiral motion with varying speed by height
    float spiralSpeed = 3.0 + complexity * 2.0;
    float angle = t * spiralSpeed * 2.0 * M_PI_F + time * (2.0 + heightNorm * 3.0);
    
    // Add turbulence
    float turbulence1 = sin(height * 0.02 + time * 4.0) * 10.0;
    float turbulence2 = cos(angle * 3.0 + time * 2.0) * 5.0;
    
    float radius = funnelRadius + turbulence1 + turbulence2;
    
    return float2(cos(angle) * radius, height);
}

// Shape 11: Quantum Field - Particle physics visualization
float2 generateQuantumPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Quantum field fluctuations
    float field1 = sin(t * 10.0 + time * 3.0) * cos(t * 7.0 + time * 2.0);
    float field2 = sin(t * 13.0 + time * 4.0) * cos(t * 11.0 + time * 1.5);
    float field3 = sin(t * 17.0 + time * 2.5) * cos(t * 19.0 + time * 3.5);
    
    // Uncertainty principle visualization
    float uncertainty = complexity * 20.0;
    float positionUncertainty = (field1 + field2 * 0.5) * uncertainty;
    float momentumUncertainty = (field2 + field3 * 0.5) * uncertainty;
    
    // Wave-particle duality
    float waveAngle = t * 2.0 * M_PI_F * (1.0 + complexity);
    float particleRadius = growthFactor * 80.0;
    
    float x = cos(waveAngle + time) * particleRadius + positionUncertainty;
    float y = sin(waveAngle * 1.618 + time * 1.5) * particleRadius + momentumUncertainty;
    
    // Add quantum tunneling effect
    if (sin(time * 5.0 + t * 20.0) > 0.8) {
        x *= 1.5; // Particles "tunnel" to unexpected positions
        y *= 1.5;
    }
    
    return float2(x, y);
}

// Shape 12: Dragon Curve - Fractal dragon pattern
float2 generateDragonPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Dragon curve algorithm
    int iterations = int(4.0 + complexity * 3.0);
    float2 position = float2(0.0, 0.0);
    float2 direction = float2(1.0, 0.0);
    float stepSize = growthFactor * 5.0;
    
    int n = int(t * pow(2.0, float(iterations)));
    
    for (int i = 0; i < iterations; i++) {
        int bit = (n >> i) & 1;
        if (bit == 1) {
            // Turn right
            direction = float2(direction.y, -direction.x);
        } else {
            // Turn left
            direction = float2(-direction.y, direction.x);
        }
        position += direction * stepSize;
    }
    
    // Add organic movement
    float wave = sin(time * 2.0 + length(position) * 0.01) * 10.0;
    position += normalize(float2(-position.y, position.x)) * wave;
    
    return position;
}

// Shape 13: Fibonacci Sunflower - Natural growth pattern
float2 generateSunflowerPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Golden angle for optimal packing
    float goldenAngle = 2.399963229728653; // (3 - sqrt(5)) * π
    float angle = float(index) * goldenAngle + time * 0.2;
    
    // Fibonacci spiral radius
    float radius = sqrt(float(index)) * growthFactor * 3.0;
    
    // Add complexity with multiple spirals
    float multiSpiral = sin(angle * complexity) * 0.2 + 1.0;
    radius *= multiSpiral;
    
    // Sunflower head rotation
    float headRotation = time * 0.1;
    angle += headRotation;
    
    // Add natural growth oscillation
    float growth = sin(time * 2.0) * 0.1 + 1.0;
    radius *= growth;
    
    return float2(cos(angle) * radius, sin(angle) * radius);
}

// Shape 14: Magnetic Field Lines - Electromagnetic visualization
float2 generateMagneticPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Dipole configuration
    float2 pole1 = float2(-50.0 * growthFactor, 0.0);
    float2 pole2 = float2(50.0 * growthFactor, 0.0);
    
    // Field line parameter
    float fieldLine = floor(t * (8.0 + complexity * 4.0));
    float linePos = fmod(t * (8.0 + complexity * 4.0), 1.0);
    
    // Starting angle from pole
    float startAngle = (fieldLine / (8.0 + complexity * 4.0)) * 2.0 * M_PI_F;
    
    // Field line tracing (simplified)
    float angle = startAngle + linePos * M_PI_F;
    float radius = 30.0 * growthFactor * (1.0 + linePos * 2.0);
    
    float2 position = pole1 + float2(cos(angle) * radius, sin(angle) * radius);
    
    // Add field oscillation
    float oscillation = sin(time * 3.0 + fieldLine) * 10.0;
    position += normalize(position - pole1) * oscillation;
    
    return position;
}

// Shape 15: Mandelbrot Zoom - Fractal exploration
float2 generateMandelbrotPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Zoom into interesting Mandelbrot region
    float zoom = 1.0 + time * 0.1 * growthFactor;
    float2 center = float2(-0.7269, 0.1889); // Interesting region
    
    // Map particle index to complex plane
    float2 gridPos = float2(
        fmod(float(index), sqrt(float(totalParticles))),
        floor(float(index) / sqrt(float(totalParticles)))
    ) / sqrt(float(totalParticles));
    
    float2 c = center + (gridPos - 0.5) * (2.0 / zoom) * growthFactor;
    float2 z = float2(0.0);
    
    int maxIterations = int(10.0 + complexity * 10.0);
    int iterations = 0;
    
    for (int i = 0; i < maxIterations; i++) {
        if (length(z) > 2.0) break;
        z = float2(z.x * z.x - z.y * z.y + c.x, 2.0 * z.x * z.y + c.y);
        iterations++;
    }
    
    // Color based on iterations
    float escapeValue = float(iterations) / float(maxIterations);
    
    // Position based on final z value and escape time
    return z * 50.0 * growthFactor + c * 100.0;
}

// Shape 16: Lightning Network - Electrical discharge pattern
float2 generateLightningPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Main lightning bolt path
    float boltProgress = t;
    float x = (boltProgress - 0.5) * 200.0 * growthFactor;
    
    // Zigzag pattern
    float zigzag = sin(boltProgress * 20.0 * complexity) * 30.0 * growthFactor;
    float branch = sin(boltProgress * 40.0 + time * 10.0) * 15.0;
    
    float y = zigzag + branch;
    
    // Add fractal branches
    if (sin(boltProgress * 50.0 + time * 5.0) > 0.7) {
        float branchAngle = sin(boltProgress * 100.0) * 0.5;
        float branchLength = (1.0 - boltProgress) * 40.0 * growthFactor;
        x += cos(branchAngle) * branchLength;
        y += sin(branchAngle) * branchLength;
    }
    
    // Electrical flickering
    float flicker = sin(time * 20.0 + boltProgress * 10.0) * 5.0;
    x += flicker;
    y += flicker * 0.5;
    
    return float2(x, y);
}

// Shape 17: Celestial Orbit - Planetary system
float2 generateCelestialPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Orbital mechanics
    int orbitLevel = int(t * (3.0 + complexity * 2.0));
    float planetIndex = fmod(t * (3.0 + complexity * 2.0), 1.0);
    
    // Orbital parameters
    float orbitRadius = (float(orbitLevel) + 1.0) * 40.0 * growthFactor;
    float orbitSpeed = 1.0 / (float(orbitLevel) + 1.0); // Kepler's law approximation
    float planetAngle = planetIndex * 2.0 * M_PI_F + time * orbitSpeed;
    
    // Elliptical orbits
    float eccentricity = 0.1 + complexity * 0.2;
    float ellipseRadius = orbitRadius * (1.0 - eccentricity * cos(planetAngle));
    
    float2 position = float2(cos(planetAngle) * ellipseRadius, sin(planetAngle) * ellipseRadius);
    
    // Add orbital precession
    float precession = time * 0.1 * float(orbitLevel);
    float cosP = cos(precession);
    float sinP = sin(precession);
    position = float2(position.x * cosP - position.y * sinP, position.x * sinP + position.y * cosP);
    
    // Add moons for outer planets
    if (orbitLevel > 1) {
        float moonAngle = time * 5.0 + planetIndex * 20.0;
        float moonRadius = 10.0 * growthFactor;
        position += float2(cos(moonAngle) * moonRadius, sin(moonAngle) * moonRadius);
    }
    
    return position;
}

// Shape 18: Convolutional Neural Network - Layered feature maps
float2 generateCNNPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Simulate CNN layers
    int numLayers = int(3.0 + complexity * 2.0); // 3 to 5 layers
    int layer = int(t * float(numLayers));
    float layerT = fmod(t * float(numLayers), 1.0);
    
    // Grid-like feature map
    int gridSize = 8; // 8x8 feature map
    int xGrid = int(layerT * float(gridSize * gridSize)) % gridSize;
    int yGrid = int(layerT * float(gridSize * gridSize)) / gridSize;
    
    // Position in 3D space
    float x = (float(xGrid) / float(gridSize) - 0.5) * 100.0 * growthFactor;
    float y = (float(yGrid) / float(gridSize) - 0.5) * 100.0 * growthFactor;
    float z = float(layer) * 40.0 * growthFactor;
    
    // Convolution animation (feature map activation)
    float activation = sin(time * 2.0 + float(xGrid + yGrid) * 0.5) * 10.0;
    x += activation;
    y += activation;
    
    // Project to 2D with slight perspective
    float perspective = 1.0 / (1.0 + z * 0.002);
    return float2(x * perspective, y * perspective);
}

// Shape 19: Recurrent Neural Network - Sequential connections
float2 generateRNNPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Simulate RNN unrolling
    int sequenceLength = int(5.0 + complexity * 3.0); // 5 to 8 timesteps
    int timestep = int(t * float(sequenceLength));
    float stepT = fmod(t * float(sequenceLength), 1.0);
    
    // Circular path for each timestep
    float radius = 50.0 * growthFactor;
    float angle = stepT * 2.0 * M_PI_F + time * (0.5 + float(timestep) * 0.2);
    
    // Offset each timestep
    float x = float(timestep - sequenceLength / 2) * 60.0 * growthFactor;
    float y = cos(angle) * radius;
    
    // Add recurrent connection visualization
    float connection = sin(time * 3.0 + float(timestep) * 2.0) * 10.0;
    x += connection;
    
    return float2(x, y);
}

// Shape 20: Graph Neural Network - Dynamic graph structure
float2 generateGNNPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Simulate graph nodes
    int numClusters = int(3.0 + complexity * 2.0); // 3 to 5 clusters
    int cluster = int(t * float(numClusters));
    float clusterT = fmod(t * float(numClusters), 1.0);
    
    // Cluster center
    float clusterAngle = float(cluster) / float(numClusters) * 2.0 * M_PI_F;
    float clusterRadius = 100.0 * growthFactor;
    float2 clusterCenter = float2(cos(clusterAngle) * clusterRadius, sin(clusterAngle) * clusterRadius);
    
    // Node position within cluster
    float nodeAngle = clusterT * 2.0 * M_PI_F + time * 0.5;
    float nodeRadius = 30.0 * growthFactor;
    float2 nodeOffset = float2(cos(nodeAngle) * nodeRadius, sin(nodeAngle) * nodeRadius);
    
    // Add edge animation
    float edgePulse = sin(time * 4.0 + t * 10.0) * 5.0;
    float2 position = clusterCenter + nodeOffset + normalize(nodeOffset) * edgePulse;
    
    return position;
}

// Shape 21: Transformer Network - Attention mechanism
float2 generateTransformerPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Simulate attention heads
    int numHeads = int(2.0 + complexity * 2.0); // 2 to 4 attention heads
    int head = int(t * float(numHeads));
    float headT = fmod(t * float(numHeads), 1.0);
    
    // Token positions in a grid
    int gridSize = 6; // 6x6 token grid
    int xGrid = int(headT * float(gridSize * gridSize)) % gridSize;
    int yGrid = int(headT * float(gridSize * gridSize)) / gridSize;
    
    float x = (float(xGrid) / float(gridSize) - 0.5) * 150.0 * growthFactor;
    float y = (float(yGrid) / float(gridSize) - 0.5) * 150.0 * growthFactor;
    
    // Attention connection animation
    float attention = sin(time * 3.0 + float(head) * 2.0 + t * 5.0) * 20.0;
    x += attention * cos(float(head) * 2.0);
    y += attention * sin(float(head) * 2.0);
    
    return float2(x, y);
}

// Shape 22: Autoencoder Network - Bottleneck structure
float2 generateAutoencoderPosition(int index, float time, float complexity, float growthFactor, int totalParticles) {
    float t = float(index) / float(totalParticles);
    
    // Simulate encoder-decoder structure
    float bottleneckRatio = 0.3 + complexity * 0.2; // Controls bottleneck size
    float layerT = t * 2.0 - 1.0; // Map t to [-1, 1]
    
    // Funnel shape (wide -> narrow -> wide)
    float width = 100.0 * growthFactor * (1.0 - bottleneckRatio * cos(layerT * M_PI_F));
    float height = layerT * 150.0 * growthFactor;
    
    // Particle distribution within layer
    float angle = t * 2.0 * M_PI_F + time * 0.5;
    float x = cos(angle) * width;
    float y = height;
    
    // Add latent space vibration in bottleneck
    if (abs(layerT) < 0.2) {
        x += sin(time * 5.0 + t * 10.0) * 10.0;
        y += cos(time * 5.0 + t * 10.0) * 10.0;
    }
    
    return float2(x, y);
}


// MARK: - Main Compute Shader
kernel void updateParticles(device Particle* particles [[buffer(0)]],
                           constant Uniforms& uniforms [[buffer(1)]],
                           uint index [[thread_position_in_grid]]) {
    
    if (index >= uint(uniforms.particleCount)) {
        return;
    }
    
    Particle particle = particles[index];
    
    // Generate target position based on current shape mode
    float2 targetPos;
    switch (uniforms.shapeMode) {
        case 0: // Spiral
            targetPos = generateSpiralPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 1: // Flower
            targetPos = generateFlowerPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 2: // Mandala
            targetPos = generateMandalaPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 3: // Galaxy
            targetPos = generateGalaxyPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 4: // DNA
            targetPos = generateDNAPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 5: // Fractal
            targetPos = generateFractalPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 6: // Neural (Original)
            targetPos = generateNeuralPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 7: // Plasma
            targetPos = generatePlasmaPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 8: // Phoenix Wing
            targetPos = generatePhoenixPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 9: // Crystal Lattice
            targetPos = generateCrystalPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 10: // Tornado Vortex
            targetPos = generateTornadoPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 11: // Quantum Field
            targetPos = generateQuantumPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 12: // Dragon Curve
            targetPos = generateDragonPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 13: // Fibonacci Sunflower
            targetPos = generateSunflowerPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 14: // Magnetic Field
            targetPos = generateMagneticPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 15: // Mandelbrot Zoom
            targetPos = generateMandelbrotPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 16: // Lightning Network
            targetPos = generateLightningPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 17: // Celestial Orbit
            targetPos = generateCelestialPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 18: // Convolutional Neural Network
            targetPos = generateCNNPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 19: // Recurrent Neural Network
            targetPos = generateRNNPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 20: // Graph Neural Network
            targetPos = generateGNNPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 21: // Transformer Network
            targetPos = generateTransformerPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        case 22: // Autoencoder Network
            targetPos = generateAutoencoderPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
        default:
            targetPos = generateSpiralPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
            break;
    }
    
    // Smooth movement towards target with morphing
    float2 direction = targetPos - particle.position;
    float distance = length(direction);
    
    // Adaptive movement speed based on distance and morph speed
    float moveSpeed = uniforms.morphSpeed * 100.0 * uniforms.deltaTime;
    if (distance > moveSpeed) {
        particle.velocity = normalize(direction) * moveSpeed;
    } else {
        particle.velocity = direction;
    }
    
    // Apply movement
    particle.position += particle.velocity;
    
    // Add organic movement and noise
    float noise1 = sin(particle.position.x * 0.02 + uniforms.time * 2.0) *
                   cos(particle.position.y * 0.02 + uniforms.time * 1.5) * 3.0;
    float noise2 = sin(particle.position.x * 0.01 + uniforms.time * 1.2) *
                   cos(particle.position.y * 0.015 + uniforms.time * 0.8) * 2.0;
    
    particle.position += float2(noise1, noise2) * uniforms.deltaTime;
    
    // Dynamic color based on shape and position
    float t = float(index) / float(uniforms.particleCount);
    float hue = 0.0;
    
    switch (uniforms.shapeMode) {
        case 0: // Spiral - Rainbow gradient
            hue = t + uniforms.time * 0.1;
            break;
        case 1: // Flower - Warm colors
            hue = 0.0 + t * 0.3 + sin(uniforms.time * 2.0) * 0.1;
            break;
        case 2: // Mandala - Cool colors
            hue = 0.5 + t * 0.4 + sin(uniforms.time * 3.0) * 0.1;
            break;
        case 3: // Galaxy - Blue to white
            hue = 0.6 + t * 0.2;
            break;
        case 4: // DNA - Green to blue
            hue = 0.3 + t * 0.3;
            break;
        case 5: // Fractal - Purple spectrum
            hue = 0.8 + t * 0.4;
            break;
        case 6: // Neural (Original) - Electric blue
            hue = 0.55 + sin(uniforms.time * 4.0 + t * 10.0) * 0.1;
            break;
        case 7: // Plasma - Full spectrum
            hue = sin(uniforms.time * 2.0 + t * 6.28) * 0.5 + 0.5;
            break;
        case 8: // Phoenix Wing - Fire colors
            hue = 0.08 + t * 0.15 + sin(uniforms.time * 3.0) * 0.05;
            break;
        case 9: // Crystal Lattice - Prismatic
            hue = t * 1.0 + uniforms.time * 0.2;
            break;
        case 10: // Tornado - Storm colors
            hue = 0.15 + t * 0.2 + sin(uniforms.time * 4.0) * 0.1;
            break;
        case 11: // Quantum Field - Neon
            hue = 0.7 + sin(uniforms.time * 6.0 + t * 15.0) * 0.3;
            break;
        case 12: // Dragon Curve - Mystical
            hue = 0.25 + t * 0.4 + sin(uniforms.time * 2.0) * 0.1;
            break;
        case 13: // Sunflower - Natural
            hue = 0.12 + t * 0.1;
            break;
        case 14: // Magnetic Field - Electromagnetic
            hue = 0.65 + sin(uniforms.time * 5.0 + t * 8.0) * 0.1;
            break;
        case 15: // Mandelbrot - Fractal rainbow
            hue = t * 3.0 + uniforms.time * 0.3;
            break;
        case 16: // Lightning - Electric
            hue = 0.55 + sin(uniforms.time * 15.0) * 0.1;
            break;
        case 17: // Celestial - Cosmic
            hue = 0.6 + t * 0.3 + sin(uniforms.time + t * 10.0) * 0.1;
            break;
        case 18: // CNN - Deep blue gradient
            hue = 0.6 + t * 0.2 + sin(uniforms.time * 3.0) * 0.05;
            break;
        case 19: // RNN - Green sequential
            hue = 0.3 + t * 0.1 + sin(uniforms.time * 2.0) * 0.1;
            break;
        case 20: // GNN - Purple networked
            hue = 0.8 + t * 0.2 + sin(uniforms.time * 4.0) * 0.05;
            break;
        case 21: // Transformer - Cyan attention
            hue = 0.5 + t * 0.2 + sin(uniforms.time * 5.0) * 0.1;
            break;
        case 22: // Autoencoder - Orange bottleneck
            hue = 0.1 + t * 0.2 + sin(uniforms.time * 3.0) * 0.05;
            break;
        default:
            hue = t + uniforms.time * 0.1;
            break;
    }
    
    hue = fmod(hue, 1.0);
    float saturation = 0.7 + 0.3 * sin(uniforms.time * 2.0 + t * 4.0);
    float brightness = 0.8 + 0.2 * sin(uniforms.time * 3.0 + t * 2.0);
    
    // HSV to RGB conversion
    float c = brightness * saturation;
    float x = c * (1.0 - abs(fmod(hue * 6.0, 2.0) - 1.0));
    float m = brightness - c;
    
    float3 rgb;
    if (hue < 1.0/6.0) {
        rgb = float3(c, x, 0);
    } else if (hue < 2.0/6.0) {
        rgb = float3(x, c, 0);
    } else if (hue < 3.0/6.0) {
        rgb = float3(0, c, x);
    } else if (hue < 4.0/6.0) {
        rgb = float3(0, x, c);
    } else if (hue < 5.0/6.0) {
        rgb = float3(x, 0, c);
    } else {
        rgb = float3(c, 0, x);
    }
    
    particle.color = float4(rgb + m, 0.7 + 0.3 * sin(uniforms.time * 4.0 + t * 8.0));
    
    // Dynamic size based on shape and movement
    float baseSize = 2.0 + uniforms.growthFactor * 0.5;
    float velocitySize = length(particle.velocity) * 0.1;
    float pulseSize = sin(uniforms.time * 5.0 + t * 12.0) * 1.0;
    
    particle.size = baseSize + velocitySize + pulseSize;
    
    // Update life (used as phase substitute)
    particle.life = fmod(particle.life + uniforms.deltaTime * 2.0, 2.0 * M_PI_F);
    
    particles[index] = particle;
}
// MARK: - Vertex Shader
struct VertexOut {
    float4 position [[position]];
    float4 color;
    float pointSize [[point_size]];
    float phase;
};

vertex VertexOut particleVertexShader(const device Particle* particles [[buffer(0)]],
                                     constant Uniforms& uniforms [[buffer(1)]],
                                     uint vertexID [[vertex_id]]) {
    
    VertexOut out;
    
    Particle particle = particles[vertexID];
    
    // Convert world coordinates to normalized device coordinates
    float2 screenPos = particle.position / (uniforms.screenSize * 0.4);
    out.position = float4(screenPos, 0.0, 1.0);
    
    out.color = particle.color;
    out.pointSize = particle.size;
    out.phase = particle.life; // Use life as phase
    
    return out;
}

// MARK: - Advanced Fragment Shader
fragment float4 particleFragmentShader(VertexOut in [[stage_in]],
                                      float2 pointCoord [[point_coord]]) {
    
    // Create complex particle shapes
    float2 center = float2(0.5, 0.5);
    float2 uv = pointCoord - center;
    float dist = length(uv);
    
    // Multi-layer particle effect
    float core = 1.0 - smoothstep(0.0, 0.2, dist);
    float ring1 = 1.0 - smoothstep(0.2, 0.4, dist);
    float ring2 = 1.0 - smoothstep(0.4, 0.6, dist);
    float glow = 1.0 - smoothstep(0.0, 0.8, dist);
    
    // Animated patterns
    float angle = atan2(uv.y, uv.x);
    float spiral = sin(angle * 6.0 + in.phase * 2.0) * 0.3 + 0.7;
    float radial = sin(dist * 20.0 + in.phase) * 0.2 + 0.8;
    
    // Combine effects
    float intensity = core + ring1 * 0.6 * spiral + ring2 * 0.3 * radial + glow * 0.2;
    
    // Add sparkle effect
    float sparkle = sin(dist * 30.0 + in.phase * 3.0) * cos(angle * 8.0) * 0.15;
    intensity += sparkle * core;
    
    // Apply color with intensity
    float4 color = in.color * intensity;
    
    // Add chromatic aberration for advanced visual effect
    float2 aberration = uv * 0.02;
    color.r += sin(in.phase * 2.0) * 0.1;
    color.g += sin(in.phase * 2.0 + 2.0) * 0.1;
    color.b += sin(in.phase * 2.0 + 4.0) * 0.1;
    
    return color;
}

// MARK: - Shape Transition Compute Shader
kernel void transitionShapes(device Particle* particles [[buffer(0)]],
                            constant Uniforms& uniforms [[buffer(1)]],
                            uint index [[thread_position_in_grid]]) {
    
    if (index >= uint(uniforms.particleCount)) {
        return;
    }
    
    // Smooth transition between shapes over time
    float transitionTime = fmod(uniforms.time * 0.1, 8.0);
    int currentShape = int(transitionTime);
    int nextShape = (currentShape + 1) % 8;
    float blend = fmod(transitionTime, 1.0);
    
    // Generate positions for both shapes
    float2 currentPos, nextPos;
    
    // This would be expanded with all shape functions
    // For now,示例两个形状之间的插值
    if (currentShape == 0) {
        currentPos = generateSpiralPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
    } else if (currentShape == 1) {
        currentPos = generateFlowerPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
    }
    
    if (nextShape == 0) {
        nextPos = generateSpiralPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
    } else if (nextShape == 1) {
        nextPos = generateFlowerPosition(int(index), uniforms.time, uniforms.complexity, uniforms.growthFactor, uniforms.particleCount);
    }
    
    // Smooth interpolation
    float2 blendedPos = mix(currentPos, nextPos, smoothstep(0.0, 1.0, blend));
    particles[index].targetPosition = blendedPos;
}
