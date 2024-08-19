//
//  StageViewModel.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/22/24.
//

import Foundation

class StageViewModel {
    @Published var state: GameStatus = .initial
    @Published var numberOfPreviousSpawn: CGFloat = 1

    var numberOfMaxShadow = gameStage == .casual ? 5 : 10
    var whiteFruitScoreCounter = 0
    var bombSpawnerScoreCounter = 0
}
