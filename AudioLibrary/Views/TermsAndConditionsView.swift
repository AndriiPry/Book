//
//  TermsAndConditionsView.swift
//  AudioLibrary
//
//  Created by Oleksii on 04.09.2025.
//
import SwiftUI

struct TermsAndConditionsView: View {
    @Binding var termsAccepted: Bool?
    @State private var isChecked = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms and Conditions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.top, 60)
                
                // Checkbox and text
                HStack(alignment: .top, spacing: 12) {
                    Button(action: {
                        isChecked.toggle()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isChecked ? Color.blue : Color.clear)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                            
                            if isChecked {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .bold))
                            }
                        }
                    }
                    .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("I agree to the")
                                .foregroundColor(.primary)
                            
                            Button("Terms of Services") {
                                // Handle terms of service tap
                            }
                            .foregroundColor(.blue)
                            
                            Text(". I have read and")
                                .foregroundColor(.primary)
                        }
                        
                        HStack(spacing: 4) {
                            Text("understand the")
                                .foregroundColor(.primary)
                            
                            Button("Privacy Policy") {
                                // Handle privacy policy tap
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .font(.system(size: 13))
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            
            // Bottom buttons
            VStack(spacing: 16) {
                Button(action: {
                    if isChecked {
                        termsAccepted = true
                    }
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(isChecked ? Color.blue : Color.gray.opacity(0.3))
                        )
                }
                .disabled(!isChecked)
                
                Button(action: {
                    termsAccepted = false
                }) {
                    Text("Decline")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
}

struct TermsDeclinedView: View {
    @Binding var termsAccepted: Bool?
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            VStack(spacing: 16) {
                Text("Terms Declined")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("You must accept the Terms and Conditions to use this app.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button(action: {
                termsAccepted = nil // Reset to show terms again
            }) {
                Text("Review Terms Again")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.blue)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
}
