//
//  ShadowSnakeViewModel.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/29/24.
//

import Foundation

class ShadowSnakeViewModel {
    @Published var state: GameStatus = .paused
    @Published var snakeCurrentDirection: SnakeDirection = .right
    @Published var moveInterval: TimeInterval = 0.1

    var timeIntervalForMovement = TimeInterval()
    var lastUpdateTime = CFTimeInterval()
}
