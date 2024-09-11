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
    var withAdditives: String
    var name: String
    var brand: String
    var quantity: String
    var ingredients: String
    var nutritionScore: Int
    var ecoScore: Int // Added ecoScore
    var foodProcessingRating: String // Added foodProcessingRating
    var allergens: [String] // Added allergens
    var ingredientsAnalysis: String // Added ingredientsAnalysis
    var imageURL: String
    var summary: String
    var timeScanned: Date
    
    init(
        withAdditives: String,
        name: String,
        brand: String,
        quantity: String,
        ingredients: String,
        nutritionScore: Int,
        ecoScore: Int, // Added ecoScore
        foodProcessingRating: String, // Added foodProcessingRating
        allergens: [String], // Added allergens
        ingredientsAnalysis: String, // Added ingredientsAnalysis
        imageURL: String,
        summary: String,
        timeScanned: Date
    ) {
        self.withAdditives = withAdditives
        self.name = name
        self.brand = brand
        self.quantity = quantity
        self.ingredients = ingredients
        self.nutritionScore = nutritionScore
        self.ecoScore = ecoScore // Initialize ecoScore
        self.foodProcessingRating = foodProcessingRating // Initialize foodProcessingRating
        self.allergens = allergens // Initialize allergens
        self.ingredientsAnalysis = ingredientsAnalysis // Initialize ingredientsAnalysis
        self.imageURL = imageURL
        self.summary = summary
        self.timeScanned = timeScanned
    }
}
