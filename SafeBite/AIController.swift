//
//  AIController.swift
//  SafeBite
//
//  Created by Prathyush Yeturi on 8/23/24.
//

import Foundation

private let encryptedText = """
1XERmTijXL2YG4WHKo0GlgmECrwqUlSqG/9RsjVIgLNzwvfJIi8qEZPm+VGQUeN6R/X3Xfd9f0oKiBH9leX062zxfN3BmYN63ikwQImKiFzipK+0738pAUIKXBGr8CcZXgMekNqGvb4IRf45W4Ns5kpvhe/3tjwyGhETKLVdivIcZJp6Vy7+CpG5TSDI3m7uKIDOs4aDMHk2U3XGxrs2bqvpmihQI+E4YiZ816nNUmg=
"""
private let secretKey = "zoNfTQapPzWHHIDt"
private let iv = "9lYRYAXAC3EmfioF"

private let apiKey = decryptAPIKey(encryptedText: encryptedText, secretKey: secretKey, iv: iv)

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
            "timeScanned": product.timeScanned.ISO8601Format()
        ]
    }
    
    do {
        // Convert food history to JSON string
        let foodHistoryJSONData = try JSONSerialization.data(withJSONObject: foodHistory, options: [])
        let foodHistoryJSONString = String(data: foodHistoryJSONData, encoding: .utf8) ?? ""
        
        // Prepare parameters for the OpenAI API request
        let parameters: [String: Any] = [
            "model": "gpt-4",
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
            "temperature": 0.3
        ]
        
        let postData = try JSONSerialization.data(withJSONObject: parameters, options: [])
        
        // Create the API request
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = postData
        
        // Perform the API request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for successful response status
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            // Parse the JSON response to extract the generated content
            if let responseJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = responseJson["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                //print(content)
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

func getInfoAboutIngredients(ingredients: String) async -> String? {
    // Create a prompt that lists each ingredient and asks for a summary
    let prompt = """
    For each of the following ingredients, generate a five-sentence summary of what the ingredient does and whether it is cancerous. Each ingredient name should precede its summary and be separated from it by a colon (:). Use the delimiter "###" to separate each ingredient summary. Do not repeat the name of the ingredient within the summary. Do not write markdown formatting (bold, italics, etc. for any of the responses).
    
    Here is an example of the format:
    Ingredient1: This is a summary of Ingredient1. It is used in...
    ###
    Ingredient2: This is a summary of Ingredient2. It helps with...
    ###
    Ingredient3: This is a summary of Ingredient3. Studies show that...
    
    Ingredients: \(ingredients)
    """

    // Prepare parameters for OpenAI API request
    let parameters: [String: Any] = [
        "model": "gpt-4",
        "messages": [
            [
                "role": "user",
                "content": prompt
            ]
        ],
        "temperature": 0.3
    ]

    do {
        let postData = try JSONSerialization.data(withJSONObject: parameters, options: [])
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer  \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = postData

        // Perform the API request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check for successful response status
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            // Parse the JSON response to extract the generated content
            if let responseJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = responseJson["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                //print(content)

                // Return the content of the ai message
                return content
            }
        } else {
            print("Unexpected response status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("Response body: \(String(data: data, encoding: .utf8) ?? "Unknown response")")
        }
    } catch {
        print("Error during the request: \(error.localizedDescription)")
    }

    return nil
}

func getCancerScore(ingredients: [String]) async -> Int? {
    let ingredientsText = ingredients.joined(separator: ", ")
    let prompt = "Based on the following ingredients, please provide a single cancer score (1-100, with 100 being highly cancerous and 1 being not cancerous): \(ingredientsText). Make sure to output only a single integer which is the cancer score. Do not output any reasoning or anything else."

    let parameters: [String: Any?] = [
        "model": "gpt-4",
        "messages": [
            [
                "role": "user",
                "content": prompt
            ]
        ],
    ]

    do {
        let postData = try JSONSerialization.data(withJSONObject: parameters, options: [])
        let url = URL(string: "https://api.openai.com/v1/chat/completions")! // Updated endpoint
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "content-type": "application/json",
            "authorization": "Bearer \(apiKey)"
        ]
        request.httpBody = postData

        let (data, _) = try await URLSession.shared.data(for: request)

        if let responseJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let choices = responseJson["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            print("Cancer score response: " + content.trimmingCharacters(in: .whitespacesAndNewlines))
            
            if let cancerScore = Int(content.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return cancerScore
            } else {
                print("Error: The response did not contain a valid integer score.")
                return nil
            }
        }
    } catch {
        print("Error during the request: \(error.localizedDescription)")
    }
    
    return nil
}
