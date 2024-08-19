//
//  RegularFruitViewModel.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/29/24.
//

import Foundation
import UIKit

class RegularFruitViewModel {
    @Published var state: GameStatus = .paused

    var currentFrame: CGRect?
    var timeIntervalForMovement: TimeInterval = 1
    var lastUpdateTime = CFTimeInterval()
    var lastUpdateTimeForFrame = CFTimeInterval()
}
