//
//  PageView.swift
//  AudioLibrary
//
//  Created by Oleksii on 09.08.2025.
//

import SwiftUI

struct PageView: View {
    let page: Page
    let geometry: GeometryProxy
    let offset: CGFloat
    let img: Image?
    @Binding var isPortrait: Bool
    
    private enum Constants {
        static let textPadding: CGFloat = 20
        static let textBackgroundOpacity: Double = 0.9
        static let cornerRadius: CGFloat = 16
        static let progressBarHeight: CGFloat = 4
        static let textBlockWidthRatio: CGFloat = 0.8
        static let textBlockHeight: CGFloat = 120
    }
    
    var fontSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 36 : 24
    }
    
    var textBlockYOffset: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 0 : 40
    }
    
    var textYOFFset: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 4 : -5
    }
    
    var body: some View {
        ZStack {
            if let bgImage = img {
                GeometryReader { geometry in
                    bgImage
                        .resizable()
                        .scaledToFill() // BEFORE frame
                        //.offset(y:50)
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height,
                        )
                        //.clipped()
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .edgesIgnoringSafeArea(.all)
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.02, blue: 0.01),
                        Color(red: 0.0, green: 0.02, blue: 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .fill(Color.white.opacity(Constants.textBackgroundOpacity))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                        .frame(
                            width: geometry.size.width * Constants.textBlockWidthRatio * 0.9
                        )
                        .frame(maxHeight: Constants.textBlockHeight * (UIDevice.current.userInterfaceIdiom == .pad ? 1 : (isPortrait ? 1 : 0.75)))
                        .padding(.vertical, Constants.textPadding)
                    
                    Text(page.text)
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .frame(
                            width: (geometry.size.width * Constants.textBlockWidthRatio - (Constants.textPadding * 2)) * 0.9,
                            alignment: .center
                        )
                        .lineLimit(4) //
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, Constants.textPadding)
                        .offset(y: textYOFFset)
                }
                .offset(y: textBlockYOffset)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

