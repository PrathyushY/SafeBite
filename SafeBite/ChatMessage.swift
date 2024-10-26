//
//  ChatMessage.swift
//  CancerDetector
//
//  Created by Prathyush Yeturi on 8/28/24.
//

import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var content: String
    var sender: String
    var timestamp: Date
    
    init(content: String, sender: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.content = content
        self.sender = sender
        self.timestamp = timestamp
    }
}
