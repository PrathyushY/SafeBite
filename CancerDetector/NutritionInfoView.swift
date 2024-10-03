import SwiftUI

struct NutritionInfoView: View {
    let product: Product
    @State private var isLoading = true // Tracks whether AI info is loading
    @State private var showAlert = false // State to control alert presentation
    @State private var alertMessage = "" // Message for the alert
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center) { // Center all content
                    productHeader // Product Information Header
                    
                    productImage // Display the image if available
                    
                    nutritionScores // Nutrition Score in Circular View
                    
                    timeScanned // Time Scanned Section
                        .padding(3)
                    
                    productDetails // Product details
                        .padding()
                    
                    ingredientSummary // Summary Section with Table
                }
                .padding()
                .frame(maxWidth: .infinity) // Make sure content is centered
            }
            .navigationTitle("Product Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Add an info button to the top-right of the toolbar
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: showInfo) {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
        .onAppear {
            loadAIInfo()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Warning"),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")))
        }
        .edgesIgnoringSafeArea(.top)
    }
    
    // Show information button action
    private func showInfo() {
        // Set the alert message and show the alert
        alertMessage = "Be cautious when trusting AI-generated content. Always verify information from reliable sources."
        showAlert = true
    }
    
    // Product Information header
    private var productHeader: some View {
        Text(product.name)
            .font(.title)
            .bold()
            .multilineTextAlignment(.center) // Center text
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .center) // Center the header
    }
    
    // Display the image if available
    private var productImage: some View {
        if let url = URL(string: product.imageURL) {
            return AnyView(
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, alignment: .center) // Center the image
                } placeholder: {
                    ProgressView()
                }
            )
        } else {
            return AnyView(
                Text("Image not available")
                    .italic()
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center) // Center the placeholder
            )
        }
    }
    
    // Nutrition Score in Circular View
    private var nutritionScores: some View {
        HStack {
            Spacer() // Add Spacer for centering
            ScoreCircleView(score: product.nutritionScore, label: "Nutrition Score")
                .padding()
            ScoreCircleView(score: product.ecoScore, label: "Eco Score")
            Spacer() // Add Spacer for centering
        }
        .frame(maxWidth: .infinity)
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
            Text("With Additives: \(product.withAdditives)")
            Text("Possible Allergens: \(product.allergens.joined(separator: ", "))")
            Text("Ingredients Analysis: \(product.ingredientsAnalysis)")
            Text("Image URL: \(product.imageURL)")
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
            if isLoading {
                ProgressView("Fetching AI-generated info...")
                    .padding()
            } else if !product.aiGeneratedInfo.isEmpty {
                let ingredients = product.ingredients.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                let summaries = product.aiGeneratedInfo
                
                ForEach(ingredients.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text(ingredients[index])
                            .font(.body)
                            .bold()
                            .foregroundColor(.red)
                            .padding(.bottom, 2)
                        
                        Text(summaries[index])
                            .font(.body)
                            .foregroundColor(.black)
                            .padding(.bottom, 10)
                    }
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
