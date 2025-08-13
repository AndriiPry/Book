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
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return 36
        default:
            return 24
        }
    }
    
    var textBlockYOffset: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return 0
        default:
            return 40
        }
    }
    
    var textYOFFset: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return 4
        default:
            return -5
        }
    }
    
    var body: some View {
        ZStack {
            ZStack {
                if let bgImage = img {
                    GeometryReader { _ in
                        bgImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            //.scaleEffect(1.1)
                            //.position(x: geo.size.width / 2, y: geo.size.height / 2)
                            .ignoresSafeArea() //
                            .scaledToFill()
                            //.frame(width: geometry.size.width, height: geometry.size.height)
                            //.clipped()
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
                    .ignoresSafeArea(.all)
                }
            }
            
            VStack {
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .fill(Color(UIColor.white).opacity(Constants.textBackgroundOpacity))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                        .frame(
                            width: geometry.size.width * Constants.textBlockWidthRatio * 0.9,
                            height: Constants.textBlockHeight * (UIDevice.current.userInterfaceIdiom == .pad ? 1 : 0.85)
                        )
                    
                    Text(page.text)
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .frame(
                            width: (geometry.size.width * Constants.textBlockWidthRatio - (Constants.textPadding * 2)) * 0.9,
                            height: Constants.textBlockHeight - (Constants.textPadding * 2) + 10
                        )
                        .offset(y: textYOFFset)
                        
                }
                .offset(y: textBlockYOffset)
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .offset(x: offset)
    }
    
//    private func getImage(at path: String) -> UIImage? {
//        return UIImage(contentsOfFile: path)
//    }
}
