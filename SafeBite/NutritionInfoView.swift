import SwiftUI

struct NutritionInfoView: View {
    let product: Product
    @State private var isLoading = true // Tracks whether AI info is loading
    @State private var showInfoSheet = false // State to control modal visibility
    
    var body: some View {
        ZStack { // Use ZStack to layer the content and modal
            NavigationView {
                ScrollView {
                    VStack(alignment: .center) {
                        productHeader
                        productImage
                        nutritionScores
                            .padding(.top)
                        timeScanned
                            .padding(3)
                        productDetails
                            .padding()
                        ingredientSummary
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, -75)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Product Info")
                            .font(.headline)
                            .offset(y: -0)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: showInfo) {
                            Image(systemName: "info.circle")
                        }
                    }
                }
                .sheet(isPresented: $showInfoSheet) {
                    InfoSheetView() // Present the new sheet view
                }
            }
            .onAppear {
                loadAIInfo()
                getCancerScore()
            }
            .edgesIgnoringSafeArea(.top)
        }
    }
    
    // Info Sheet View
    private struct InfoSheetView: View {
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Information")
                            .font(.title)
                            .fontWeight(.semibold)
                            .padding(.top, 20)
                        
                        Text("Be cautious when trusting AI-generated content. Always verify information from reliable sources. Zero scores usually indicate that no data is available for this product.")
                            .font(.body)
                            .padding(.bottom, 10)
                        
                        Text("""
                        The Nutrition Score is a logo on the overall nutritional quality of products.The score from 0 to 100 is calculated based on nutrients and foods to favor (proteins, fiber, fruits, vegetables, and legumes) and nutrients to limit (calories, saturated fat, sugars, salt). The score is calculated from the data of the nutrition facts table and the composition data (fruits, vegetables, and legumes).
                        """)
                        .font(.body)
                        .padding(.bottom, 10)
                        
                        Text("""
                        The Cancer Score is a measure on a scale from 1-100 of how potentially cancerous a product may be, with 1 being the least likely to cause cancer and 100 being the most. It is an AI-generated value based on the ingredients in the product. Be cautious when trusting AI-generated information.
                        """)
                        .font(.body)
                        .padding(.bottom, 10)
                        
                        Text("""
                        The Eco Score is an experimental score that summarizes the environmental impacts of food products. The Eco-Score was initially developed for France and is being extended to other European countries. The Eco-Score formula is subject to change as it is regularly improved to make it more precise and better suited to each country.
                        """)
                        .font(.body)
                        .padding(.bottom, 10)
                    }
                    .padding()
                }
            }
            .navigationBarTitle("Info")
            .presentationDragIndicator(.visible)
        }
    }
    
    // Show information button action
    private func showInfo() {
        showInfoSheet = true
    }
    
    // Product Information header
    private var productHeader: some View {
        Text(product.name)
            .font(.title)
            .bold()
            .multilineTextAlignment(.center) // Center text
            .padding(.top, 100)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .center) // Center the header
    }
    
    // Display the image if available
    // Display the image if available
    private var productImage: some View {
        HStack { // Use HStack to align the image and info button horizontally
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
        }
        .frame(maxWidth: .infinity, alignment: .center) // Center the image and info button
    }
    
    // Nutrition Score in Circular View
    private var nutritionScores: some View {
        VStack {
            HStack {
                Spacer() // Add Spacer for centering
                ScoreCircleView(score: product.nutritionScore, label: "Nutrition Score")
                Spacer() // Add Spacer for centering
                ScoreCircleView(score: product.cancerScore, label: "Cancer Score")
                Spacer() // Add Spacer for centering
                Spacer()
                ScoreCircleView(score: product.ecoScore, label: "Eco Score")
                Spacer() // Add Spacer for centering
            }
            .frame(maxWidth: .infinity)
            
            // Adding an additional alignment section to ensure everything is centered vertically
            .padding(.bottom, 20) // Add some bottom padding for spacing
        }
        .frame(maxWidth: .infinity) // Ensure the VStack takes full width
    }
    
    // Time Scanned Section
    private var timeScanned: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.gray)
            Text("Time Scanned: \(formattedDate(product.timeScanned))")
                .font(.body)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .center) // Center time scanned section
    }
    
    // Product details
    private var productDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name: \(product.name)")
            Text("Brand: \(product.brand)")
            Text("Quantity: \(product.quantity)")
            Text("Calories: \(product.calories) kcal")
            Text("Food Processing Rating: \(product.foodProcessingRating)")
        }
        .font(.body)
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .center) // Center product details
    }
    
    // Summary Section with Table
    private var ingredientSummary: some View {
        VStack(alignment: .leading) {
            Text("Ingredients Overview")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.bottom)
            
            Divider()
            
            if isLoading {
                ProgressView("Fetching AI-generated info...")
                    .padding()
            } else if !product.aiGeneratedInfo.isEmpty {
                let ingredients = product.ingredients.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                let summaries = product.aiGeneratedInfo
                
                ForEach(0..<ingredients.count, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text(ingredients[index])
                            .font(.body)
                            .bold()
                            .foregroundColor(.red)
                            .padding(.bottom, 2)
                        
                        // Safely access the summary if it exists
                        if index < summaries.count {
                            Text(summaries[index])
                                .font(.body)
                                .padding(.bottom, 10)
                        } else {
                            // Display a message if no summary is available
                            Text("No AI-generated information available.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .padding(.bottom, 10)
                        }
                    }
                    //.padding()
                    //.background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                    Divider()
                }
            } else {
                Text("No AI-generated information available.")
                    .italic()
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
    }
    
    // Function to load AI info
    private func loadAIInfo() {
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
    
    private func getCancerScore() {
        Task {
            if product.cancerScore == -1 {
                await product.fetchCancerScore()
            }
        }
    }
    
    // Function to format the date using DateFormatter
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // Format like: Sep 10, 2024
        formatter.timeStyle = .short  // Format like: 3:45 PM
        return formatter.string(from: date)
    }
}

struct ScoreCircleView: View {
    let score: Int
    let label: String
    let radius: CGFloat = 85
    
    var body: some View {
        VStack {
            ZStack {
                // Background circle (gray outline)
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 15)
                    .frame(width: radius, height: radius) // Updated size
                
                // Foreground circle representing the score (red outline)
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(Color.red, lineWidth: 15)
                    .rotationEffect(.degrees(-90)) // Start from the top
                    .frame(width: radius, height: radius) // Updated size
                
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
                .padding(.top, 5) // Added padding
        }
    }
}

// Preview the view
#Preview {
    NutritionInfoView(product: Product(
        name: "Name",
        brand: "Brand",
        quantity: "Quantity",
        ingredients: "Sugar, Water, Salt",
        nutritionScore: 85,
        ecoScore: 90,
        foodProcessingRating: "Low",
        imageURL: "https://www.applesfromny.com/wp-content/uploads/2020/05/20Ounce_NYAS-Apples2.png",
        timeScanned: Date(),
        calories: 150
    ))
}
