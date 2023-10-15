//
//  ChatScreenModel.swift
//  SwiftChat (iOS)
//
//  Created by andres paladines on 10/13/23.
//

import SwiftUI

final class ChatScreenModel: ObservableObject {
    private var username: String?
    private var userID: UUID?
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    @Published private(set) var messages: [ReceivingChatMessage] = []

    // MARK: - Connection
    func connect(username: String, userID: UUID) {
        guard webSocketTask == nil else {
            return
        }

        self.username = username
        self.userID = userID

        let url = URL(string: "ws://127.0.0.1:8080/chat")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.receive(completionHandler: onReceive)
        webSocketTask?.resume()
        print("Connecting to chat...")
    }
    
    func disconnect() {
        print("Disconecting from chat...")
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
    }
    
    // MARK: - Sending / recieving
    private func onReceive(incoming: Result<URLSessionWebSocketTask.Message, Error>) {
        webSocketTask?.receive(completionHandler: onReceive)

        if case .success(let message) = incoming {
            onMessage(message: message)
        }
        else if case .failure(let error) = incoming {
            print("Error", error)
        }
    }
    
    private func onMessage(message: URLSessionWebSocketTask.Message) {
        if case .string(let text) = message {
            guard let data = text.data(using: .utf8),
                  let chatMessage = try? JSONDecoder().decode(ReceivingChatMessage.self, from: data)
            else {
                return
            }

            DispatchQueue.main.async {
                withAnimation(.spring()) {
                    self.messages.append(chatMessage)
                }
            }
        }
    }
    
    func send(text: String) {
        guard let username = username,
              let userID = userID
        else {
            return
        }
        
        let message = SubmittedChatMessage(message: text, user: username, userID: userID)
        guard let json = try? JSONEncoder().encode(message),
              let jsonString = String(data: json, encoding: .utf8)
        else {
            return
        }
        
        webSocketTask?.send(.string(jsonString)) { error in
            if let error = error {
                print("Error sending message", error)
            }
        }
    }
    
    deinit {
        disconnect()
    }
}
