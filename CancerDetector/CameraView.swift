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
    
    var body: some View {
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
    
    private var mainView: some View {
        ZStack {
            DataScannerView(
                recognizedItems: $vm.recognizedItems,
                recognizedDataType: vm.recognizedDataType,
                recognizesMultipleItems: vm.recognizesMultipleItems)
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
            .onChange(of: vm.scanType) { _ in vm.recognizedItems = [] }
            .onChange(of: vm.textContentType) { _ in vm.recognizedItems = [] }
            .onChange(of: vm.recognizesMultipleItems) { _ in vm.recognizedItems = []}
        }
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
