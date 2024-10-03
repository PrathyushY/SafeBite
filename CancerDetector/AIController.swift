//
//  PerplexityResponse.swift
//  CancerDetector
//
//  Created by Prathyush Yeturi on 8/23/24.
//

import Foundation

// Function to generate a summary using AI based on product history
func chatBasedOnHistory(message: String, products: [Product]) async -> String? {
  // Convert products to a JSON-compatible dictionary or array
  let foodHistory: [[String: Any]] = products.map { product in
    return [
      "name": product.name,
      "brand": product.brand,
      "quantity": product.quantity,
      "ingredients": product.ingredients,
      "nutritionScore": product.nutritionScore,
      "ecoScore": product.ecoScore,
      "foodProcessingRating": product.foodProcessingRating,
      "allergens": product.allergens,
      "ingredientsAnalysis": product.ingredientsAnalysis,
      "timeScanned": product.timeScanned.ISO8601Format()
    ]
  }
  do {
    // Convert food history to JSON string
    let foodHistoryJSONData = try JSONSerialization.data(withJSONObject: foodHistory, options: [])
    let foodHistoryJSONString = String(data: foodHistoryJSONData, encoding: .utf8) ?? ""
    // Prepare parameters for the API request
    let parameters: [String: Any] = [
      "model": "llama-3.1-sonar-small-128k-online",
      "messages": [
        [
          "role": "system",
          "content": """
          You are an AI assistant in a health and nutrition app. The app allows users to scan food products and track their diet. Here's the context:
          1. User's food history: \(foodHistoryJSONString)
          2. App features: product scanning, nutritional information, diet logging, calorie tracking, sugar intake monitoring.
          3. Your role: Provide diet advice, answer nutrition questions, and engage in general conversation.
          Guidelines:
          - Analyze the user's food history when relevant to their questions.
          - Offer personalized diet improvements based on their scanned products.
          - Engage in general conversation, but always be ready to link back to nutrition topics.
          - Keep responses concise but informative.
          - If asked about specific products not in the history, provide general information and suggest scanning the product for accurate details.
          """
        ],
        [
          "role": "user",
          "content": message
        ]
      ],
      "return_citations": true
    ]
    let postData = try JSONSerialization.data(withJSONObject: parameters, options: [])
    // Create the API request
    let url = URL(string: "https://api.perplexity.ai/chat/completions")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 10
    request.allHTTPHeaderFields = [
      "accept": "application/json",
      "content-type": "application/json",
      "authorization": "Bearer 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" // Use your actual API key
    ]
    request.httpBody = postData
    // Perform the API request
    let (data, response) = try await URLSession.shared.data(for: request)
    // Check for successful response status
    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
      // Parse the JSON response to extract the generated summary
      if let responseJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
        let choices = responseJson["choices"] as? [[String: Any]],
        let message = choices.first?["message"] as? [String: Any],
        let content = message["content"] as? String {
        return content
      }
    } else {
      print("Unexpected response status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
      print("Response body: \(String(data: data, encoding: .utf8) ?? "Unknown response")")
    }
  } catch {
    print("Error during the request or data fetching: \(error.localizedDescription)")
  }
  return nil
}

func getInfoAboutIngredients(ingredients: [String]) async -> [String]? {
    // Create a prompt that lists each ingredient and asks for a summary
    let ingredientsText = ingredients.joined(separator: ", ")
    let prompt = "For each of the following ingredients, generate a five-sentence summary of what the ingredient does and whether it is cancerous. Each summary should be separated by a unique delimiter and must not include any headers: \(ingredientsText). Please use '###' as a delimiter between each summary."

    let parameters = [
        "model": "llama-3.1-sonar-small-128k-online",
        "messages": [
            [
                "role": "user",
                "content": prompt
            ]
        ],
        "return_citations": false
    ] as [String : Any?]

    do {
        let postData = try JSONSerialization.data(withJSONObject: parameters, options: [])
        let url = URL(string: "https://api.perplexity.ai/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "content-type": "application/json",
            "authorization": "Bearer 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"
        ]
        request.httpBody = postData

        let (data, _) = try await URLSession.shared.data(for: request)

        // Parse the JSON response to extract the generated summary
        if let responseJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let choices = responseJson["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            
            // Split the content using the unique delimiter
            let summaries = content.split(separator: "###").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            
            // Check if the summaries list matches the number of ingredients
            if summaries.count != ingredients.count {
                print("Warning: Number of summaries doesn't match the number of ingredients.")
                return nil
            }

            // Return an array of summaries
            return summaries
        }
    } catch {
        print("Error during the request: \(error.localizedDescription)")
    }
    
    return nil
}
