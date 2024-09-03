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
    var imageURL: String
    var summary: String
    var timeScanned: Date
    
    init(withAdditives: String, name: String, brand: String, quantity: String, ingredients: String, nutritionScore: Int, imageURL: String, summary: String, timeScanned: Date) {
        self.withAdditives = withAdditives
        self.name = name
        self.brand = brand
        self.quantity = quantity
        self.ingredients = ingredients
        self.nutritionScore = nutritionScore
        self.imageURL = imageURL
        self.summary = summary
        self.timeScanned = timeScanned
    }
}

