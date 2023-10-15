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
	@EnvironmentObject private var userInfo: UserInfo

	@StateObject private var model = ChatScreenModel()
	@State private var message = ""
	
	// MARK: - Events
	private func onAppear() {
		model.connect(username: userInfo.username, userID: userInfo.userID)
	}
	
	private func onDisappear() {
		model.disconnect()
	}
	
	private func onCommit() {
		if !message.isEmpty {
			model.send(text: message)
			message = ""
		}
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
                            ChatMessageRow(message: message, isUser: message.userID == userInfo.userID)
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
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(5)
                
                Button(action: onCommit) {
                    ZStack {
                        Circle()
                            .frame(width: 36, height: 36)
                                Image(systemName: "paperplane.fill")
                                    .padding(6)
                                    .foregroundColor(.white)
                    }
                }
                .cornerRadius(5)
                .disabled(message.isEmpty)
                .hoverEffect(.highlight)
            }
			.padding()
		}
		.navigationTitle("Chat")
		.onAppear(perform: onAppear)
		.onDisappear(perform: onDisappear)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.blue.opacity(0.75), lineWidth: 2)
        )
        .background(Color.white)
        .cornerRadius(12)
	}
}

struct ChatScreen_Previews: PreviewProvider {
    static var previews: some View {
        ChatScreen()
            .environmentObject(UserInfo())
    }
}

