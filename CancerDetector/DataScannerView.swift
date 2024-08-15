//
//  DataScannerView.swift
//  BarcodeTextScanner
//
//  Created by Prathyush Yeturi on 6/13/2024
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
            recognizedDataTypes: [recognizedDataType],
            qualityLevel: .balanced,
            recognizesMultipleItems: recognizesMultipleItems,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        return vc
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        uiViewController.delegate = context.coordinator
        try? uiViewController.startScanning()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedItems: $recognizedItems, onScan: onScan)
    }
    
    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        
        @Binding var recognizedItems: [RecognizedItem]
        let onScan: (([RecognizedItem]) -> Void)?  // Add this property
        
        init(recognizedItems: Binding<[RecognizedItem]>, onScan: (([RecognizedItem]) -> Void)?) {
            self._recognizedItems = recognizedItems
            self.onScan = onScan
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            print("didTapOn \(item)")
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            recognizedItems.append(contentsOf: addedItems)
            print("didAddItems \(addedItems)")
            
            // Handle scanning result
            onScan?(addedItems)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            self.recognizedItems = recognizedItems.filter { item in
                !removedItems.contains(where: {$0.id == item.id })
            }
            print("didRemovedItems \(removedItems)")
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            print("became unavailable with error \(error.localizedDescription)")
        }
    }
}
