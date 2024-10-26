//
//  DataScannerView.swift
//  SafeBite
//
//  Created by Prathyush Yeturi on 8/10/24.
//  Made with code written by Alfian Losari on 6/25/22.
//

import Foundation
import SwiftUI
import VisionKit

struct DataScannerView: UIViewControllerRepresentable {
    
    @Binding var recognizedItems: [RecognizedItem]
    let recognizedDataType: DataScannerViewController.RecognizedDataType
    let recognizesMultipleItems: Bool
    let onScan: (([RecognizedItem]) -> Void)?
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: recognizesMultipleItems,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        vc.delegate = context.coordinator // Ensure delegate is set
        return vc
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        uiViewController.delegate = context.coordinator
        
        if uiViewController.isScanning { return }
        
        do {
            try uiViewController.startScanning()
        } catch {
            print("Failed to start scanning: \(error.localizedDescription)")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedItems: $recognizedItems, onScan: onScan)
    }
    
    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        
        @Binding var recognizedItems: [RecognizedItem]
        let onScan: (([RecognizedItem]) -> Void)?
        
        init(recognizedItems: Binding<[RecognizedItem]>, onScan: (([RecognizedItem]) -> Void)?) {
            self._recognizedItems = recognizedItems
            self.onScan = onScan
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            print("Tapped on item \(item)")
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            recognizedItems.append(contentsOf: addedItems)
            print("Added items: \(addedItems)")
            onScan?(addedItems)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            recognizedItems = recognizedItems.filter { item in
                !removedItems.contains { $0.id == item.id }
            }
            print("Removed items: \(removedItems)")
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            print("Scanner became unavailable: \(error.localizedDescription)")
        }
    }
}
