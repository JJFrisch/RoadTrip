//
//  NetworkStatusBanner.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import SwiftUI

struct NetworkStatusBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    @State private var showBanner = false
    
    var body: some View {
        VStack {
            if showBanner && !networkMonitor.isConnected {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Internet Connection")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Text("Showing cached or sample data")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            showBanner = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(8)
                    }
                }
                .padding()
                .background(Color.red.gradient)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: showBanner)
        .animation(.easeInOut, value: networkMonitor.isConnected)
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            if !isConnected {
                withAnimation {
                    showBanner = true
                }
            }
        }
        .onAppear {
            if !networkMonitor.isConnected {
                showBanner = true
            }
        }
    }
}

// MARK: - Inline Network Status Indicator
struct NetworkStatusIndicator: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(networkMonitor.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var statusText: String {
        if !networkMonitor.isConnected {
            return "Offline"
        }
        switch networkMonitor.connectionType {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .ethernet:
            return "Ethernet"
        case .unknown:
            return "Connected"
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        NetworkStatusBanner()
        
        Divider()
        
        NetworkStatusIndicator()
    }
}
