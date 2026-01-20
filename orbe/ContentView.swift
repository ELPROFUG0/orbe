//
//  ContentView.swift
//  orbe
//
//  Dream Machine - Orb Image Editor with Metal Shaders
//

import SwiftUI
import PhotosUI
import Combine

struct ContentView: View {
    // Effect parameters
    @State private var motionEnabled = true
    @State private var motionSpeed: Double = 0.26
    @State private var motionStrength: Double = 0.05
    @State private var motionFrequency: Double = 0.24
    @State private var motionNoise: Double = 0.5

    @State private var glowIntensity: Double = 0.5
    @State private var lightIntensity: Double = 0.3
    @State private var edgeIntensity: Double = 0.5
    @State private var lensIntensity: Double = 0.7
    @State private var reflectionIntensity: Double = 0.5

    @State private var selectedTab: Int = 0
    @State private var showControls = true

    // Image selection
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    // Animation
    @State private var animationTime: Double = 0
    let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                Spacer()

                // Orb with Metal shader effects
                DropletOrbView(
                    image: selectedImage,
                    time: animationTime,
                    motionEnabled: motionEnabled,
                    motionSpeed: motionSpeed,
                    motionStrength: motionStrength,
                    motionFrequency: motionFrequency,
                    motionNoise: motionNoise,
                    glowIntensity: glowIntensity,
                    lightIntensity: lightIntensity,
                    edgeIntensity: edgeIntensity,
                    lensIntensity: lensIntensity,
                    reflectionIntensity: reflectionIntensity
                )
                .frame(height: UIScreen.main.bounds.height * 0.5)

                Spacer()

                if showControls {
                    controlsSection
                }
            }
        }
        .onTapGesture {
            if !showControls {
                withAnimation { showControls = true }
            }
        }
        .onReceive(timer) { _ in
            if motionEnabled {
                animationTime += 1/60
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
        .onAppear {
            loadDefaultImage()
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dream")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .italic()
                Text("MACHINE")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.7))
            }
            .foregroundColor(.white)

            Spacer()

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // MARK: - Controls Section
    private var controlsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Hide") {
                    withAnimation { showControls = false }
                }
                .foregroundColor(.white.opacity(0.6))

                Spacer()

                Button("Reset") {
                    resetCurrentTab()
                }
                .foregroundColor(.white.opacity(0.6))
            }
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 20)

            tabSelector
                .padding(.vertical, 12)

            controlsView
                .padding(.bottom, 30)
        }
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "MOTION", icon: "waveform", index: 0)
            tabButton(title: "VISUAL", icon: "sparkles", index: 1)
        }
        .background(Capsule().fill(Color.white.opacity(0.1)))
        .padding(.horizontal, 60)
    }

    private func tabButton(title: String, icon: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(selectedTab == index ? .white : .white.opacity(0.4))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                selectedTab == index ?
                Capsule().fill(Color.white.opacity(0.15)) : nil
            )
        }
    }

    // MARK: - Controls
    private var controlsView: some View {
        VStack(spacing: 14) {
            if selectedTab == 0 {
                toggleRow(title: "Animate", isOn: $motionEnabled)
                sliderRow(title: "Speed", value: $motionSpeed, range: 0...1)
                sliderRow(title: "Strength", value: $motionStrength, range: 0...0.2)
                sliderRow(title: "Frequency", value: $motionFrequency, range: 0...1)
                sliderRow(title: "Noise", value: $motionNoise, range: 0...1)
            } else {
                sliderRow(title: "Glow", value: $glowIntensity, range: 0...1)
                sliderRow(title: "Light", value: $lightIntensity, range: 0...1)
                sliderRow(title: "Edge", value: $edgeIntensity, range: 0...1)
                sliderRow(title: "Lens", value: $lensIntensity, range: 0...1)
                sliderRow(title: "Reflection", value: $reflectionIntensity, range: 0...1)
            }
        }
        .padding(.horizontal, 24)
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            Slider(value: value, in: range)
                .tint(.cyan)
        }
    }

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Toggle("", isOn: isOn)
                .tint(.green)
        }
    }

    private func resetCurrentTab() {
        if selectedTab == 0 {
            motionEnabled = true
            motionSpeed = 0.26
            motionStrength = 0.05
            motionFrequency = 0.24
            motionNoise = 0.5
        } else {
            glowIntensity = 0.5
            lightIntensity = 0.3
            edgeIntensity = 0.5
            lensIntensity = 0.7
            reflectionIntensity = 0.5
        }
    }

    private func loadDefaultImage() {
        if let image = UIImage(named: "sample") {
            selectedImage = image
        }
    }
}

// MARK: - Droplet Orb View with Metal Shader
struct DropletOrbView: View {
    let image: UIImage?
    let time: Double
    let motionEnabled: Bool
    let motionSpeed: Double
    let motionStrength: Double
    let motionFrequency: Double
    let motionNoise: Double
    let glowIntensity: Double
    let lightIntensity: Double
    let edgeIntensity: Double
    let lensIntensity: Double
    let reflectionIntensity: Double

