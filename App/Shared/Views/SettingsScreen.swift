//
//  SettingsScreen.swift
//  SwiftChat
//
//  Created by Freek Zijlmans on 16/08/2020.
//

import SwiftUI

struct SettingsScreen: View {
    
    @EnvironmentObject private var userInfo: UserInfo
    @State var buttonTitle: String = ""
    @State var isOpened: Bool = false
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
                isOpened.toggle()
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
//            if isOpened {
                GeometryReader { gp in
                    ChatScreen()
                        .animation(Animation.easeOut(duration: 0.35).delay(isOpened ? 0.5 : 0), value: isOpened)
                        .frame(
                            width: isOpened ? gp.size.width - 40 : 0,
                            height: isOpened ? gp.size.height - buttonSize*2 : 0,
                            alignment: .center
                        )
                        .position(isOpened 
                                  ? CGPoint(x: gp.size.width/2, y: gp.size.height/2 - buttonSize/2)
                                  : CGPoint(x: gp.size.width*1.5, y: gp.size.height/2)
                        )
                        .shadow(radius: 8)
                        

                }
                
//            }
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
