// Utilities/AnimationModifiers.swift
import SwiftUI

// MARK: - Transition Modifiers
struct ScaleAndFadeTransition: ViewModifier {
    let duration: Double
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.9)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    isVisible = true
                }
            }
    }
}

struct SlideInTransition: ViewModifier {
    let duration: Double
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isVisible ? 0 : 20)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    isVisible = true
                }
            }
    }
}

struct FadeTransition: ViewModifier {
    let duration: Double
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: duration)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Interactive Button Animation
struct InteractiveButtonModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1)
            .opacity(isPressed ? 0.8 : 1)
    }
}

// MARK: - Pulsing Animation
struct PulsingModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.05 : 1)
            .opacity(isAnimating ? 0.8 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Shake Animation
struct ShakeModifier: ViewModifier {
    @State private var shake = false
    let intensity: CGFloat = 10
    
    func body(content: Content) -> some View {
        content
            .offset(x: shake ? intensity : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                    shake = true
                }
            }
    }
}

// MARK: - Extension Methods
extension View {
    func scaleAndFadeTransition(duration: Double = AppTheme.Animation.normal) -> some View {
        modifier(ScaleAndFadeTransition(duration: duration))
    }
    
    func slideInTransition(duration: Double = AppTheme.Animation.normal) -> some View {
        modifier(SlideInTransition(duration: duration))
    }
    
    func fadeTransition(duration: Double = AppTheme.Animation.normal) -> some View {
        modifier(FadeTransition(duration: duration))
    }
    
    func interactiveButtonAnimation() -> some View {
        modifier(InteractiveButtonModifier())
    }
    
    func pulsing() -> some View {
        modifier(PulsingModifier())
    }
    
    func shake() -> some View {
        modifier(ShakeModifier())
    }
}

// MARK: - Smooth Geometry Transitions
extension AnyTransition {
    static var smoothScale: AnyTransition {
        AnyTransition.scale.combined(with: .opacity)
    }
    
    static var smoothSlide: AnyTransition {
        AnyTransition.move(edge: .bottom).combined(with: .opacity)
    }
}
