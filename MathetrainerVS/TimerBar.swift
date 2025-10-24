//
//  TimerBar.swift
//  MathetrainerVS
//
//  Created by Klaus Gruber on 24.10.25.
//
// TimerBar.swift
import SwiftUI

struct TimerBar: View {
    let timeRemaining: Double
    let totalTime: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(height: 20)
                    .foregroundColor(Color.gray.opacity(0.3))

                Rectangle()
                    .frame(width: geometry.size.width * (timeRemaining / totalTime), height: 20)
                    .foregroundColor(timeRemaining < (totalTime * 0.2) ? .red : .blue)
                    .animation(.linear, value: timeRemaining)
            }
            .cornerRadius(10)
        }
        .frame(height: 20)
    }
}

#Preview {
    TimerBar(timeRemaining: 30, totalTime: 60)
        .padding()
}
