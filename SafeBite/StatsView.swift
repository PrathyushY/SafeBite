import SwiftUI
import Charts
import SwiftData

struct NutritionScorePerDay: Identifiable {
    let id = UUID()
    let date: Date
    let totalNutritionScore: Int
}

struct EcoScorePerDay: Identifiable {
    let id = UUID()
    let date: Date
    let totalEcoScore: Double
}

struct CancerScorePerDay: Identifiable {
    let id = UUID()
    let date: Date
    let totalCancerScore: Double
}

struct CaloriesPerDay: Identifiable {
    let id = UUID()
    let date: Date
    let totalCalories: Double
}

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Product.timeScanned) private var products: [Product]
    
    var last7Days: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        return (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: today)
        }.reversed()
    }
    
    var nutritionScores: [NutritionScorePerDay] {
        let groupedByDay = Dictionary(grouping: products.filter {
            $0.timeScanned >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        }, by: { Calendar.current.startOfDay(for: $0.timeScanned) })

        return last7Days.map { date in
            NutritionScorePerDay(
                date: date,
                totalNutritionScore: groupedByDay[date]?.reduce(0) { (result: Int, product: Product) in
                    // Only add scores that are not -1
                    result + (product.nutritionScore != -1 ? product.nutritionScore : 0)
                } ?? 0
            )
        }
    }

    var ecoScores: [EcoScorePerDay] {
        let groupedByDay = Dictionary(grouping: products.filter {
            $0.timeScanned >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        }, by: { Calendar.current.startOfDay(for: $0.timeScanned) })

        return last7Days.map { date in
            EcoScorePerDay(
                date: date,
                totalEcoScore: groupedByDay[date]?.reduce(0.0) { (result: Double, product: Product) in
                    // Only add scores that are not -1
                    result + (product.ecoScore != -1 ? Double(product.ecoScore) : 0.0)
                } ?? 0.0
            )
        }
    }

    var cancerScores: [CancerScorePerDay] {
        let groupedByDay = Dictionary(grouping: products.filter {
            $0.timeScanned >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        }, by: { Calendar.current.startOfDay(for: $0.timeScanned) })

        return last7Days.map { date in
            CancerScorePerDay(
                date: date,
                totalCancerScore: groupedByDay[date]?.reduce(0.0) { (result: Double, product: Product) in
                    // Only add scores that are not -1
                    result + (product.cancerScore != -1 ? Double(product.cancerScore) : 0.0)
                } ?? 0.0
            )
        }
    }
    
    var calories: [CaloriesPerDay] {
        let groupedByDay = Dictionary(grouping: products.filter {
            $0.timeScanned >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        }, by: { Calendar.current.startOfDay(for: $0.timeScanned) })
        
        return last7Days.map { date in
            CaloriesPerDay(
                date: date,
                totalCalories: groupedByDay[date]?.reduce(0.0) { (result: Double, product: Product) in
                    // Only add scores that are not -1
                    result + (product.calories != -1 ? Double(product.calories) : 0.0)
                } ?? 0.0
            )
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    // Cancer score graph
                    if !cancerScores.isEmpty {
                        GroupBox {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                                Text("Cancer Score Over Last 7 Days")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.red)
                            }
                            .padding(.bottom, 4)
                            
                            Text("Displays the total cancer score for each day over the last 7 days. (For this one, the lower the better!)")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding([.leading, .trailing, .bottom])
                            
                            Chart(cancerScores) { score in
                                LineMark(
                                    x: .value("Date", score.date, unit: .day),
                                    y: .value("Cancer Score", score.totalCancerScore)
                                )
                                .lineStyle(StrokeStyle(lineWidth: 4))
                                .foregroundStyle(Color.red)
                                .annotation(position: .top, alignment: .center) {
                                    Text("\(score.totalCancerScore)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisGridLine()
                                    AxisValueLabel()
                                }
                            }
                            .chartXAxisLabel(position: .bottom, alignment: .center) {
                                Text("Date")
                            }
                            .chartYAxisLabel(position: .leading, alignment: .center) {
                                Text("Total Cancer Score")
                            }
                            .frame(width: 300, height: 175)
                        }
                        .padding(.bottom, 8)
                    } else {
                        Text("No cancer scores available for the past 7 days.")
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)
                    }
                    
                    // Calories graph
                    if !calories.isEmpty {
                        GroupBox {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 20))
                                Text("Total Calories Over Last 7 Days")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            .padding(.bottom, 4)
                            
                            Text("Displays the total calories eaten for each day over the past 7 days.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding([.leading, .trailing, .bottom])
                            
                            Chart(calories) { calorie in
                                LineMark(
                                    x: .value("Date", calorie.date, unit: .day),
                                    y: .value("Calories", calorie.totalCalories)
                                )
                                .lineStyle(StrokeStyle(lineWidth: 4))
                                .foregroundStyle(Color.orange)
                                .annotation(position: .top, alignment: .center) {
                                    Text(String(format: "%.1f", calorie.totalCalories))
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisGridLine()
                                    AxisValueLabel()
                                }
                            }
                            .chartXAxisLabel(position: .bottom, alignment: .center) {
                                Text("Date")
                            }
                            .chartYAxisLabel(position: .leading, alignment: .center) {
                                Text("Total Calories")
                            }
                            .frame(width: 300, height: 175)
                        }
                        .padding(.bottom, 8)
                    } else {
                        Text("No calorie data available for the past 7 days.")
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)
                    }
                    
                    if !nutritionScores.isEmpty {
                        GroupBox {
                            HStack {
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                                Text("Nutrition Score Over Last 7 Days")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.red)
                            }
                            .padding(.bottom, 4)
                            
                            Text("Displays the total nutrition score for each day over the last 7 days.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding([.leading, .trailing, .bottom])
                            
                            Chart(nutritionScores) { score in
                                LineMark(
                                    x: .value("Date", score.date, unit: .day),
                                    y: .value("Nutrition Score", score.totalNutritionScore)
                                )
                                .lineStyle(StrokeStyle(lineWidth: 4))
                                .foregroundStyle(Color.red)
                                .annotation(position: .top, alignment: .center) {
                                    Text("\(score.totalNutritionScore)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisGridLine()
                                    AxisValueLabel()
                                }
                            }
                            .chartXAxisLabel(position: .bottom, alignment: .center) {
                                Text("Date")
                            }
                            .chartYAxisLabel(position: .leading, alignment: .center) {
                                Text("Total Nutrition Score")
                            }
                            .frame(width: 300, height: 175)
                        }
                        .padding(.bottom, 8)
                    } else {
                        Text("No nutrition scores available for the past 7 days.")
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)
                    }
                    
                    if !ecoScores.isEmpty {
                        GroupBox {
                            HStack {
                                Image(systemName: "arrow.3.trianglepath")
                                    .foregroundColor(.green)
                                    .font(.system(size: 20))
                                Text("Eco Score Over Last 7 Days")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            .padding(.bottom, 4)
                            
                            Text("Displays the total eco score for each day over the past 7 days.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding([.leading, .trailing, .bottom])
                            
                            Chart(ecoScores) { score in
                                LineMark(
                                    x: .value("Date", score.date, unit: .day),
                                    y: .value("Eco Score", score.totalEcoScore)
                                )
                                .lineStyle(StrokeStyle(lineWidth: 4))
                                .foregroundStyle(Color.green)
                                .annotation(position: .top, alignment: .center) {
                                    Text(String(format: "%.1f", score.totalEcoScore))
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisGridLine()
                                    AxisValueLabel()
                                }
                            }
                            .chartXAxisLabel(position: .bottom, alignment: .center) {
                                Text("Date")
                            }
                            .chartYAxisLabel(position: .leading, alignment: .center) {
                                Text("Total Eco Score")
                            }
                            .frame(width: 300, height: 175)
                        }
                        .padding(.bottom, 8)
                    } else {
                        Text("No eco scores available for the past 7 days.")
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics")
        }
    }
}

#Preview {
    StatsView()
}
