//
//  CameraView.swift
//  CancerDetector
//
//  Created by Prathyush Yeturi on 8/13/24.
//  Made using code made by Alfian Losari on 6/25/22.
//

import SwiftUI
import VisionKit

struct CameraView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var productInfoView: NutritionInfoView? = nil

    var body: some View {
        NavigationView {
            switch vm.dataScannerAccessStatus {
            case .scannerAvailable:
                mainView
            case .cameraNotAvailable:
                Text("Your device doesn't have a camera")
            case .scannerNotAvailable:
                Text("Your device doesn't have support for scanning barcode with this app")
            case .cameraAccessNotGranted:
                Text("Please provide access to the camera in settings")
            case .notDetermined:
                Text("Requesting camera access")
            }
        }
        .task {
            await vm.requestDataScannerAccessStatus()
        }
        .navigationTitle("Camera")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: showInfo) {
                    Image(systemName: "info.circle")
                        .imageScale(.large)
                }
            }
        }
        .sheet(isPresented: $vm.showNutritionInfo) {
            if let productInfoView = productInfoView {
                productInfoView
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var mainView: some View {
        ZStack {
            DataScannerView(
                recognizedItems: $vm.recognizedItems,
                recognizedDataType: vm.recognizedDataType,
                recognizesMultipleItems: vm.recognizesMultipleItems,
                onScan: { result in
                    handleScan(result)
                }
            )
            .background { Color.gray.opacity(0.3) }
            .ignoresSafeArea()
            .id(vm.dataScannerViewId)

            VStack {
                Spacer()
                
                bottomContainerView
                    .background(.clear)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.height * 0.35) // Height of scanning information
                    .clipped()
            }
            .edgesIgnoringSafeArea(.bottom)
            .onChange(of: vm.scanType) { newValue, _ in
                vm.recognizedItems = []
            }
            .onChange(of: vm.textContentType) { newValue, _ in
                vm.recognizedItems = []
            }
            .onChange(of: vm.recognizesMultipleItems) { newValue, _ in
                vm.recognizedItems = []
            }
        }
    }

    private func handleScan(_ result: [RecognizedItem]) {
        // Ensure scanType is barcode
        if vm.scanType == .barcode {
            // Iterate over recognized items
            for item in result {
                // Check if the item is a barcode
                if case let .barcode(barcode) = item {
                    // Fetch product info with the barcode payload
                    vm.fetchProductInfo(barcode: barcode.payloadStringValue ?? "", modelContext: modelContext) { newProduct in
                        // Ensure newProduct is not nil
                        if let product = newProduct {
                            DispatchQueue.main.async {
                                self.productInfoView = NutritionInfoView(product: product)
                                vm.showNutritionInfo = true  // Ensure this state is toggled to present the sheet
                                modelContext.insert(product)
                                do {
                                    try modelContext.save()
                                } catch {
                                    print("Failed to save context: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                    break
                }
            }
        }
    }

    private func showInfo() {
        print("Info button tapped")
    }

    private var bottomContainerView: some View {
        VStack {
            Picker("Scan Type", selection: $vm.scanType) {
                Text("Barcode").tag(ScanType.barcode)
                Text("Text").tag(ScanType.text)
            }
            .pickerStyle(.segmented)
            .padding(.leading, 30)
            .padding(.trailing, 30)
            .padding(.horizontal)
        }
    }
}
