//
//  SnakeView.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/24/24.
//  Copyright (c) 2024 Ramon Jr Bahio
//
//  This file is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).
//  You may not use this file for commercial purposes. For more details, see the LICENSE file in the repository.
//
//  See the full license at https://creativecommons.org/licenses/by-nc/4.0/

import UIKit
import Combine

@MainActor
class SnakeView: UIView {
    private var snakeHead: UIView!
    private var snakeBody: [UIView] = []
    private let segmentSize: CGFloat = screenWidth * 0.025

    private let viewModel = SnakeViewModel()
    lazy var cancellables = Set<AnyCancellable>()

    var snakeFruitCollisionHandler: ((CGRect) -> Bool)?
    var snakeRegularFruitCollisionHandler: [((CGRect) -> Bool)?] = [((CGRect) -> Bool)?]()
    var snakeBombCollisionHandler: [((CGRect) -> Bool)?] = [((CGRect) -> Bool)?]()
    var snakeCraterCollisionHandler: [((CGRect) -> Bool)?] = [((CGRect) -> Bool)?]()
    var snakeDeathCollisionHandler: (() -> Void)?
    var snakeShrinkReduceScoreHandler: (() -> Void)?

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
        viewModel.$snakeCurrentDirection
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snakeCurrentDirection in
                guard let self else { return }
                if viewModel.state == .playing {
                    changeSnakeDirection(snakeCurrentDirection)
                }
            }
            .store(in: &cancellables)
        viewModel.$moveInterval
            .receive(on: DispatchQueue.main)
            .sink { [weak self] moveInterval in
                guard let self else { return }
                viewModel.timeIntervalForMovement = gameStage.getSnakeSpeed(for: moveInterval)
            }
            .store(in: &cancellables)
    }

    func getTimeInterval() -> (CFTimeInterval,TimeInterval,(CFTimeInterval)->Void) {
        (viewModel.lastUpdateTime,viewModel.timeIntervalForMovement,{ lastUpdateTime in
            self.moveSnakeToCurrentDirection()
            self.viewModel.lastUpdateTime = lastUpdateTime
        })
    }

    private func setup() {
        setupBindings()
        setupSnake()
    }

    func updateState(_ gameState: GameStatus) {
        viewModel.state = gameState
    }

    func updateSnakeDirection(snakeDirection: SnakeDirection) {
        viewModel.snakeCurrentDirection = snakeDirection
    }

    private func changeSnakeDirection(_ snakeDirection: SnakeDirection) {
        moveSnake(to: snakeDirection)
    }

    private func moveSnake(to snakeDirection: SnakeDirection) {
        var newFrame = snakeHead.frame
        switch snakeDirection {
        case .up:
            newFrame.origin.y -= segmentSize
        case .down:
            newFrame.origin.y += segmentSize
        case .left:
            newFrame.origin.x -= segmentSize
        case .right:
            newFrame.origin.x += segmentSize
        }

        if gameStage.isCurrentStageExclusive(.hard) {
            if newFrame.minX < bounds.minX {
                newFrame.origin.x = bounds.maxX
            } else if newFrame.maxX > bounds.maxX {
                newFrame.origin.x = bounds.minX
            }
            if newFrame.minY < bounds.minY {
                newFrame.origin.y = bounds.maxY
            } else if newFrame.maxY > bounds.maxY {
                newFrame.origin.y = bounds.minY
            }
        }

        if gameStage != .hard && gameStage != .extreme {
            guard CGRect(origin: .zero, size: frame.size).contains(newFrame) else {
                guard let snakeDeathCollisionHandler else { return }
                snakeDeathCollisionHandler()
                resetSnake()
                return
            }
        }
        
        if gameStage != .hard && gameStage != .extreme {
            guard !checkSnakeSelfCollision(newFrame: newFrame) else {
                guard let snakeDeathCollisionHandler else { return }
                resetSnake()
                snakeDeathCollisionHandler()
                return
            }
        }

        var newSegment = UIView(frame: newFrame)
        let segmentImage = UIImageView(image: gameStage.getSnakePattern())
        segmentImage.frame = CGRect(origin: .zero, size: newSegment.frame.size)
        newSegment.addSubview(segmentImage)
        newSegment.alpha = 0
        newSegment.clipsToBounds = true
        newSegment = changeSnakeSegmentOrientation(newSegment)

        UIView.animate(withDuration: viewModel.moveInterval) {
            newSegment.alpha = 1
        } completion: { _ in
            self.addSubview(newSegment)
        }

        for snakeView in snakeBody {
            snakeView.layer.cornerRadius = .zero
        }

        snakeBody.insert(newSegment, at: 0)

        let lastSegment = snakeBody.removeLast()
        lastSegment.layer.cornerRadius = .zero
        UIView.animate(withDuration: viewModel.moveInterval) {
            lastSegment.alpha = 0
        } completion: { _ in
            lastSegment.removeFromSuperview()
        }

        snakeHead = snakeBody.first

        guard snakeBody.count > 0 else { return }

        if let hasCollidedWithFruit = snakeFruitCollisionHandler, hasCollidedWithFruit(newFrame) {
            growSnake()
            viewModel.moveInterval = viewModel.moveInterval - 0.01 == 0 ? viewModel.moveInterval - 0.001 : viewModel.moveInterval - 0.01
            Impact.medium.fire()
        }
        for eachRegularFruitHandler in snakeRegularFruitCollisionHandler {
            if let hasCollidedWithRegularFruit = eachRegularFruitHandler, hasCollidedWithRegularFruit(newFrame) {
                growSnake()
                viewModel.moveInterval = viewModel.moveInterval - 0.01 == 0 ? viewModel.moveInterval - 0.001 : viewModel.moveInterval - 0.01
                Impact.light.fire()
            }
        }

        if gameStage.isCurrentStageExclusive(.normal) {
            for eachBombHandler in snakeBombCollisionHandler {
                if let hasCollidedWithBomb = eachBombHandler, hasCollidedWithBomb(newFrame) {
                    callHasCollidedWithBomb()
                    Impact.medium.fire()
                }
            }

            for eachCraterHandler in snakeCraterCollisionHandler {
                if let hasCollidedWithCrater = eachCraterHandler, hasCollidedWithCrater(newFrame) {
                    guard let snakeDeathCollisionHandler else { return }
                    snakeDeathCollisionHandler()
                    resetSnake()
                    Impact.heavy.fire()
                }
            }
        }
    }

    func callHasCollidedWithBomb(_ bombView: BombView? = nil) {
        guard gameStage.isCurrentStageExclusive(.hard) && snakeBody.count > 1 else {
            guard let snakeDeathCollisionHandler else { return }
            snakeDeathCollisionHandler()
            resetSnake()
            return
        }

        shortenSnake()
        guard let snakeShrinkReduceScoreHandler else { return }
        snakeShrinkReduceScoreHandler()

        guard let bombView else { return }

        bombView.removeBomb()
        guard let bombDetonated = bombView.bombDetonatedByTimerHandler else { return }
        
        bombDetonated()
    }

    func isValidDirectionChange(_ newDirection: SnakeDirection) -> Bool {
        guard isCurrentAndDetectedDirectionCheckWall(newDirection) else { return true }
        var nextHeadPosition = CGRect()
        switch viewModel.snakeCurrentDirection {
        case .right:
            nextHeadPosition = snakeHead.frame.offsetBy(dx: segmentSize, dy: 0)
        case .up:
            nextHeadPosition = snakeHead.frame.offsetBy(dx: 0, dy: -segmentSize)
        case .down:
            nextHeadPosition = snakeHead.frame.offsetBy(dx: 0, dy: segmentSize)
        case .left:
            nextHeadPosition = snakeHead.frame.offsetBy(dx: -segmentSize, dy: 0)
        }

        switch newDirection {
        case .right:
            return nextHeadPosition.maxX < bounds.maxX
        case .up:
            return nextHeadPosition.minY > bounds.minY
        case .down:
            return nextHeadPosition.maxY < bounds.maxY
        case .left:
            return nextHeadPosition.minX > bounds.minX
        }
    }

    private func isCurrentAndDetectedDirectionCheckWall(_ newDirection: SnakeDirection) -> Bool {
        let currentAndDetectedDirectionsToCheck: [(SnakeDirection, SnakeDirection)] = [
            (.right, .up), (.right, .down), (.up, .left), (.up, .right),
            (.left, .up), (.left, .down), (.down, .left), (.down, .right)
        ]
        return currentAndDetectedDirectionsToCheck.contains { $0 == (viewModel.snakeCurrentDirection, newDirection) }
    }

    private func setupSnake() {
        snakeHead = UIView(frame: CGRect(origin: .zero, size: CGSize(width: segmentSize, height: segmentSize)))
        let segmentImage = UIImageView(image: gameStage.getSnakePattern())
        segmentImage.frame = CGRect(origin: .zero, size: snakeHead.frame.size)
        snakeHead.addSubview(segmentImage)
        snakeHead.alpha = 0
        snakeHead.clipsToBounds = true
        addSubview(snakeHead)
        snakeBody.append(snakeHead)
        growSnake()
        updateSnakeDirection(snakeDirection: .right)
    }

    func getSnakeBodyFrames() -> [CGRect] {
        return subviews.map { $0.frame }
    }

    func resetSnake() {
        snakeBody.removeAll()
        for subview in subviews {
            subview.removeFromSuperview()
        }
        setupSnake()
    }

    func isFruitRandomPointInsideBody(_ newPoint: CGPoint) -> Bool {
        snakeBody.contains { $0.frame.contains(newPoint) }
    }

    func startGame() {
        if viewModel.state == .gameOver {
            viewModel.moveInterval = 0.1
        }
    }

    func getCurrentSnakeDirection() -> SnakeDirection {
        viewModel.snakeCurrentDirection
    }

    func moveSnakeToCurrentDirection() {
        guard viewModel.state == .playing else { return }
        moveSnake(to: viewModel.snakeCurrentDirection)
    }

    private func changeSnakeSegmentOrientation(_ segment: UIView) -> UIView {
        segment.layer.cornerRadius = segmentSize / 2
        switch viewModel.snakeCurrentDirection {
        case .up:
            segment.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        case .down:
            segment.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        case .left:
            segment.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        case .right:
            segment.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        }

        return segment
    }

    private func checkSnakeSelfCollision(newFrame: CGRect) -> Bool {
        guard let _ = (snakeBody.first {
            $0 != snakeHead && $0.frame.intersects(newFrame)
        })
        else { return false }

        return true
    }

    private func growSnake() {
        guard let lastSegment = snakeBody.last else { return }

        let newSegment = UIView(frame: lastSegment.frame)
        newSegment.alpha = 0
        UIView.animate(withDuration: viewModel.moveInterval) {
            newSegment.alpha = 1
        } completion: { _ in
            self.addSubview(newSegment)
        }

        snakeBody.append(newSegment)
    }

    func shortenSnake() {
        if snakeBody.count > 1 {
            let lastSegment = snakeBody.removeLast()
            lastSegment.removeFromSuperview()
        }
    }
}
