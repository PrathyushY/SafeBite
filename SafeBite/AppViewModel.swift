import AVKit
import Foundation
import SwiftUI
import SwiftData
import VisionKit

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
    @Published var showNutritionInfo = false
    
    public func fetchProductInfo(barcode: String, modelContext: ModelContext, completion: @escaping (Product?) -> Void) {
        let baseURL = "https://world.openfoodfacts.org/api/v0/product/"
        guard let url = URL(string: "\(baseURL)\(barcode).json") else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Failed to retrieve data: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                print("Failed to retrieve data. Status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let status = json["status"] as? Int, status == 1,
                   let productJson = json["product"] as? [String: Any] {
                    
                    let foodProcessingRating: String = {
                        if let novaGroupsTags = productJson["nova_groups_tags"] as? [String], !novaGroupsTags.isEmpty {
                            return novaGroupsTags[0] // Return the first item if available
                        }
                        return "N/A" // Default if no valid data is found
                    }()
                    
                    // Extract calories from 'nutriments'
                    let calories: Int = {
                        if let nutriments = productJson["nutriments"] as? [String: Any],
                           let energyKcal = nutriments["energy-kcal"] as? Double {
                            return Int(energyKcal) // Cast to Int since calories are usually whole numbers
                        }
                        return 0 // Default if no valid data is found
                    }()

                    let newProduct = Product(
                        name: productJson["product_name"] as? String ?? "N/A",
                        brand: productJson["brands"] as? String ?? "N/A",
                        quantity: productJson["quantity"] as? String ?? "N/A",
                        ingredients: productJson["ingredients_text"] as? String ?? "N/A",
                        nutritionScore: productJson["nutriscore_score"] as? Int ?? 0,
                        ecoScore: productJson["ecoscore_score"] as? Int ?? 0, // Assuming you might have this field
                        foodProcessingRating: foodProcessingRating,
                        //allergens: productJson["allergens"] as? [String] ?? [],
                        //ingredientsAnalysis: productJson["ingredients_analysis"] as? String ?? "N/A",
                        imageURL: productJson["image_url"] as? String ?? "N/A",
                        timeScanned: Date(),
                        calories: calories
                    )
                    
                    DispatchQueue.main.async {
                        self.showNutritionInfo = true
                        completion(newProduct)
                    }
                } else {
                    print("Product not found.")
                    DispatchQueue.main.async { completion(nil) }
                }
            } catch {
                print("Failed to parse JSON: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
        
        task.resume()
    }
    
    var recognizedDataType: DataScannerViewController.RecognizedDataType {
        .barcode() // Always return barcode scanner type
    }
    
    var headerText: String {
        if recognizedItems.isEmpty {
            return "Scanning barcodes"
        } else {
            return "Recognized \(recognizedItems.count) item(s)"
        }
    }
    
    var dataScannerViewId: Int {
        let hasher = Hasher()
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
            dataScannerAccessStatus = granted ? (isScannerAvailable ? .scannerAvailable : .scannerNotAvailable) : .cameraAccessNotGranted
            
        default: break
        }
    }
}
