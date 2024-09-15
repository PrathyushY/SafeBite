import SwiftUI

struct NutritionInfoView: View {
    let product: Product
    @State private var isLoading = true // Tracks whether AI info is loading
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Product Information header without colon and larger size
                Text("Product Information")
                    .font(.largeTitle) // Increased size
                    .bold()
                    .padding(.bottom, 10)
                
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
                        .foregroundColor(.gray)
                }
                
                // Nutrition Score in Circular View
                HStack {
                    ScoreCircleView(score: product.nutritionScore, label: "Nutrition Score")
                        .padding()
                    ScoreCircleView(score: product.ecoScore, label: "Eco Score")
                }
                
                // Time Scanned Section
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    Text("Time Scanned: \(formattedDate(product.timeScanned))")
                        .font(.body)
                        .foregroundColor(.black)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                .padding(.horizontal)
                
                // Product details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name: \(product.name)")
                    Text("Brand: \(product.brand)")
                    Text("Quantity: \(product.quantity)")
                    Text("With Additives: \(product.withAdditives)")
                    Text("Possible Allergens: \(product.allergens.joined(separator: ", "))")
                    Text("Ingredients Analysis: \(product.ingredientsAnalysis)")
                    Text("Image URL: \(product.imageURL)")
                }
                .font(.body)
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                .padding(.horizontal)
                
                // Summary Section with Table
                VStack(alignment: .leading) {
                    Text("Ingredient Summary")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    let aiGeneratedInfo = product.aiGeneratedInfo
                    
                    if isLoading {
                        ProgressView("Fetching AI-generated info...")
                            .padding()
                    } else if !aiGeneratedInfo.isEmpty {
                        ForEach(product.ingredients.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }, id: \.self) { ingredient in
                            if let index = product.ingredients.split(separator: ",").map({ String($0).trimmingCharacters(in: .whitespacesAndNewlines) }).firstIndex(of: ingredient),
                               index < aiGeneratedInfo.count {
                                // Displaying ingredient and AI-generated info in two columns
                                HStack {
                                    Text(ingredient)
                                        .font(.body)
                                        .bold()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(aiGeneratedInfo[index])
                                        .font(.body)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 5)
                                Divider()
                            }
                        }
                    } else {
                        Text("No AI-generated information available.")
                            .italic()
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .onAppear {
            Task {
                if product.aiGeneratedInfo.isEmpty {
                    isLoading = true
                    await product.fetchAIInfo() // Ensure this method is implemented in your Product model
                    isLoading = false
                } else {
                    isLoading = false
                }
            }
        }
    }
    
    // Function to format the date using DateFormatter
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // Format like: Sep 10, 2024
        formatter.timeStyle = .short  // Format like: 3:45 PM
        return formatter.string(from: date)
    }
}

struct ScoreCircleView: View {
    let score: Int
    let label: String
    
    var body: some View {
        VStack {
            ZStack {
                // Background circle (gray outline)
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 15)
                    .frame(width: 100, height: 100) // Updated size
                
                // Foreground circle representing the score (red outline)
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(Color.red, lineWidth: 15)
                    .rotationEffect(.degrees(-90)) // Start from the top
                    .frame(width: 100, height: 100) // Updated size
                
                // Display the score in the center
                Text("\(score)")
                    .font(.title)
                    .bold()
                    .foregroundColor(.red)
            }
            // Caption for the score
            Text(label)
                .font(.body)
                .bold()
                .foregroundColor(.gray)
                .padding(.top, 8) // Added padding
        }
    }
}

// Preview the view
#Preview {
    NutritionInfoView(product: Product(
        withAdditives: "No",
        name: "Name",
        brand: "Brand",
        quantity: "Quantity",
        ingredients: "Sugar, Water, Salt",
        nutritionScore: 85,
        ecoScore: 90,
        foodProcessingRating: "Low",
        allergens: ["None"],
        ingredientsAnalysis: "Contains sugar and salt, minimal processing",
        imageURL: "https://www.applesfromny.com/wp-content/uploads/2020/05/20Ounce_NYAS-Apples2.png",
        timeScanned: Date()
    ))
}
