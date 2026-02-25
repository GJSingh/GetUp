// Views/CountdownView.swift
// 3-2-1 countdown shown before the workout begins.

import SwiftUI

struct CountdownView: View {
    @EnvironmentObject var vm: WorkoutViewModel

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            VStack(spacing: 24) {
                Text(vm.selectedExercise.emoji)
                    .font(.system(size: 72))

                Text(vm.selectedExercise.name)
                    .font(.custom("Georgia-Bold", size: 24))
                    .foregroundColor(.white)

                Text("Get ready!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "666680"))

                // Countdown number
                ZStack {
                    Circle()
                        .stroke(Color(hex: "00C896").opacity(0.2), lineWidth: 4)
                        .frame(width: 140, height: 140)

                    Circle()
                        .trim(from: 0, to: CGFloat(vm.countdown) / 3.0)
                        .stroke(Color(hex: "00C896"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: vm.countdown)

                    Text("\(vm.countdown)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.spring(response: 0.3), value: vm.countdown)
                }
                .padding(.top, 16)

                Text(vm.selectedExercise.cameraSetup)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "8888AA"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
            }
        }
    }
}
