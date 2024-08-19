//
//  FruitViewModel.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/25/24.
//  Copyright (c) 2024 Ramon Jr Bahio
//
//  This file is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).
//  You may not use this file for commercial purposes. For more details, see the LICENSE file in the repository.
//
//  See the full license at https://creativecommons.org/licenses/by-nc/4.0/

import Foundation
import UIKit

class FruitViewModel {
    @Published var state: GameStatus = .paused

    var currentFrame: CGRect?
    var timeIntervalForMovement: TimeInterval = 1
    var timeIntervalForWhiteFruit: TimeInterval = 10
    var willStartWhiteFruit: Bool = false
    var lastUpdateTime = CFTimeInterval()
    var lastUpdateTimeForFrame = CFTimeInterval()
    var lastUpdateTimeForWhiteFruit = CFTimeInterval()
}
