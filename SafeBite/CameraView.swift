//
//  CameraView.swift
//  SafeBite
//
//  Created by Prathyush Yeturi on 8/10/24.
//  Made with code written by Alfian Losari on 6/25/22.
//

import SwiftUI
import VisionKit

struct CameraView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var productInfoView: NutritionInfoView? = nil
    @State private var scanningPaused = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack {
                switch vm.dataScannerAccessStatus {
                case .scannerAvailable:
                    mainView
                case .cameraNotAvailable:
                    Text("Your device doesn't have a camera")
                case .scannerNotAvailable:
                    Text("Your device doesn't have support for scanning barcodes with this app")
                case .cameraAccessNotGranted:
                    Text("Please provide access to the camera in settings")
                case .notDetermined:
                    Text("Requesting camera access")
                }
            }
            .task {
                await vm.requestDataScannerAccessStatus()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: showInfo) {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $vm.showNutritionInfo, onDismiss: {
                scanningPaused = false
            }) {
                if let productInfoView = productInfoView {
                    productInfoView
                        .presentationDragIndicator(.visible)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Info"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
            .navigationBarTitle("Camera")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var mainView: some View {
        ZStack {
            if !scanningPaused {
                DataScannerView(
                    recognizedItems: $vm.recognizedItems,
                    recognizedDataType: .barcode(),
                    recognizesMultipleItems: false,
                    onScan: { result in
                        handleScan(result)
                    }
                )
                .background { Color.gray.opacity(0.3) }
                .ignoresSafeArea()
                .id(vm.dataScannerViewId)
            } else {
                Text("Scanning Paused")
                    .foregroundColor(.gray)
                    .font(.title2)
            }
        }
    }

    private func handleScan(_ result: [RecognizedItem]) {
        guard !scanningPaused else { return }
        
        for item in result {
            if case let .barcode(barcode) = item {
                scanningPaused = true

                vm.fetchProductInfo(barcode: barcode.payloadStringValue ?? "", modelContext: modelContext) { newProduct in
                    if let product = newProduct {
                        DispatchQueue.main.async {
                            self.productInfoView = NutritionInfoView(product: product)
                            vm.showNutritionInfo = true
                            modelContext.insert(product)
                            do {
                                try modelContext.save()
                            } catch {
                                print("Failed to save context: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.alertMessage = "No product information could be found for the scanned barcode."
                            self.showAlert = true
                            scanningPaused = false
                        }
                    }
                }
                break
            }
        }
    }
    
    private func showInfo() {
        alertMessage = "To get an accurate scan, making sure the barcode is fully exposed and you are in good lighting conditions. Try not to shake the camera too much as well."
        showAlert = true
    }
}
