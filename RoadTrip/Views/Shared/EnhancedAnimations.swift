//
//  EnhancedAnimations.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import SwiftUI

// MARK: - Activity Card Animations

struct AnimatedActivityCard: View {
    let activity: Activity
    @State private var isPressed = false
    @State private var showCheckmark = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        ZStack {
            // Card background with animated shadow
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(
                    color: Color.black.opacity(isPressed ? 0.3 : 0.1),
                    radius: isPressed ? 8 : 4,
                    x: 0,
                    y: isPressed ? 4 : 2
                )
            
            HStack(spacing: 12) {
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(activity.isCompleted ? Color.green : Color.blue)
                        .scaleEffect(showCheckmark ? 1.0 : 0.8, anchor: .center)
                    
                    Image(systemName: activity.isCompleted ? "checkmark" : "circle")
                        .foregroundStyle(.white)
                        .font(.headline)
                }
                .frame(width: 40, height: 40)
                .onAppear {
                    if !reduceMotion {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            showCheckmark = true
                        }
                    } else {
                        showCheckmark = true
                    }
                }
                
                // Content with fade-in
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let time = activity.scheduledTime {
                        Text(time, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .opacity(showCheckmark ? 1.0 : 0.5)
                
                Spacer()
                
                // Arrow animation on press
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isPressed ? 45 : 0))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .scaleEffect(isPressed ? 1.1 : 1.0)
            }
            .padding()
        }
        .frame(height: 80)
        .scaleEffect(isPressed ? 0.98 : 1.0, anchor: .center)
        .onTapGesture { }
        .onLongPressGesture(minimumDuration: 0.1) { pressed in
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isPressed = pressed
                }
            }
        }
    }
}

// MARK: - Map Pin Animations

struct AnimatedMapPin: View {
    let activity: Activity
    let isVisible: Bool
    
    @State private var scale: CGFloat = 0
    @State private var rotation: Double = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        ZStack {
            // Pulse effect
            Circle()
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                .scaleEffect(scale)
                .onAppear {
                    if !reduceMotion {
                        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            scale = 1.5
                        }
                    }
                }
            
            // Pin with bounce animation
            VStack(spacing: 0) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.red)
                
                Image(systemName: "triangle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.red)
                    .offset(y: -3)
            }
            .scaleEffect(isVisible ? 1.0 : 0.0)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                if !reduceMotion {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                        rotation = 0
                    }
                } else {
                    rotation = 0
                }
            }
        }
    }
}

// MARK: - Pull-to-Refresh Animation

struct PullToRefreshView: View {
    @State private var isRefreshing = false
    @State private var scrollOffset: CGFloat = 0
    let onRefresh: () async -> Void
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var refreshProgress: CGFloat {
        min(scrollOffset / 80, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Refresh indicator
            if scrollOffset > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .rotationEffect(.degrees(scrollOffset > 80 ? 180 : 0))
                        .scaleEffect(refreshProgress)
                    
                    Text(scrollOffset > 80 ? "Release to refresh" : "Pull to refresh")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if isRefreshing {
                        ProgressView()
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .transition(.move(edge: .top))
            }
            
            Spacer()
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollOffset = 0
                }
            }
        }
    }
}

// MARK: - Loading State Animations

struct AnimatedLoadingView: View {
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1.0
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(spacing: 16) {
            // Rotating loading spinner
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .rotationEffect(.degrees(rotation))
                
                Image(systemName: "car.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .frame(width: 60, height: 60)
            .onAppear {
                if !reduceMotion {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
            
            // Pulsing text
            Text("Loading your trip...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .opacity(opacity)
                .onAppear {
                    if !reduceMotion {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            opacity = 0.5
                        }
                    }
                }
        }
    }
}

// MARK: - Transition Animations

struct ActivityCardTransition: View {
    let activity: Activity
    @State private var isVisible = false
    
    var body: some View {
        AnimatedActivityCard(activity: activity)
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Expandable List Item Animation

struct ExpandableActivityItem: View {
    let activity: Activity
    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.headline)
                    
                    if let time = activity.scheduledTime {
                        Text(time, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .foregroundStyle(.secondary)
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture {
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } else {
                    isExpanded.toggle()
                }
            }
            
            // Expanded content
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    if let location = activity.location {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                            Text(location)
                        }
                        .font(.subheadline)
                    }
                    
                    if let notes = activity.notes {
                        HStack(spacing: 8) {
                            Image(systemName: "note.text")
                                .foregroundStyle(.blue)
                            Text(notes)
                        }
                        .font(.caption)
                    }
                    
                    if let cost = activity.estimatedCost {
                        HStack(spacing: 8) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundStyle(.green)
                            Text("$\(cost, specifier: "%.2f")")
                        }
                        .font(.subheadline)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Shared Transition Effects

struct SharedElementTransition<ID: Hashable>: View {
    let item: ID
    let namespace: Namespace.ID
    @ViewBuilder let content: () -> some View
    
    var body: some View {
        content()
            .matchedGeometryEffect(id: item, in: namespace)
    }
}

// MARK: - List Animation Helper

extension View {
    func listItemAnimation(index: Int, delay: Double = 0.05) -> some View {
        self
            .transition(.opacity.combined(with: .move(edge: .trailing)))
            .animation(
                .easeOut(duration: 0.3).delay(Double(index) * 0.05),
                value: index
            )
    }
}

// MARK: - Haptic Feedback for Animations

struct HapticAnimationView<Content: View>: View {
    let hapticOnAppear: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
            .onAppear {
                if hapticOnAppear {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                }
            }
    }
}

// MARK: - Animated Progress Ring

struct AnimatedProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat = 8
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            
            // Animated progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    reduceMotion
                        ? .linear(duration: 0.1)
                        : .easeInOut(duration: 0.3),
                    value: progress
                )
            
            // Center text
            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 100, height: 100)
    }
}
