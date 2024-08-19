//
//  ShadowSnakeViewModel.swift
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

class ShadowSnakeViewModel {
    @Published var state: GameStatus = .paused
    @Published var snakeCurrentDirection: SnakeDirection = .right
    @Published var moveInterval: TimeInterval = 0.1

    var timeIntervalForMovement = TimeInterval()
    var lastUpdateTime = CFTimeInterval()
}
