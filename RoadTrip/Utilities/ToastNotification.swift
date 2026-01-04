//
//  ToastNotification.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import SwiftUI

// MARK: - Toast Manager
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var currentToast: Toast?
    @Published var showingToast = false
    
    private var toastQueue: [Toast] = []
    private var isProcessingQueue = false
    
    private init() {}
    
    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let type: ToastType
        let duration: TimeInterval
        
        enum ToastType {
            case success
            case warning
            case error
            case info
            
            var icon: String {
                switch self {
                case .success: return "checkmark.circle.fill"
                case .warning: return "exclamationmark.triangle.fill"
                case .error: return "xmark.circle.fill"
                case .info: return "info.circle.fill"
                }
            }
            
            var color: Color {
                switch self {
                case .success: return .green
                case .warning: return .orange
                case .error: return .red
                case .info: return .blue
                }
            }
        }
    }
    
    func show(_ message: String, type: Toast.ToastType = .info, duration: TimeInterval = 3.0) {
        let toast = Toast(message: message, type: type, duration: duration)
        
        DispatchQueue.main.async {
            self.toastQueue.append(toast)
            if !self.isProcessingQueue {
                self.processQueue()
            }
        }
    }
    
    private func processQueue() {
        guard !toastQueue.isEmpty else {
            isProcessingQueue = false
            return
        }
        
        isProcessingQueue = true
        let toast = toastQueue.removeFirst()
        
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.currentToast = toast
                self.showingToast = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.showingToast = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.currentToast = nil
                    self.processQueue()
                }
            }
        }
    }
    
    func dismiss() {
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.showingToast = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.currentToast = nil
                self.processQueue()
            }
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let toast: ToastManager.Toast
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.title3)
                .foregroundStyle(toast.type.color)
            
            Text(toast.message)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(3)
            
            Spacer(minLength: 0)
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}

// MARK: - Toast View Modifier
struct ToastModifier: ViewModifier {
    @ObservedObject var manager = ToastManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if manager.showingToast, let toast = manager.currentToast {
                    ToastView(toast: toast, onDismiss: manager.dismiss)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: manager.showingToast)
                }
                
                Spacer()
            }
            .zIndex(999)
        }
    }
}

extension View {
    func withToast() -> some View {
        modifier(ToastModifier())
    }
}
