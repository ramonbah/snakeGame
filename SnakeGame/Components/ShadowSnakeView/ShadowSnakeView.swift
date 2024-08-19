//
//  ShadowSnakeView.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/29/24.
//

import UIKit
import Combine

@MainActor
class ShadowSnakeView: UIView {
    private var snakeHead: UIView!
    private var snakeBody: [UIView] = []
    private let segmentSize: CGFloat = screenWidth * 0.025

    private let viewModel = SnakeViewModel()
    lazy var cancellables = Set<AnyCancellable>()

    var snakeFruitCollisionHandler: ((CGRect) -> Bool)?
    var snakeRegularFruitCollisionHandler: [((CGRect) -> Bool)?] = [((CGRect) -> Bool)?]()
    var snakeBombCollisionHandler: ((CGRect) -> Bool)?
    var snakeRemoveShadowHandler: (() -> Void)?

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

    private func setup() {
        setupBindings()
        setupSnake()
    }

    func getTimeInterval() -> (CFTimeInterval,TimeInterval,(CFTimeInterval)->Void) {
        (viewModel.lastUpdateTime,viewModel.timeIntervalForMovement,{ lastUpdateTime in
            self.moveSnakeToCurrentDirection()
            self.viewModel.lastUpdateTime = lastUpdateTime
        })
    }

    func updateState(_ gameState: GameStatus) {
        viewModel.state = gameState
    }

    func updateSnakeDirection() {
        var directionDetected: SnakeDirection = .right
        repeat {
            directionDetected = SnakeDirection.random
        } while viewModel.snakeCurrentDirection.oppositeDirection() == directionDetected || (viewModel.snakeCurrentDirection == directionDetected)

        viewModel.snakeCurrentDirection = directionDetected
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

        if gameStage == .casual {
            if newFrame.minX < bounds.minX {
                newFrame.origin.x = bounds.maxX - segmentSize
            } else if newFrame.maxX > bounds.maxX {
                newFrame.origin.x = bounds.minX
            }
            if newFrame.minY < bounds.minY {
                newFrame.origin.y = bounds.maxY - segmentSize
            } else if newFrame.maxY > bounds.maxY {
                newFrame.origin.y = bounds.minY
            }
        } else {
            guard CGRect(origin: .zero, size: frame.size).contains(newFrame) else {
                guard let snakeRemoveShadowHandler = snakeRemoveShadowHandler else { return }
                snakeRemoveShadowHandler()
                removeShadow()
                return
            }
        }

        var newSegment = UIView(frame: newFrame)
        newSegment.backgroundColor = ColorSet.shadowSnake.color()
        newSegment.alpha = 0
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
            Impact.light.fire()
        }
        for eachRegularFruitHandler in snakeRegularFruitCollisionHandler {
            if let hasCollidedWithRegularFruit = eachRegularFruitHandler, hasCollidedWithRegularFruit(newFrame) {
                growSnake()
                viewModel.moveInterval = viewModel.moveInterval - 0.01 == 0 ? viewModel.moveInterval - 0.001 : viewModel.moveInterval - 0.01
                Impact.light.fire()
            }
        }

        if gameStage.isCurrentStageExclusive(.normal) {
            if let hasCollidedWithBomb = snakeBombCollisionHandler, hasCollidedWithBomb(newFrame) {
                removeShadow()
                guard let snakeRemoveShadowHandler = snakeRemoveShadowHandler else { return }
                snakeRemoveShadowHandler()
                Impact.medium.fire()
            }
        }
    }

    private func setupSnake() {
        snakeHead = UIView(frame: CGRect(origin: .zero, size: CGSize(width: segmentSize, height: segmentSize)))
        addSubview(snakeHead)
        snakeBody.append(snakeHead)
        growSnake()
        viewModel.state = .playing
    }

    func setSnakeInitialSpawnPoint(_ snakePoint: CGPoint) {
        snakeHead.frame.origin = snakePoint
    }

    func getSegmentSize() -> CGFloat {
        return segmentSize
    }

    func isFruitRandomPointInsideBody(_ newPoint: CGPoint) -> Bool {
        snakeBody.contains { $0.frame.contains(newPoint) }
    }

    func startGame() {
        if viewModel.state == .gameOver {
            viewModel.moveInterval = 0.1
        }
    }

    func removeShadow() {
        removeFromSuperview()
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
}

