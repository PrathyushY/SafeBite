import SwiftUI
import Foundation
import SwiftData

@MainActor
struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var userMessage: String = ""
    @State private var aiResponse: String = "Type a message and press 'Send' to start."
    @State private var products: [Product] = []
    @State private var isGeneratingResponse: Bool = false
    @State private var showAlert: Bool = false
    
    @Query(sort: \ChatMessage.timestamp, order: .forward) private var chatMessages: [ChatMessage]
    
    var body: some View {
        NavigationView {
            VStack {
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
                                            .contextMenu {
                                                Button(action: {
                                                    UIPasteboard.general.string = message.content
                                                }) {
                                                    Label("Copy", systemImage: "doc.on.doc")
                                                }
                                                // Regenerate response only for the last user message
                                                if isLastUserMessage(message) {
                                                    Button(action: {
                                                        Task {
                                                            await regenerateResponse(for: message)
                                                        }
                                                    }) {
                                                        Label("Regenerate Response", systemImage: "arrow.counterclockwise")
                                                    }
                                                }
                                            }
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
                                                .contextMenu {
                                                    Button(action: {
                                                        UIPasteboard.general.string = message.content
                                                    }) {
                                                        Label("Copy", systemImage: "doc.on.doc")
                                                    }
                                                }
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
                
                HStack {
                    TextField("Enter your message", text: $userMessage, onCommit: {
                        Task {
                            await sendChatRequest()
                        }
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .disabled(isGeneratingResponse)
                    
                    Button(action: {
                        Task {
                            await sendChatRequest()
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .padding(7)
                            .background(isGeneratingResponse ? Color.gray : Color.red)
                            .cornerRadius(5)
                    }
                    .padding(.trailing, 10)
                    .disabled(isGeneratingResponse)
                }
                .padding(.bottom)
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: clearMessageHistory) {
                        Text("Clear History")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAlert = true
                    }) {
                        Image(systemName: "info.circle")
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Information"),
                            message: Text("Be cautious when trusting AI-generated content. Always verify information from reliable sources."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
            }
            .task {
                await fetchProducts()
            }
            .padding()
        }
    }
    
    private func clearMessageHistory() {
        for message in chatMessages {
            modelContext.delete(message)
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context after clearing history: \(error.localizedDescription)")
        }
    }
    
    private func fetchProducts() async {
        do {
            let fetchDescriptor: FetchDescriptor<Product> = FetchDescriptor()
            products = try modelContext.fetch(fetchDescriptor)
        } catch {
            aiResponse = "Error fetching data: \(error.localizedDescription)"
        }
    }
    
    private func sendChatRequest() async {
        if userMessage.isEmpty {
            let aiChatMessage = ChatMessage(content: "Please enter a message before sending", sender: "ai")
            modelContext.insert(aiChatMessage)
            return
        }
        
        let userChatMessage = ChatMessage(content: userMessage, sender: "user")
        modelContext.insert(userChatMessage)
        
        isGeneratingResponse = true
        
        let idleMessage = ChatMessage(content: "idle message", sender: "ai")
        modelContext.insert(idleMessage)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
        
        if let aiResponseText = await chatBasedOnHistory(message: userMessage, products: products) {
            let aiChatMessage = ChatMessage(content: aiResponseText, sender: "ai")
            modelContext.insert(aiChatMessage)
        } else {
            let aiChatMessage = ChatMessage(content: "Failed to generate summary.", sender: "ai")
            modelContext.insert(aiChatMessage)
        }
        
        isGeneratingResponse = false
        userMessage = ""
        modelContext.delete(idleMessage)
    }
    
    // Function to regenerate the AI response based on a specific user message
    private func regenerateResponse(for userMessage: ChatMessage) async {
        guard userMessage.sender == "user" else { return }
        
        // Find and delete the existing AI response related to the user's message
        if let existingAIMessage = chatMessages.first(where: { $0.sender == "ai" && $0.timestamp > userMessage.timestamp }) {
            modelContext.delete(existingAIMessage)
        }
        
        isGeneratingResponse = true
        
        let idleMessage = ChatMessage(content: "idle message", sender: "ai")
        modelContext.insert(idleMessage)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
        
        // Generate the new response
        if let newAIResponse = await chatBasedOnHistory(message: userMessage.content, products: products) {
            let aiChatMessage = ChatMessage(content: newAIResponse, sender: "ai")
            modelContext.insert(aiChatMessage)
        } else {
            let aiChatMessage = ChatMessage(content: "Failed to generate a new response.", sender: "ai")
            modelContext.insert(aiChatMessage)
        }
        
        isGeneratingResponse = false
        modelContext.delete(idleMessage)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
    
    // Check if the message is the last one sent by the user
    private func isLastUserMessage(_ message: ChatMessage) -> Bool {
        // Find the last message sent by the user in the list
        guard let lastUserMessage = chatMessages.last(where: { $0.sender == "user" }) else {
            return false
        }
        return message.id == lastUserMessage.id
    }
}
