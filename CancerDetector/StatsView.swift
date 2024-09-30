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
    let averageEcoScore: Double
}

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Product.timeScanned) private var products: [Product]
    
    // Generate the last 7 days as a range
    var last7Days: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        return (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: today)
        }.reversed() // Sort ascending
    }
    
    // Compute total nutrition score per day
    var nutritionScores: [NutritionScorePerDay] {
        let groupedByDay = Dictionary(grouping: products.filter {
            $0.timeScanned >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        }, by: { Calendar.current.startOfDay(for: $0.timeScanned) })
        
        return last7Days.map { date in
            NutritionScorePerDay(
                date: date,
                totalNutritionScore: groupedByDay[date]?.reduce(0) { $0 + $1.nutritionScore } ?? 0
            )
        }
    }
    
    // Compute average eco score per day
    var ecoScores: [EcoScorePerDay] {
        let groupedByDay = Dictionary(grouping: products.filter {
            $0.timeScanned >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        }, by: { Calendar.current.startOfDay(for: $0.timeScanned) })
        
        return last7Days.map { date in
            let productsForDay = groupedByDay[date] ?? []
            let averageEcoScore = productsForDay.isEmpty ? 0 : Double(productsForDay.reduce(0) { $0 + $1.ecoScore }) / Double(productsForDay.count)
            
            return EcoScorePerDay(
                date: date,
                averageEcoScore: averageEcoScore
            )
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    // Nutrition Score Graph
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
                            
                            Text("Displays the average nutrition score for each day over the last 7 days.")
                                .font(.subheadline)
                                .fontWeight(.light)
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
                        .padding(.bottom, 32)
                    } else {
                        Text("No nutrition scores available for the past 7 days.")
                            .foregroundColor(.gray)
                            .padding(.bottom, 32)
                    }
                    
                    // Eco Score Graph
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
                            
                            Text("Displays the average eco score for each day over the past 7 days.")
                                .font(.subheadline)
                                .fontWeight(.light)
                                .multilineTextAlignment(.center)
                                .padding([.leading, .trailing, .bottom])
                            
                            Chart(ecoScores) { score in
                                LineMark(
                                    x: .value("Date", score.date, unit: .day),
                                    y: .value("Eco Score", score.averageEcoScore)
                                )
                                .lineStyle(StrokeStyle(lineWidth: 4))
                                .foregroundStyle(Color.green)
                                .annotation(position: .top, alignment: .center) {
                                    Text(String(format: "%.1f", score.averageEcoScore))
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
                                Text("Average Eco Score")
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
