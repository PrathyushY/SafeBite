//
//  AppViewModel.swift
//  BarcodeTextScanner
//
//  Created by Alfian Losari on 6/25/22.
//  Modified for use on this project by Prathyush Yeturi on 8/13/2024
//

import AVKit
import Foundation
import SwiftUI
import VisionKit

enum ScanType: String {
    case barcode, text
}

enum DataScannerAccessStatusType {
    case notDetermined
    case cameraAccessNotGranted
    case cameraNotAvailable
    case scannerAvailable
    case scannerNotAvailable
}

@MainActor
final class AppViewModel: ObservableObject {
    
    @Published var dataScannerAccessStatus: DataScannerAccessStatusType = .notDetermined
    @Published var recognizedItems: [RecognizedItem] = []
    @Published var scanType: ScanType = .barcode
    @Published var textContentType: DataScannerViewController.TextContentType?
    @Published var recognizesMultipleItems = true
    
    public func fetchProductInfo(barcode: String) {
        let baseURL = "https://world.openfoodfacts.org/api/v0/product/"
        guard let url = URL(string: "\(baseURL)\(barcode).json") else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Failed to retrieve data: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                print("Failed to retrieve data. Status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let status = json["status"] as? Int, status == 1 {
                        if let product = json["product"] as? [String: Any] {
                            DispatchQueue.main.async {
                                // Handle the product information as needed
                                print("Product Information:")
                                print("With Additives: \(product["with_additives"] as? String ?? "N/A")")
                                print("Name: \(product["product_name"] as? String ?? "N/A")")
                                print("Brand: \(product["brands"] as? String ?? "N/A")")
                                print("Quantity: \(product["quantity"] as? String ?? "N/A")")
                                print("Ingredients: \(product["ingredients_text"] as? String ?? "N/A")")
                                print("Nutrition Score: \(product["nutriscore_score"] as? Int ?? -1)")
                                print("Image URL: \(product["image_url"] as? String ?? "N/A")")
                            }
                        }
                    } else {
                        print("Product not found.")
                    }
                }
            } catch {
                print("Failed to parse JSON: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    var recognizedDataType: DataScannerViewController.RecognizedDataType {
        scanType == .barcode ? .barcode() : .text(textContentType: textContentType)
    }
    
    var headerText: String {
        if recognizedItems.isEmpty {
            return "Scanning \(scanType.rawValue)"
        } else {
            return "Recognized \(recognizedItems.count) item(s)"
        }
    }
    
      var dataScannerViewId: Int {
        var hasher = Hasher()
        hasher.combine(scanType)
        hasher.combine(recognizesMultipleItems)
        if let textContentType {
            hasher.combine(textContentType)
        }
        return hasher.finalize()
    }
    
    private var isScannerAvailable: Bool {
        DataScannerViewController.isAvailable && DataScannerViewController.isSupported
    }
    
    func requestDataScannerAccessStatus() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            dataScannerAccessStatus = .cameraNotAvailable
            return
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            
        case .authorized:
            dataScannerAccessStatus = isScannerAvailable ? .scannerAvailable : .scannerNotAvailable
            
        case .restricted, .denied:
            dataScannerAccessStatus = .cameraAccessNotGranted
            
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                dataScannerAccessStatus = isScannerAvailable ? .scannerAvailable : .scannerNotAvailable
            } else {
                dataScannerAccessStatus = .cameraAccessNotGranted
            }
        
        default: break
            
        }
    }
}
