//
//  SnakeViewModel.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/24/24.
//

import Foundation

class SnakeViewModel {
    @Published var state: GameStatus = .paused
    @Published var snakeCurrentDirection: SnakeDirection = .right
    @Published var moveInterval: TimeInterval = 0.1

    var timeIntervalForMovement = TimeInterval()
    var lastUpdateTime = CFTimeInterval()
}
