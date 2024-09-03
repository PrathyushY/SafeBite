//
//  NutritionInfoView.swift
//  CancerDetector
//
//  Created by Prathyush Yeturi on 8/14/24.
//

import SwiftUI

struct NutritionInfoView: View {
    let product: Product
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Product Information:")
                    .font(.headline)
                
                // Display the image if available
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
                
                Text("Time Scanned: \(product.timeScanned)")
                Text("With Additives: \(product.withAdditives)")
                Text("Name: \(product.name)")
                Text("Brand: \(product.brand)")
                Text("Quantity: \(product.quantity)")
                Text("Ingredients: \(product.ingredients)")
                Text("Nutrition Score: \(product.nutritionScore)")
                Text("Image URL: \(product.imageURL)")
                Text("Summary: \(product.summary)")
            }
            .padding()
        }
    }
}

#Preview {
    NutritionInfoView(product: Product(withAdditives: "No", name: "Name", brand: "Brand", quantity: "Quantity", ingredients: "Ingredients", nutritionScore: 0, imageURL: "https://www.applesfromny.com/wp-content/uploads/2020/05/20Ounce_NYAS-Apples2.png", summary: "Sample summary", timeScanned: Date()))
}

