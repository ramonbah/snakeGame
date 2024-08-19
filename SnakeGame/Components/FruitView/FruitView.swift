//
//  FruitView.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/25/24.
//  Copyright (c) 2024 Ramon Jr Bahio
//
//  This file is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).
//  You may not use this file for commercial purposes. For more details, see the LICENSE file in the repository.
//
//  See the full license at https://creativecommons.org/licenses/by-nc/4.0/

import UIKit
import Combine

@MainActor
class FruitView: UIView {
    private lazy var fruitImage: UIImageView = {
        let view = UIImageView()
        view.image = gameStage.getFruitImage()
        return view
    }()
    private let fruitSize: FruitBombSize = .regular
    private let viewModel = FruitViewModel()
    lazy var cancellables = Set<AnyCancellable>()

    var fruitWillBeEatenHandler: (() -> Void)?
    var fruitEatenHandler: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setupBindings() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                alpha = state == .playing ? 1 : 0
            }
            .store(in: &cancellables)
    }

    private func setup() {
        setupBindings()
        frame.origin = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midX)
        frame.size = CGSize(width: fruitSize.getValue(), height: fruitSize.getValue())
        fruitImage.frame = CGRect(origin: .zero, size: frame.size)
        layer.cornerRadius = fruitSize.getValue() / 2
        clipsToBounds = true

        addSubview(fruitImage)

        setupActions()
    }

    func getTimeInterval() -> (CFTimeInterval,TimeInterval,(CFTimeInterval)->Void) {
        (viewModel.lastUpdateTime,viewModel.timeIntervalForMovement,{ lastUpdateTime in
            self.moveFruit()
            self.viewModel.lastUpdateTime = lastUpdateTime
        })
    }

    func getTimeIntervalForWhiteFruit() -> (CFTimeInterval,TimeInterval,(CFTimeInterval)->Void) {
        (viewModel.lastUpdateTimeForWhiteFruit,viewModel.timeIntervalForWhiteFruit,{ lastUpdateTime in
            self.revertFruit()
            self.viewModel.lastUpdateTimeForWhiteFruit = lastUpdateTime
        })
    }

    func getUpdateFrame() -> (CFTimeInterval,TimeInterval,(CFTimeInterval)->Void) {
        (viewModel.lastUpdateTimeForFrame,.zero,{ lastUpdateTime in
            self.updateFrame()
            self.viewModel.lastUpdateTimeForFrame = lastUpdateTime
        })
    }

    func updateFrame() {
        if let presentationLayer = layer.presentation() {
            viewModel.currentFrame = presentationLayer.frame
        }
    }

    func getCurrentFrame() -> CGRect{
        guard let currentFrame = viewModel.currentFrame else { return .zero }
        return currentFrame
    }

    func moveFruit() {
        if viewModel.state == .playing {
            guard let superview else { return }
            var newFruitPosition: CGPoint
            repeat {
                let x = CGFloat.random(in: superview.bounds.minX..<superview.bounds.maxX - self.fruitSize.getValue()).rounded(.down)
                let y = CGFloat.random(in: superview.bounds.minY..<superview.bounds.maxY - self.fruitSize.getValue()).rounded(.down)
                newFruitPosition = CGPoint(x: x, y: y)
            } while self.isNewPointInsideStage(newFruitPosition)

            let distance = (self.distanceBetweenPoints(self.frame.origin, newFruitPosition) / self.fruitSize.getValue()) / 10 * 2
            guard gameStage.isCurrentStageExclusive(.extreme) else {
                UIView.animate(withDuration: distance) {
                    self.frame.origin = newFruitPosition
                }
                return
            }
            UIView.animate(withDuration: distance, delay: .zero, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0) {
                self.frame.origin = newFruitPosition
            }
        }
    }

    private func distanceBetweenPoints(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx*dx + dy*dy)
    }

    private func isNewPointInsideStage(_ newPoint: CGPoint) -> Bool {
        guard superview?.frame.contains(newPoint) == true else { return false }
        return true
    }

    private func setupActions() {
        fruitWillBeEatenHandler = { [weak self] in
            guard let self, let fruitEatenHandler else { return }
            fruitEatenHandler()
            Impact.medium.fire()
        }
    }

    func updateState(_ gameState: GameStatus) {
        viewModel.state = gameState
    }

    func startWhiteFruitTimer() {
        viewModel.willStartWhiteFruit = true
    }

    func getWhiteFruitWillStart() -> Bool {
        viewModel.willStartWhiteFruit
    }

    func revertFruit() {
        viewModel.willStartWhiteFruit = false
    }
}
