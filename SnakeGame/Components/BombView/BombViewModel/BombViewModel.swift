//
//  BombViewModel.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/29/24.
//  Copyright (c) 2024 Ramon Jr Bahio
//
//  This file is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).
//  You may not use this file for commercial purposes. For more details, see the LICENSE file in the repository.
//
//  See the full license at https://creativecommons.org/licenses/by-nc/4.0/

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
