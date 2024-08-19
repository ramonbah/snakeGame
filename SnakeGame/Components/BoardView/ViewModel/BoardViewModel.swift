//
//  BoardViewModel.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/22/24.
//

import Foundation

class BoardViewModel {
    @Published var state: GameStatus = .initial

    let casualSubtitle = "In this mode, you’ll control a single snake and pick flowers. It’s a great place to start if you’re new to the game. Just focus on picking flowers and growing your snake!"
    let easySubtitle = "Ready for a bit more challenge? Friendly snakes will appear when you pick-up mushrooms. These Friendly snakes will disapear when they meet the wall."
    let normalSubtitle = "Things get more interesting! Bombs will appear when you pick-up puzzle pieces. Be careful to avoid the bombs and keep your snake growing by catching the small animal and picking up puzzle pieces!"
    let hardSubtitle = "Step up to for an exciting challenge! Your snake can pass through walls, and you’ll face larger disappearing animals and more frequent bombs. Keep an eye out for bombs thrown from outside the screen—they’ll keep you on your toes!"
    let extremeSubtitle = "Are you ready for the ultimate test? The Extreme Stage combines all the toughest elements. Only the best can survive this intense challenge!"
}
