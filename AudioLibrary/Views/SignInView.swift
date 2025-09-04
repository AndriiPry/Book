//
//  SignInView.swift
//  AudioLibrary
//
//  Created by Oleksii on 04.09.2025.
//

import SwiftUI

struct SignInView: View {
    @Binding var isSignedIn: Bool
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        isSignedIn = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Text("Start reading classic stories in your language for free in 4 languages")
                                .font(.system(size: 24, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            
                            VStack(spacing: 12) {
                                Button(action: {
                                    handleAppleSignIn()
                                }) {
                                    HStack {
                                        Image(systemName: "apple.logo")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.black)
                                        Text("Continue with Apple")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                }
                                
                                Button(action: {
                                    handleGoogleSignIn()
                                }) {
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 20, height: 20)
                                            Text("G")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.blue)
                                        }
                                        Text("Continue with Google")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                }
                                
                                // Continue with Facebook
                                Button(action: {
                                    // Handle Facebook sign in
                                    handleFacebookSignIn()
                                }) {
                                    HStack {
                                        Text("f")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 20, height: 20)
                                            .background(Circle().fill(Color.blue))
                                        Text("Continue with Facebook")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                                Text("or")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 10)
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 8)
                            
                            // Email input and continue button
                            VStack(spacing: 12) {
                                TextField("Enter Email", text: $email)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Button(action: {
                                    handleEmailSignIn()
                                }) {
                                    Text("Continue")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 25)
                                                .fill(email.isEmpty ? Color.gray.opacity(0.5) : Color.blue.opacity(0.8))
                                        )
                                }
                                .disabled(email.isEmpty)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Sign In Methods
    private func handleAppleSignIn() {
        print("Apple Sign In tapped")
        isSignedIn = true
    }
    
    private func handleGoogleSignIn() {
        print("Google Sign In tapped")
        isSignedIn = true
    }
    
    private func handleFacebookSignIn() {
        print("Facebook Sign In tapped")
        isSignedIn = true
    }
    
    private func handleEmailSignIn() {
        print("Email Sign In tapped with email: \(email)")
        isSignedIn = true
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(isSignedIn: .constant(false))
    }
}
