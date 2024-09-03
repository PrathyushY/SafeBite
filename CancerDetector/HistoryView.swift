//
//  HistoryView.swift
//  CancerDetector
//
//  Created by Prathyush Yeturi on 8/10/24.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.timeScanned, order: .reverse) private var products: [Product]

    var body: some View {
        NavigationSplitView {
            Group {
                if !products.isEmpty {
                    List {
                        ForEach(products) { product in
                            NavigationLink {
                                NutritionInfoView(product: product)
                            } label: {
                                Text(product.name)
                                if let url = URL(string: product.imageURL) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: 200, maxHeight: 200)
                                            .cornerRadius(10)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                } else {
                                    Text("Image not available")
                                        .italic()
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                } else {
                    ContentUnavailableView {
                        Label("You haven't scanned anything yet", systemImage: "barcode.viewfinder")
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
//                ToolbarItem {
//                    Button("Add Test Product") {
//                        addTestProduct()
//                    }
//                }
            }
        } detail: {
            Text("Select a product")
                .navigationTitle("Products")
        }
    }

//    private func addTestProduct() {
//        let newProduct = Product(
//            withAdditives: "None",
//            name: "Test Product",
//            brand: "Test Brand",
//            quantity: "1",
//            ingredients: "Test Ingredients",
//            nutritionScore: 100,
//            imageURL: "https://example.com"
//        )
//        modelContext.insert(newProduct)
//        try? modelContext.save()
//    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(products[index])
            }
        }
    }
}


#Preview {
    HistoryView()
}
