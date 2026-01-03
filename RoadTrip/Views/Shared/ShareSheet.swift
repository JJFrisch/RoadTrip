// Views/Shared/ShareSheet.swift
import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var fileName: String? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // If we have PDF data and a filename, create a temporary file
        var activityItems: [Any] = []
        
        for item in items {
            if let data = item as? Data, let fileName = fileName {
                // Save to temp directory with the filename
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try? data.write(to: tempURL)
                activityItems.append(tempURL)
            } else {
                activityItems.append(item)
            }
        }
        
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
