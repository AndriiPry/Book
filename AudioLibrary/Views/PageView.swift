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
        UIDevice.current.userInterfaceIdiom == .pad ? 4 : -10
    }
    
    var body: some View {
        ZStack {
            if let bgImage = img {
                GeometryReader { _ in
                    bgImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                        .scaledToFill()
                }
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.02, blue: 0.01),
                        Color(red: 0.0, green: 0.02, blue: 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            VStack {
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .fill(Color.white.opacity(Constants.textBackgroundOpacity))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                        .frame(
                            width: geometry.size.width * Constants.textBlockWidthRatio * 0.9,
                            height: Constants.textBlockHeight * (UIDevice.current.userInterfaceIdiom == .pad ? 1 : 0.85)
                        )
                    
                    Text(page.text)
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .frame(
                            width: (geometry.size.width * Constants.textBlockWidthRatio - (Constants.textPadding * 2)) * 0.9,
                            height: Constants.textBlockHeight - (Constants.textPadding * 2),
                            alignment: .center
                        )
                        .offset(y: textYOFFset)
                        .clipped() // ensures no overflow without lineLimit
                }
                .offset(y: textBlockYOffset)
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .offset(x: offset)
    }
}

