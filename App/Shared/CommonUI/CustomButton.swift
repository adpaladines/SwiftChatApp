//
//  CustomButtom.swift
//  PayPalExampleCode
//
//  Created by andres paladines on 10/10/23.
//

import SwiftUI

extension CGPoint: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
    
    
    func distance(to point: CGPoint) -> CGFloat {
        let dx = self.x - point.x
        let dy = self.y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}

struct ButtonExtras {
    let color: Color
    let width: CGFloat
}

struct BackgroundColorState {
    let unselected: Color
    let selected: Color
    let inactive: Color
}

enum CustomButtonCorners: CGFloat {
    case flat = 0.0
    case rounded = 12.0
    case circle = 300.0
}

struct ConfigurationButton {
    @Binding var buttonTitle: String
    var backgroundColors: BackgroundColorState
    let width: CGFloat
    let height: CGFloat
    let cornerType: CustomButtonCorners
    let borders: ButtonExtras
    var shadow: ButtonExtras?
}

struct CustomButtom: View { //<Content>: View where Content: View {
    
    let configuration: ConfigurationButton
    @Binding var isOpened: Bool
    var isActive: Bool
    let acion: (() -> Void)
//    var content: () -> Content?
    
    @State var buttonPos: CGPoint?
    @State var buttonLastPos: CGPoint?
    @State var nearestCorner: CGPoint?
    
    private func fixButtonPosition(geometry: GeometryProxy, width: CGFloat, height: CGFloat) {
        let midWidth = width/2
        let midHeiht = height/2
        let topLeft = CGPoint(x: midWidth, y: midHeiht)
        let topRight = CGPoint(x: geometry.size.width - midWidth, y: midHeiht)
        let bottomLeft = CGPoint(x: midWidth, y: geometry.size.height - midHeiht)
        let bottomRight = CGPoint(x: geometry.size.width - midWidth, y: geometry.size.height - midHeiht)
        let midLeft = CGPoint(x: midWidth, y: geometry.size.height/2 - midHeiht)
        let midRight = CGPoint(x: geometry.size.width - midWidth, y: geometry.size.height/2 - midHeiht)

        
        guard let buttonPosition = buttonPos else { return }
        let distancesToCorners: [CGPoint: CGFloat] = [
            topLeft: buttonPosition.distance(to: topLeft),
            topRight: buttonPosition.distance(to: topRight),
            midLeft: buttonPosition.distance(to: midLeft),
            midRight: buttonPosition.distance(to: midRight),
            bottomLeft: buttonPosition.distance(to: bottomLeft),
            bottomRight: buttonPosition.distance(to: bottomRight)
        ]
        
        if let nearestposition =  distancesToCorners.min(by: { $0.value < $1.value }) {
            buttonPos = nearestposition.key
            buttonLastPos = buttonPos
        }
    }
    
    private var currentbackgroundColor: Color {
        if isActive {
            if isOpened {
                return configuration.backgroundColors.selected
            }else {
                return configuration.backgroundColors.unselected
            }
        }else {
            return configuration.backgroundColors.inactive
        }
    }
    
    var body: some View {
        GeometryReader { gp in
            Button {
                if isActive {
                    acion()
                }
            } label: {
//                content()
//                Text(configuration.buttonTitle)
                Image(systemName: isOpened ? "bubble.left.and.bubble.right.fill" : "bubble.right.fill")
                    .font(.title)
                    .foregroundColor(Color.white)
            }
            .frame(width: configuration.width, height: configuration.height)
            .background(currentbackgroundColor)
            .cornerRadius(configuration.cornerType.rawValue)
            .overlay(
                RoundedRectangle(cornerRadius: configuration.cornerType.rawValue)
                    .stroke(configuration.borders.color, lineWidth: configuration.borders.width)
            )
            .shadow(color: configuration.shadow?.color ?? .clear, radius: configuration.shadow?.width ?? 0)
            .position(buttonPos ?? CGPoint(x: gp.size.width / 2, y: gp.size.height / 2))
            .animation(.default, value: buttonPos)
            .highPriorityGesture(
                DragGesture()
                    .onChanged { value in
                        if !isOpened {
                            buttonPos = value.location
                        }
                    }
                    .onEnded { _ in
                        if !isOpened {
                            fixButtonPosition(
                                geometry: gp,
                                width: configuration.width,
                                height: configuration.height
                            )
                        }
                    }
            )
            .onChange(of: isOpened) { newValue in
                if newValue {
                    let width = configuration.width/1.5 + configuration.borders.width
                    let height = configuration.height/1.5 + configuration.borders.width
                    buttonPos = CGPoint(
                        x: gp.size.width - width,
                        y: gp.size.height - height
                    )
                }else {
                    buttonPos = buttonLastPos
                }
            }
        }
    }
}

#Preview {
    CustomButtom(
        configuration:
            ConfigurationButton(
                buttonTitle: .constant(""),
                backgroundColors:
                    BackgroundColorState(
                        unselected: .blue.opacity(0.85),
                        selected: .green.opacity(0.85), 
                        inactive: .gray
                    ),
                width: 64,
                height: 64,
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
        isOpened: .constant(false),
        isActive: true,
        acion: {
            print("You tapped the button!")
        }
//        , content: {
//            Text("")
//        }
    )
}