    var body: some View {
        GeometryReader { geo in
            let orbSize = min(geo.size.width, geo.size.height) * 0.88

            ZStack {
                // Main orb with shader AND wavy border distortion
                if let uiImage = image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: orbSize, height: orbSize)
                        .clipShape(Circle())
                        // Fisheye lens effect
                        .modifier(
                            DropletShaderModifier(
                                size: CGSize(width: orbSize, height: orbSize),
                                time: time,
                                motionSpeed: motionSpeed,
                                motionStrength: motionEnabled ? motionStrength : 0,
                                motionFrequency: motionFrequency,
                                motionNoise: motionNoise,
                                lightIntensity: lightIntensity,
                                edgeIntensity: edgeIntensity,
                                lensIntensity: lensIntensity
                            )
                        )
                        .clipShape(Circle())
                        .overlay(orbOverlays(size: orbSize, reflectionIntensity: reflectionIntensity))
                        // Wavy border distortion - makes the circle wobble like jelly
                        .modifier(
                            WavyBorderModifier(
                                size: CGSize(width: orbSize, height: orbSize),
                                time: time,
                                enabled: motionEnabled,
                                speed: motionSpeed,
                                strength: motionStrength,
                                frequency: motionFrequency,
                                noise: motionNoise
                            )
                        )
                } else {
                    placeholderOrb(size: orbSize)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Orb Overlays
    private func orbOverlays(size: CGFloat, reflectionIntensity: Double) -> some View {
        ZStack {
            // GLOW effect - concentrated white glow from edge inward
            if glowIntensity > 0.01 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(glowIntensity * 0.6),
                                Color.white.opacity(glowIntensity * 0.9)
                            ],
                            center: .center,
                            startRadius: size * (0.4 - glowIntensity * 0.2),
                            endRadius: size * 0.5
                        )
                    )
                    .blur(radius: 3 + glowIntensity * 2)
            }

            // Light/vignette effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(lightIntensity * 0.4)
                        ],
                        center: .center,
                        startRadius: size * 0.15,
                        endRadius: size * 0.5
                    )
                )

            // Edge effect - soft gradient pushing inward
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.clear,
                            Color.clear,
                            Color.black.opacity(edgeIntensity * 0.15),
                            Color.black.opacity(edgeIntensity * 0.3),
                            Color.black.opacity(edgeIntensity * 0.5)
                        ],
                        center: .center,
                        startRadius: size * (0.25 - edgeIntensity * 0.1),
                        endRadius: size * 0.5
                    )
                )

            // Reflection highlights on the EDGE of the orb
            if reflectionIntensity > 0.01 {
                // Main highlight arc on top-left edge
                Circle()
                    .trim(from: 0.58, to: 0.82)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.5 * reflectionIntensity),
                                Color.white.opacity(0.7 * reflectionIntensity),
                                Color.white.opacity(0.5 * reflectionIntensity),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: size * 0.04, lineCap: .round)
                    )
                    .blur(radius: 4)

                // Sharp highlight on edge
                Circle()
                    .trim(from: 0.62, to: 0.76)
                    .stroke(
                        Color.white.opacity(0.6 * reflectionIntensity),
                        style: StrokeStyle(lineWidth: size * 0.015, lineCap: .round)
                    )
                    .blur(radius: 1)

                // Subtle bottom-right edge reflection
                Circle()
                    .trim(from: 0.12, to: 0.28)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.15 * reflectionIntensity),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: size * 0.025, lineCap: .round)
                    )
                    .blur(radius: 3)

                // Thin edge ring
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4 * reflectionIntensity),
                                Color.white.opacity(0.15 * reflectionIntensity),
                                Color.white.opacity(0.05 * reflectionIntensity),
                                Color.white.opacity(0.1 * reflectionIntensity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            }
        }
    }

    private func placeholderOrb(size: CGFloat) -> some View {
        Circle()
            .fill(Color.white.opacity(0.03))
            .frame(width: size, height: size)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "drop.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.15))
                    Text("Select an image")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.25))
                }
            )
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - Droplet Shader Modifier (internal image distortion)
struct DropletShaderModifier: ViewModifier {
    let size: CGSize
    let time: Double
    let motionSpeed: Double
    let motionStrength: Double
    let motionFrequency: Double
    let motionNoise: Double
    let lightIntensity: Double
    let edgeIntensity: Double
    let lensIntensity: Double

    func body(content: Content) -> some View {
        content
            .layerEffect(
                ShaderLibrary.dropletEffect(
                    .float2(size),
                    .float(time),
                    .float(motionSpeed),
                    .float(motionStrength),
                    .float(motionFrequency),
                    .float(motionNoise),
                    .float(lightIntensity),
                    .float(edgeIntensity),
                    .float(lensIntensity)
                ),
                maxSampleOffset: CGSize(width: 100, height: 100)
            )
    }
}

// MARK: - Wavy Border Modifier (distorts the shape with waves)
struct WavyBorderModifier: ViewModifier {
    let size: CGSize
    let time: Double
    let enabled: Bool
    let speed: Double
    let strength: Double
    let frequency: Double
    let noise: Double

    func body(content: Content) -> some View {
        if enabled && strength > 0 {
            content
                .distortionEffect(
                    ShaderLibrary.wavyDistortion(
                        .float2(size),
                        .float(time),
                        .float(speed),
                        .float(strength),
                        .float(frequency),
                        .float(noise)
                    ),
                    maxSampleOffset: CGSize(width: 50, height: 50)
                )
        } else {
            content
        }
    }
}

#Preview {
    ContentView()
}
