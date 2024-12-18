//
//  ContentView.swift
//  SafeBite
//
//  Created by Prathyush Yeturi on 8/10/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var vm = AppViewModel()
    
    var body: some View {
        TabView {
            StatsView()
                .environmentObject(vm)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Stats")
                }
            
            VStack {
                CameraView()
                    .environmentObject(vm)
                    .safeAreaInset(edge: .bottom, alignment: .center, spacing: 0) {
                        Color.clear
                            .frame(height: 0)
                            .background(Material.bar)
                    }
                    .ignoresSafeArea(.all, edges: .top)
            }
            .tabItem {
                Image(systemName: "camera")
                Text("Camera")
            }
            
            HistoryView()
                .environmentObject(vm)
                .tabItem {
                    Image(systemName: "clock")
                    Text("History")
                }
            
            ChatView()
                .environmentObject(vm)
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
        }
        .modelContainer(for: [Product.self, ChatMessage.self], inMemory: false)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Product.self, ChatMessage.self], inMemory: false)
}
