//
//  CraterViewModel.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/30/24.
//

import Foundation
import UIKit

class CraterViewModel {
    @Published var state: GameStatus = .paused
    @Published var craterTimerValue: Int = 15

    var hasJustAppeared: Bool = true
    var timeIntervalForTimer: TimeInterval = 1
    var lastUpdateTime = CFTimeInterval()
}
