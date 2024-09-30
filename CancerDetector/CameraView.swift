import SwiftUI
import VisionKit

struct CameraView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var productInfoView: NutritionInfoView? = nil
    @State private var scanningPaused = false // State to control scanning

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
                // Add an info button to the top-right of the toolbar
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: showInfo) {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $vm.showNutritionInfo, onDismiss: {
                // Resume scanning when the sheet is dismissed
                scanningPaused = false
            }) {
                if let productInfoView = productInfoView {
                    productInfoView
                        .presentationDragIndicator(.visible)
                }
            }
            .navigationBarTitle("Camera")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Main view with the scanner
    private var mainView: some View {
        ZStack {
            if !scanningPaused {
                DataScannerView(
                    recognizedItems: $vm.recognizedItems,
                    recognizedDataType: .barcode(), // Only allow barcode scanning
                    recognizesMultipleItems: false, // Disable multiple item recognition
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

            VStack {
                Spacer()
                
                bottomContainerView
                    .background(.clear)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.height * 0.35) // Height of scanning information
                    .clipped()
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }

    // Handle barcode scan results
    private func handleScan(_ result: [RecognizedItem]) {
        guard !scanningPaused else { return } // Ensure we stop scanning once a barcode is detected
        
        for item in result {
            if case let .barcode(barcode) = item {
                scanningPaused = true // Pause scanning after barcode is detected

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
                    }
                }
                break
            }
        }
    }

    // Show information button action
    private func showInfo() {
        print("Info button tapped")
    }

    // The bottom view with barcode scan status information
    private var bottomContainerView: some View {
        VStack {
            Text("Point your camera at a barcode to scan.")
                .font(.headline)
                .padding()
        }
    }
}
