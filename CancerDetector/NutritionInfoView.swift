//
//  NutritionInfoView.swift
//  CancerDetector
//
//  Created by Prathyush Yeturi on 8/14/24.
//

import SwiftUI

struct NutritionInfoView: View {
    let withAdditives: String
    let name: String
    let brand: String
    let quantity: String
    let ingredients: String
    let nutritionScore: Int
    let imageURL: String
    
    var body: some View {
        VStack {
            Text("Product Information:")
                .font(.headline)
            
            // Display the image if available
            if let url = URL(string: imageURL) {
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
            
            Text("With Additives: \(withAdditives)")
            Text("Name: \(name)")
            Text("Brand: \(brand)")
            Text("Quantity: \(quantity)")
            Text("Ingredients: \(ingredients)")
            Text("Nutrition Score: \(nutritionScore)")
            Text("Image URL: \(imageURL)")
        }
        .padding()
    }
}

#Preview {
    NutritionInfoView(withAdditives: "No", name: "Name", brand: "Brand", quantity: "Quantity", ingredients: "Ingredients", nutritionScore: 0, imageURL: "https://www.applesfromny.com/wp-content/uploads/2020/05/20Ounce_NYAS-Apples2.png")
}
