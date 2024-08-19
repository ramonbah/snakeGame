//
//  StageViewModel.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/22/24.
//  Copyright (c) 2024 Ramon Jr Bahio
//
//  This file is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).
//  You may not use this file for commercial purposes. For more details, see the LICENSE file in the repository.
//
//  See the full license at https://creativecommons.org/licenses/by-nc/4.0/

import Foundation

class StageViewModel {
    @Published var state: GameStatus = .initial
    @Published var numberOfPreviousSpawn: CGFloat = 1

    var numberOfMaxShadow = gameStage == .casual ? 5 : 10
    var whiteFruitScoreCounter = 0
    var bombSpawnerScoreCounter = 0
}
