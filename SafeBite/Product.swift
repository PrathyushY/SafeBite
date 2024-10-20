//
//  Product.swift
//  CancerDetector
//
//  Created by Prathyush Yeturi on 8/15/24.
//

import Foundation
import SwiftData

@Model
final class Product {
    var name: String
    var brand: String
    var quantity: String
    var ingredients: String
    var nutritionScore: Int
    var ecoScore: Int
    var foodProcessingRating: String
    var timeScanned: Date
    var aiGeneratedInfo: String = ""
    var imageURL: String
    var calories: Int = 0
    var cancerScore: Int = -1
    
    init(
        name: String,
        brand: String,
        quantity: String,
        ingredients: String,
        nutritionScore: Int,
        ecoScore: Int,
        foodProcessingRating: String,
        imageURL: String,
        timeScanned: Date,
        calories: Int
    ) {
        self.name = name
        self.brand = brand
        self.quantity = quantity
        self.ingredients = ingredients
        self.nutritionScore = nutritionScore
        self.ecoScore = ecoScore
        self.foodProcessingRating = foodProcessingRating
        self.imageURL = imageURL
        self.timeScanned = timeScanned
        self.calories = calories
    }
    
    // Fetch AI-generated information for ingredients
    func fetchAIInfo() async {
        if let generatedInfo = await getInfoAboutIngredients(ingredients: ingredients) {
            aiGeneratedInfo = generatedInfo
        } else {
            aiGeneratedInfo = "N/A" // No info returned
        }
    }
    
    func fetchCancerScore() async {
        let ingredientList = self.ingredients.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        if let generatedInfo = await getCancerScore(ingredients: ingredientList) {
            cancerScore = generatedInfo
        } else {
            cancerScore = 0 // No info returned
        }
    }
}
