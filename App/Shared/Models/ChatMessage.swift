//
//  ChatMessage.swift
//  SwiftChat
//
//  Created by Freek Zijlmans on 15/08/2020.
//

import Foundation

struct SubmittedChatMessage: Encodable {
	let message: String
	let user: String
	let userID: UUID
    let senderMessageID: UUID
}

struct ReceivingChatMessage: Decodable, Identifiable {
	let date: Date
	var id: UUID?
	let message: String
	let user: String
	let userID: UUID
    let senderMessageID: UUID
}

extension ReceivingChatMessage {
    
    var status: MessageSendStatus {
        guard id != nil else {
            return .sending
        }
        return .sent
    }
    
}
