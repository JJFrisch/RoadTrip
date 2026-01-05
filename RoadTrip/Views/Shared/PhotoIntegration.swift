//
//  PhotoIntegration.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import Foundation
import SwiftUI
import PhotosUI

// MARK: - Photo Picker
struct ActivityPhotoPicker: View {
    @Bindable var activity: Activity
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Photo Gallery
            if !activity.photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(activity.photos.enumerated()), id: \.offset) { index, photoData in
                            if let uiImage = UIImage(data: photoData) {
                                PhotoThumbnailView(image: uiImage, onDelete: {
                                    deletePhoto(at: index)
                                })
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 120)
            }
            
            // Photo Picker Button
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 10,
                matching: .images
            ) {
                Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    await loadPhotos(from: newItems)
                }
            }
            
            if isLoading {
                ProgressView("Loading photos...")
            }
        }
    }
    
    func loadPhotos(from items: [PhotosPickerItem]) async {
        await MainActor.run {
            isLoading = true
        }
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                // Generate thumbnail
                if let thumbnail = generateThumbnail(from: data) {
                    await MainActor.run {
                        activity.photos.append(data)
                        activity.photoThumbnails.append(thumbnail)
                    }
                }
            }
        }
        
        await MainActor.run {
            isLoading = false
            selectedItems.removeAll()
        }
    }
    
    func generateThumbnail(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        
        let targetSize = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        let thumbnail = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return thumbnail.jpegData(compressionQuality: 0.7)
    }
    
    func deletePhoto(at index: Int) {
        guard index < activity.photos.count else { return }
        activity.photos.remove(at: index)
        if index < activity.photoThumbnails.count {
            activity.photoThumbnails.remove(at: index)
        }
    }
}

struct PhotoThumbnailView: View {
    let image: UIImage
    let onDelete: () -> Void
    
    @State private var showingFullScreen = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    showingFullScreen = true
                }
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .background(Circle().fill(.black.opacity(0.5)))
            }
            .padding(4)
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            PhotoViewerView(image: image)
        }
    }
}

struct PhotoViewerView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                            
                            // Reset if zoomed out too far
                            if scale < 1.0 {
                                withAnimation {
                                    scale = 1.0
                                    lastScale = 1.0
                                }
                            }
                        }
                )
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

// MARK: - Photo Gallery View
struct PhotoGalleryView: View {
    let activity: Activity
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(activity.photos.enumerated()), id: \.offset) { index, photoData in
                    if let uiImage = UIImage(data: photoData) {
                        GalleryThumbnail(image: uiImage)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Photos")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GalleryThumbnail: View {
    let image: UIImage
    @State private var showingFullScreen = false
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 110, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                showingFullScreen = true
            }
            .fullScreenCover(isPresented: $showingFullScreen) {
                PhotoViewerView(image: image)
            }
    }
}

// MARK: - Camera Integration
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct CameraButton: View {
    @Bindable var activity: Activity
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        Button {
            showingCamera = true
        } label: {
            Label("Take Photo", systemImage: "camera.fill")
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(image: $capturedImage)
        }
        .onChange(of: capturedImage) { _, newImage in
            if let image = newImage, let data = image.jpegData(compressionQuality: 0.8) {
                activity.photos.append(data)
                
                // Generate thumbnail
                if let thumbnail = generateThumbnail(from: image) {
                    activity.photoThumbnails.append(thumbnail)
                }
                
                capturedImage = nil
            }
        }
    }
    
    func generateThumbnail(from image: UIImage) -> Data? {
        let targetSize = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        let thumbnail = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return thumbnail.jpegData(compressionQuality: 0.7)
    }
}

// MARK: - PDF Export with Photos
extension PDFExportService {
    func generateTripPDFWithPhotos(trip: Trip) -> Data? {
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yOffset: CGFloat = 40
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24)
            ]
            let title = trip.name as NSString
            title.draw(at: CGPoint(x: 40, y: yOffset), withAttributes: titleAttributes)
            yOffset += 40
            
            // Date range
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateRange = "\(dateFormatter.string(from: trip.startDate)) - \(dateFormatter.string(from: trip.endDate))"
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.gray
            ]
            (dateRange as NSString).draw(at: CGPoint(x: 40, y: yOffset), withAttributes: dateAttributes)
            yOffset += 40
            
            // Days and activities with photos
            for day in trip.days.sorted(by: { $0.dayNumber < $1.dayNumber }) {
                // Check if we need a new page
                if yOffset > pageRect.height - 100 {
                    context.beginPage()
                    yOffset = 40
                }
                
                // Day header
                let dayTitle = "Day \(day.dayNumber)" as NSString
                let dayAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18)
                ]
                dayTitle.draw(at: CGPoint(x: 40, y: yOffset), withAttributes: dayAttributes)
                yOffset += 30
                
                // Activities
                for activity in day.activities.sorted(by: { $0.order < $1.order }) {
                    // Activity name
                    let activityName = activity.name as NSString
                    let activityAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12)
                    ]
                    activityName.draw(at: CGPoint(x: 60, y: yOffset), withAttributes: activityAttributes)
                    yOffset += 20
                    
                    // Photos (first 3 per activity)
                    let photosToShow = activity.photos.prefix(3)
                    if !photosToShow.isEmpty {
                        let photoSize: CGFloat = 100
                        var xOffset: CGFloat = 60
                        
                        for photoData in photosToShow {
                            if let image = UIImage(data: photoData) {
                                let photoRect = CGRect(x: xOffset, y: yOffset, width: photoSize, height: photoSize)
                                image.draw(in: photoRect)
                                xOffset += photoSize + 10
                            }
                        }
                        
                        yOffset += photoSize + 20
                    }
                    
                    // Check page overflow
                    if yOffset > pageRect.height - 150 {
                        context.beginPage()
                        yOffset = 40
                    }
                }
                
                yOffset += 20
            }
        }
        
        return data
    }
}
