//
//  ViewModel.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/22/24.
//

import Foundation

class ViewModel {
    @Published var state: GameStatus = .initial
    @Published var snakeCurrentDirection: SnakeDirection = .right

    var hasLoaded = false
    func load(){
        state = .loading
    }
}
