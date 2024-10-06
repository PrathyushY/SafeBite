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
//                        populateProducts()
//                    }
//                }
                ToolbarItem {
                    Button("Clear History") {
                        clearHistory()
                    }
                }
            }
        } detail: {
            Text("Select a product")
                .navigationTitle("Products")
        }
    }
    
    func clearHistory() {
        do {
            try modelContext.delete(model: Product.self)
        } catch {
            print("Unable to clear history: \(error.localizedDescription)")
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
    
    func populateProducts() {
        let sampleProducts = [
            Product(
                withAdditives: "Yes",
                name: "Apple",
                brand: "Fresh Farms",
                quantity: "1 kg",
                ingredients: "Apples",
                nutritionScore: 5,
                ecoScore: 4,
                foodProcessingRating: "Minimal Processing",
                allergens: [],
                ingredientsAnalysis: "Whole fruit, rich in vitamins.",
                imageURL: "https://example.com/apple.jpg",
                timeScanned: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                calories: 150
            ),
            Product(
                withAdditives: "No",
                name: "Banana",
                brand: "Tropical Fruits",
                quantity: "1 bunch",
                ingredients: "Bananas",
                nutritionScore: 50,
                ecoScore: 5,
                foodProcessingRating: "Minimal Processing",
                allergens: [],
                ingredientsAnalysis: "Natural, high in potassium.",
                imageURL: "https://example.com/banana.jpg",
                timeScanned: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                calories: 150
            ),
            Product(
                withAdditives: "No",
                name: "Banana",
                brand: "Tropical Fruits",
                quantity: "1 bunch",
                ingredients: "Bananas",
                nutritionScore: 67,
                ecoScore: 5,
                foodProcessingRating: "Minimal Processing",
                allergens: [],
                ingredientsAnalysis: "Natural, high in potassium.",
                imageURL: "https://example.com/banana.jpg",
                timeScanned: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                calories: 150
            ),
            Product(
                withAdditives: "No",
                name: "Banana",
                brand: "Tropical Fruits",
                quantity: "1 bunch",
                ingredients: "Bananas",
                nutritionScore: 4,
                ecoScore: 5,
                foodProcessingRating: "Minimal Processing",
                allergens: [],
                ingredientsAnalysis: "Natural, high in potassium.",
                imageURL: "https://example.com/banana.jpg",
                timeScanned: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
                calories: 150
            ),
            Product(
                withAdditives: "No",
                name: "Banana",
                brand: "Tropical Fruits",
                quantity: "1 bunch",
                ingredients: "Bananas",
                nutritionScore: 1,
                ecoScore: 5,
                foodProcessingRating: "Minimal Processing",
                allergens: [],
                ingredientsAnalysis: "Natural, high in potassium.",
                imageURL: "https://example.com/banana.jpg",
                timeScanned: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                calories: 150
            ),
            Product(
                withAdditives: "No",
                name: "Banana",
                brand: "Tropical Fruits",
                quantity: "1 bunch",
                ingredients: "Bananas",
                nutritionScore: 4,
                ecoScore: 5,
                foodProcessingRating: "Minimal Processing",
                allergens: [],
                ingredientsAnalysis: "Natural, high in potassium.",
                imageURL: "https://example.com/banana.jpg",
                timeScanned: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
                calories: 150
            ),
            Product(
                withAdditives: "No",
                name: "Banana",
                brand: "Tropical Fruits",
                quantity: "1 bunch",
                ingredients: "Bananas",
                nutritionScore: 6,
                ecoScore: 5,
                foodProcessingRating: "Minimal Processing",
                allergens: [],
                ingredientsAnalysis: "Natural, high in potassium.",
                imageURL: "https://example.com/banana.jpg",
                timeScanned: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
                calories: 150
            )
        ]
        
        for product in sampleProducts {
            modelContext.insert(product)
        }
        
        // Save context if necessary
        do {
            try modelContext.save()
        } catch {
            print("Failed to save products: \(error)")
        }
    }
    
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
