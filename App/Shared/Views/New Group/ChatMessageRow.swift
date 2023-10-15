//
//  ChatMessageRow.swift
//  SwiftChat
//
//  Created by andres paladines on 10/13/23.
//

import SwiftUI

// MARK: - Individual chat message balloon
struct ChatMessageRow: View {
    
    static private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    let message: ReceivingChatMessage
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser {
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(message.user)
                        .fontWeight(.bold)
                        .font(.system(size: 12))
                    
                    Text(Self.dateFormatter.string(from: message.date))
                        .font(.system(size: 10))
                        .opacity(0.7)
                }
                
                Text(message.message)
            }
            .foregroundColor(isUser ? .white : .black)
            .padding(10)
            .background(isUser ? Color.blue : Color(white: 0.95))
            .cornerRadius(5)
            
            if !isUser {
                Spacer()
            }
        }
        .transition(.scale(scale: 0, anchor: isUser ? .topTrailing : .topLeading))
    }
}

#Preview {
    ChatMessageRow(message: ReceivingChatMessage(date: Date(), id: UUID(), message: "New messsaje", user: "Admin", userID: UUID() ), isUser: true)
}
