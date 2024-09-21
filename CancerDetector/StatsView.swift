import SwiftUI
import Charts
import SwiftData

struct NutritionScorePerDay: Identifiable {
    let id = UUID()
    let date: Date
    let totalNutritionScore: Int
}

struct StatsView: View {
    // Access the SwiftData model context
    @Environment(\.modelContext) private var modelContext
    
    // Fetch all products and filter them in the computed property
    @Query(sort: \Product.timeScanned) private var products: [Product]
    
    var nutritionScores: [NutritionScorePerDay] {
        // Calculate the date for 7 days ago
        let sevenDaysAgo = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date())
        
        // Filter and aggregate nutrition scores by day
        let filteredProducts = products.filter { $0.timeScanned >= sevenDaysAgo }
        let groupedByDay = Dictionary(grouping: filteredProducts, by: { product in
            Calendar.current.startOfDay(for: product.timeScanned)
        })
        
        return groupedByDay.map { (date, products) in
            NutritionScorePerDay(
                date: date,
                totalNutritionScore: products.reduce(0) { $0 + $1.nutritionScore }
            )
        }
        .sorted { $0.date < $1.date } // Sort by date
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Heading with black text
            Text("Statistics")
                .font(.largeTitle)
                .foregroundColor(.black)
                .padding(.top)
            
            if !nutritionScores.isEmpty {
                Chart(nutritionScores) { score in
                    LineMark(
                        x: .value("Date", score.date, unit: .day),
                        y: .value("Nutrition Score", score.totalNutritionScore)
                    )
                    .foregroundStyle(Color.blue)
                    .annotation(position: .top, alignment: .center) {
                        Text("\(score.totalNutritionScore)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .frame(height: 300)
            } else {
                Text("No nutrition scores available for the past 7 days.")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding()
    }
}

#Preview {
    StatsView()
}
