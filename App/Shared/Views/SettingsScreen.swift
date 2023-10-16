//
//  SettingsScreen.swift
//  SwiftChat
//
//  Created by Freek Zijlmans on 16/08/2020.
//

import SwiftUI

struct SettingsScreen: View {
    
    @EnvironmentObject private var userInfo: UserInfo
    
    @Namespace var animation
    
    @State var buttonTitle: String = ""
    @State var isOpened: Bool = false
    @State var isChatOpened: Bool = false
    @State var isActive: Bool = false

    let buttonSize: CGFloat = 64
    
    private var isUsernameValid: Bool {
        !userInfo.username.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    @ViewBuilder
    func getFloatingButton() -> some View {
        CustomButtom(
            configuration:
                ConfigurationButton(
                    buttonTitle: $buttonTitle,
                    backgroundColors:
                        BackgroundColorState(
                            unselected: .blue.opacity(0.85),
                            selected: .green.opacity(0.85),
                            inactive: .gray
                        ),
                    width: buttonSize,
                    height: buttonSize,
                    cornerType: .circle,
                    borders:
                        ButtonExtras(
                            color: .white,
                            width: 6
                        ),
                    shadow:
                        ButtonExtras(
                            color: .gray.opacity(0.75),
                            width: 8
                        )
                ),
            isOpened: $isOpened,
            isActive: isUsernameValid,
            acion: {
                withAnimation(.snappy(duration: 0.35, extraBounce: 0)) {
                    isOpened.toggle()
                }
                withAnimation(.snappy(duration: 0.35).delay(0.35)) {
                    isChatOpened = isOpened
                }
                print("You tapped the button!")
            }
        )
    }
    
    @ViewBuilder
    func getForm() -> some View {
        Form {
            Section(header: Text("Username")) {
                TextField("E.g. John Applesheed", text: $userInfo.username)
                
                NavigationLink("Continue", destination: ChatScreen())
                    .disabled(!isUsernameValid)
            }
        }
    }
    
    var body: some View {
        ZStack {
            getForm()
            getFloatingButton()
            if isChatOpened {
                GeometryReader { gp in
                    VStack(alignment: .center) {
                        ChatScreen()
                            .shadow(radius: 8)
                            .matchedGeometryEffect(id: "chatShape", in: animation)
                            .frame(width: gp.size.width - 40, height: gp.size.height - buttonSize*2, alignment: .center)
                            .zIndex(10000)
                    }
                }
            }else {
                GeometryReader { gp in
                    Rectangle()
                        .fill(Color.clear)
                        .matchedGeometryEffect(id: "chatShape", in: animation)
                        .frame(width: buttonSize, height: buttonSize, alignment: .center)
                        .position(CGPoint(x: gp.size.width - buttonSize/2, y: gp.size.height - buttonSize/2))
                }
            }
        }
        .navigationTitle("Settings")
    }
}


struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen()
            .environmentObject(UserInfo())
    }
}
