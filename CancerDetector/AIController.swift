//
//  PerplexityResponse.swift
//  CancerDetector
//
//  Created by Prathyush Yeturi on 8/23/24.
//

import Foundation

// Function to send the POST request and handle the response
func getAISummary(jsonString: String) async -> String? {
    let parameters = [
      "model": "llama-3.1-sonar-small-128k-online",
      "messages": [
        [
          "role": "system",
          "content": "Generate a concise summary of the overall quality and healthiness of the product based on the following product information."
        ],
        [
          "role": "user",
          "content": jsonString
        ]
      ],
      "return_citations": true
    ] as [String : Any?]

    do {
        let postData = try JSONSerialization.data(withJSONObject: parameters, options: [])
        let url = URL(string: "https://api.perplexity.ai/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
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
            return content
        }
    } catch {
        print("Error during the request: \(error.localizedDescription)")
    }
    
    return nil
}

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
                    "content": "This is information on what the user has eaten in the past: \(foodHistoryJSONString). Answer questions with this context in mind. Keep in mind that this is an app where the user can scan products and view their nutritional value. They can also keep a log of what they have eaten and see how many calories they have eaten this week and how much sugar they have eaten in the past week. You are an assistant in this app to the user, giving them tips and advice about what they are eating and helping them with any questions they have. Try to keep your answers short and concise."
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
    let prompt = "For each of the following ingredients, generate a two-sentence summary of what the ingredient does and whether it is cancerous: \(ingredientsText)."

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
            
            // Split the content into separate responses for each ingredient
            let summaries = content.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            
            // Return an array of summaries
            return summaries
        }
    } catch {
        print("Error during the request: \(error.localizedDescription)")
    }
    
    return nil
}
