//
//  ChatScreen.swift
//  SwiftChat
//
//  Created by Freek Zijlmans on 15/08/2020.
//

import Combine
import Foundation
import SwiftUI

struct ChatScreen: View {
	@AppStorage("id") private var userID = UUID().uuidString
	@AppStorage("username") private var username = ""

	@StateObject private var model = ChatScreenModel()
	@State private var message = ""
	
	// MARK: - Events
	private func onAppear() {
		model.connect(username: username, userID: userID)
	}
	
	private func onDisappear() {
		model.disconnect()
	}
	
	private func onCommit() {
		model.send(text: message)
		message = ""
	}
	
	private func scrollToLastMessage(proxy: ScrollViewProxy) {
		if let lastMessage = model.messages.last {
			withAnimation(.easeOut(duration: 0.4)) {
				proxy.scrollTo(lastMessage.id, anchor: .bottom)
			}
		}
	}

	// MARK: -
	var body: some View {
		VStack {
			// Chat history.
			ScrollView {
				ScrollViewReader{ proxy in
					LazyVStack(spacing: 8) {
						ForEach(model.messages) { message in
							ChatMessageRow(message: message, isUser: message.userID == userID)
								.id(message.id)
						}
					}
					.padding(10)
					.onChange(of: model.messages.count) { _ in
						scrollToLastMessage(proxy: proxy)
					}
				}
			}

			// Message field.
			HStack {
				TextField("Message", text: $message, onEditingChanged: { _ in }, onCommit: onCommit)
					.padding(10)
					.keyboardType(.webSearch)
					.background(Color.secondary.opacity(0.2))
					.cornerRadius(5)
				
				Button(action: onCommit) {
					Image(systemName: "arrowshape.turn.up.right")
						.font(.system(size: 20))
				}
				.padding()
				.disabled(message.isEmpty)
			}
			.padding()
		}
		.navigationTitle("Chat")
		.onAppear(perform: onAppear)
		.onDisappear(perform: onDisappear)
	}
}

// MARK: - Individual chat message balloon
private struct ChatMessageRow: View {
	static private let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .none
		formatter.timeStyle = .short
		return formatter
	}()
	
	let message: ChatMessage
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

// MARK: - Chat Screen model
/**
 * All business logic is performed in this Observable Object.
 */
private final class ChatScreenModel: ObservableObject {
	private static let decoder = JSONDecoder()
	private static let encoder = JSONEncoder()
	
	// MARK: -
	private(set) var username: String?
	private(set) var userID: String?
	
	private var webSocketTask: URLSessionWebSocketTask?

	@Published private(set) var messages: [ChatMessage] = []

	// MARK: - Connection
	func connect(username: String, userID id: String) {
		self.username = username
		self.userID = id

		let url = URL(string: "ws://127.0.0.1:8080/chat")!
		webSocketTask = URLSession.shared.webSocketTask(with: url)
		webSocketTask?.receive(completionHandler: onReceive)
		webSocketTask?.resume()
	}
	
	func disconnect() {
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
				  let chatMessage = try? Self.decoder.decode(ChatMessage.self, from: data)
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
		
		let message = ChatMessage(message: text, user: username, userID: userID)
		guard let json = try? Self.encoder.encode(message),
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
