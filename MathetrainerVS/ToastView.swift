//
//  ToastView.swift
//  MathetrainerVS
//
//  Created by Klaus Gruber on 24.10.25.
//
// ToastView.swift
import SwiftUI

struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    let isCorrect: Bool

    var body: some View {
        if isShowing {
            Text(message)
                .font(.headline)
                .padding()
                .background(isCorrect ? Color.green : Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
        }
    }
}

#Preview {
    ToastView(message: "Richtig! 🦄", isShowing: .constant(true), isCorrect: true)
        .padding()
}
