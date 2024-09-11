//
//  SettingsView.swift
//  CancerDetector
//
//  Created by Prathyush Yeturi on 8/10/24.
//

import SwiftUI
import Foundation
import SwiftData

@MainActor
struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    
    // State properties to hold user input and AI response
    @State private var userMessage: String = ""
    @State private var aiResponse: String = "Type a message and press 'Send' to start."
    @State private var products: [Product] = []
    @State private var isGeneratingResponse: Bool = false // Tracks if AI is generating a response
    
    @Query(sort: \ChatMessage.timestamp, order: .forward) private var chatMessages: [ChatMessage]
    
    var body: some View {
        VStack {
            // Display chat history in a list
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(chatMessages) { message in
                            HStack {
                                if message.sender == "user" {
                                    Spacer()
                                    Text(message.content)
                                        .padding()
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                } else {
                                    if message.content == "idle message" {
                                        ProgressView()
                                            .padding()
                                            .background(Color(.secondarySystemBackground))
                                            .cornerRadius(10)
                                        Spacer()
                                    } else {
                                        Text(message.content)
                                            .padding()
                                            .background(Color(.secondarySystemBackground))
                                            .cornerRadius(10)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .safeAreaInset(edge: .top, alignment: .center, spacing: 0) {
                    Color.clear
                        .frame(height: 0)
                        .background(Material.bar)
                }
                .onChange(of: chatMessages.count) {
                    if let lastMessage = chatMessages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
                .onAppear {
                    if let lastMessage = chatMessages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            
            Spacer()
            
            // Text input and send button at the bottom of the screen
            HStack {
                TextField("Enter your message", text: $userMessage, onCommit: {
                    // Send message when user presses return
                    Task {
                        await sendChatRequest()
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .disabled(isGeneratingResponse)
                
                // Dynamic button: Show ProgressView when loading, otherwise show send button
                Button(action: {
                    Task {
                        await sendChatRequest()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .padding(7)
                        .background(isGeneratingResponse ? Color.gray : Color.red) // Gray when disabled
                        .cornerRadius(5)
                }
                .padding(.trailing, 10)
                .disabled(isGeneratingResponse) // Disable button when AI is generating
            }
            .padding(.bottom)
        }
        .task {
            // Fetch data when the view appears
            await fetchProducts()
        }
    }
    
    // Function to fetch products from the Core Data context
    private func fetchProducts() async {
        do {
            let fetchDescriptor: FetchDescriptor<Product> = FetchDescriptor()
            products = try modelContext.fetch(fetchDescriptor)
        } catch {
            aiResponse = "Error fetching data: \(error.localizedDescription)"
        }
    }
    
    // Function to handle sending the chat request to the AI
    private func sendChatRequest() async {
        if userMessage.isEmpty {
            let aiChatMessage = ChatMessage(content: "Please enter a message before sending", sender: "ai")
            modelContext.insert(aiChatMessage)
            return
        }
        
        // Create a new ChatMessage for the user's message and save it
        let userChatMessage = ChatMessage(content: userMessage, sender: "user")
        modelContext.insert(userChatMessage)
        
        // Disable further input while generating response
        isGeneratingResponse = true
        
        // Ensure that the idle message is unique for every request
        let idleMessage = ChatMessage(content: "idle message", sender: "ai")
        
        // Insert the idle chat message after the user message
        modelContext.insert(idleMessage)
        
        // Save context to update UI with the idle message
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
        
        // Fetch AI summary based on user message and fetched products
        if let aiResponseText = await chatBasedOnHistory(message: userMessage, products: products) {
            let aiChatMessage = ChatMessage(content: aiResponseText, sender: "ai")
            modelContext.insert(aiChatMessage)
        } else {
            let aiChatMessage = ChatMessage(content: "Failed to generate summary.", sender: "ai")
            modelContext.insert(aiChatMessage)
        }
        
        // Re-enable input after AI response is generated
        isGeneratingResponse = false
        
        // Clear the text field after sending the message
        userMessage = ""
        
        // Remove the idle message
        modelContext.delete(idleMessage)
    }
}
