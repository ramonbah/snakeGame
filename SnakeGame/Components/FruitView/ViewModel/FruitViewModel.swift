//
//  FruitViewModel.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/25/24.
//

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
