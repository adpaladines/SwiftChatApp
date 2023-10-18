//
//  ChatScreenModel.swift
//  SwiftChat (iOS)
//
//  Created by andres paladines on 10/13/23.
//

import SwiftUI

enum ConnexionStatus: Equatable {
    
    static func == (lhs: ConnexionStatus, rhs: ConnexionStatus) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
    
    case notConected
    case connecting
    case connected
    case error(_: Error)
}

enum MessageSendStatus: Equatable {
    
    static func == (lhs: MessageSendStatus, rhs: MessageSendStatus) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
    
    case sending
    case sent
}

final class ChatScreenModel: ObservableObject {
    private var username: String?
    private var userID: UUID?
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    @Published private(set) var messages: [ReceivingChatMessage] = []
    @Published private(set) var connexionStatus: ConnexionStatus = .notConected
    
    // MARK: - Connection
    func connect(username: String, userID: UUID) {
        guard webSocketTask == nil else {
            connexionStatus = .error(NSError(domain: "WebSocket already initialized", code: 403))
            return
        }

        self.username = username
        self.userID = userID
//        let url = URL(string: "ws://127.0.0.1:8080/chat")!
        let url = URL(string: "ws://rcxdh8qz-8080.use.devtunnels.ms/chat")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.receive(completionHandler: onReceive)
        webSocketTask?.resume()
        withAnimation {
            connexionStatus = .connected
        }
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
            connexionStatus = .error(NSError(domain: "WebSocket: connection failed", code: 500))
            eraseConnexion()
        }
    }
    
    private func onMessage(message: URLSessionWebSocketTask.Message) {
        if case .string(let text) = message {
            guard let data = text.data(using: .utf8),
                  let chatMessage = try? JSONDecoder().decode(ReceivingChatMessage.self, from: data)
            else {
                connexionStatus = .error(NSError(domain: "Incoming Message: Malformed response.", code: 500))
                return
            }
            
            print("Received: \(chatMessage.user)")
            
            if let index = self.messages.firstIndex(where: {$0.senderMessageID == chatMessage.senderMessageID} ) {
//                self.messages.remove(at: index)
                DispatchQueue.main.async {
//                    withAnimation(.spring()) {
                        self.messages[index].id = chatMessage.id
//                        self.messages.insert(chatMessage, at: index)
//                    }
                }
                //                        self.messages.append(chatMessage)
            }else {
                DispatchQueue.main.async {
                    withAnimation(.spring()) {
                        self.messages.append(chatMessage)
                    }
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
        let senderMessageID: UUID = UUID()
        let message = SubmittedChatMessage(message: text, user: username, userID: userID, senderMessageID: senderMessageID)
        guard let json = try? JSONEncoder().encode(message),
              let jsonString = String(data: json, encoding: .utf8)
        else {
            return
        }
        
        webSocketTask?.send(.string(jsonString)) {[weak self] error in
            if let error = error {
                print("Error sending message", error)
            }else {
                
                if let message_ = self?.makeSendingStatusMessageWith(message: text, user: username, userID: userID, senderMessageID: senderMessageID) {
                    print("Sent: \(message_.user)")
                    DispatchQueue.main.async {
                        self?.messages.append(message_)
                    }
                }
            }
        }
    }
    
    func makeSendingStatusMessageWith(message: String, user: String, userID: UUID, senderMessageID: UUID) -> ReceivingChatMessage {
        ReceivingChatMessage(
            date: Date(),
            id: nil,
            message: message,
            user: user,
            userID: userID,
            senderMessageID: senderMessageID
        )
    }
    
    func eraseConnexion() {
        disconnect()
        webSocketTask = nil
    }
    
    deinit {
        eraseConnexion()
        print("deinit: ChatScreenModel")
    }
}
