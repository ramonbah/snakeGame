//
//  BombViewModel.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/29/24.
//

import Foundation
import UIKit

class BombViewModel {
    @Published var state: GameStatus = .paused
    @Published var bombTimerValue: Int = 10

    var currentFrame: CGRect?
    var centerInsideStageForAnimation: CGPoint?
    var timeIntervalForTimer: TimeInterval = 1
    var lastUpdateTime = CFTimeInterval()
    var lastUpdateTimeForFrame = CFTimeInterval()
}
