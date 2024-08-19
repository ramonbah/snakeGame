//
//  StageView.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/22/24.
//  Copyright (c) 2024 Ramon Jr Bahio
//
//  This file is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).
//  You may not use this file for commercial purposes. For more details, see the LICENSE file in the repository.
//
//  See the full license at https://creativecommons.org/licenses/by-nc/4.0/

import UIKit
import Combine

@MainActor
class StageView: UIView {
    private lazy var snakeView: SnakeView = SnakeView()
    private lazy var fruitView: FruitView = FruitView()

    private let viewModel = StageViewModel()
    lazy var cancellables = Set<AnyCancellable>()

    var snakeShadows = [ShadowSnakeView]()
    var regularFruits = [RegularFruitView]()
    var bombs = [BombView]()
    var craters = [CraterView]()

    var scoreIncreaseHandler: ((Int) -> Void)?
    var updateGameStatusHandler: ((GameStatus) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    init(gameStatus: GameStatus) {
        super.init(frame: .zero)
        setup()
        viewModel.state = gameStatus
    }

    private func setupBindings() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                showStage(state == .playing)
                snakeView.updateState(state)
                fruitView.updateState(state)
                for shadowSnake in snakeShadows {
                    shadowSnake.updateState(state)
                }
                for fruit in regularFruits {
                    fruit.updateState(state)
                }
                for bomb in bombs {
                    bomb.updateState(state)
                }
                for crater in craters {
                    crater.updateState(state)
                }
                guard state == .gameOver else { return }

                viewModel.numberOfPreviousSpawn = 1
            }
            .store(in: &cancellables)
        viewModel.$numberOfPreviousSpawn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] numberFruitsToSpawn in
                guard let self, viewModel.state == .playing else { return }
                self.spawnRegularFruit(numberFruitsToSpawn)
            }
            .store(in: &cancellables)
    }

    private func setup() {
        setupBindings()

        addSubview(snakeView)
        addSubview(fruitView)

        setupActions()

        //clipsToBounds = true
    }

    func resetStage() {
        snakeView.removeFromSuperview()
        fruitView.removeFromSuperview()

        snakeView = SnakeView()
        fruitView = FruitView()

        setup()
    }

    private func setupActions() {
        snakeView.snakeFruitCollisionHandler = { [weak self] newFrame in
            guard let self else { return false }
            if newFrame.intersects(gameStage.isCurrentStageExclusive(.easy) ? fruitView.getCurrentFrame(): fruitView.frame) {
                guard let fruitWillBeEatenHandler = fruitView.fruitWillBeEatenHandler else { return false }
                fruitWillBeEatenHandler()
                self.spawnFruit()
                self.spawnShadowSnake()
                if gameStage.isCurrentStageExclusive(.normal) {
                    self.spawnShadowSnake()
                    if gameStage == .normal {
                        self.spawnBombFromFruitConsumption()
                    }
                }
                return true
            }
            return false
        }
        fruitView.fruitEatenHandler = { [weak self] in
            guard let self, let scoreIncreaseHandler else { return }
            let scoreToAdd = gameStage.isCurrentStageExclusive(.hard) ? 4 : 2
            scoreIncreaseHandler(scoreToAdd)
            udpateWhiteFruitCheckScore(scoreToAdd)
            updateBombSpawnerCheckScore(scoreToAdd)
        }
        snakeView.snakeDeathCollisionHandler = { [weak self] in
            guard let self, let updateGameStatusHandler else { return }
            updateGameStatusHandler(.gameOver)
        }
        snakeView.snakeShrinkReduceScoreHandler = { [weak self] in
            guard let self, let scoreIncreaseHandler else { return }
            scoreIncreaseHandler(-1)
            udpateWhiteFruitCheckScore(-1)
            updateBombSpawnerCheckScore(-1)
        }
    }

    private func showStage(_ show: Bool = true) {
        snakeView.startGame()
        UIView.animate(withDuration: 0.2) {
            self.frame.size.width = screenWidth
            self.frame.size.height = show ? screenWidth : .zero
            self.snakeView.frame.size.width = self.frame.size.width
            self.snakeView.frame.size.height = show ? self.frame.size.height : .zero
            for shadowSnake in self.snakeShadows {
                shadowSnake.frame.size = self.snakeView.frame.size
            }
        }
    }

    func updateGameStatus(gameStatus: GameStatus) {
        viewModel.state = gameStatus
    }

    func updateSnakeDirection(snakeDirection: SnakeDirection) {
        snakeView.updateSnakeDirection(snakeDirection: snakeDirection)
        for shadowSnake in self.snakeShadows {
            shadowSnake.updateSnakeDirection()
        }
    }

    func getCurrentSnakeDirection() -> SnakeDirection {
        snakeView.getCurrentSnakeDirection()
    }

    func isValidDirectionChange(_ newDirection: SnakeDirection) -> Bool {
        snakeView.isValidDirectionChange(newDirection)
    }

    private func spawnFruit() {
        if isGameStatePlaying() {
            var newFruitPosition: CGPoint
            repeat {
                let x = CGFloat.random(in: bounds.minX..<bounds.maxX - fruitView.frame.size.width).rounded(.down)
                let y = CGFloat.random(in: bounds.minY..<bounds.maxY - fruitView.frame.size.height).rounded(.down)
                newFruitPosition = CGPoint(x: x, y: y)
            } while snakeView.isFruitRandomPointInsideBody(newFruitPosition) && isFruitRandomIntersectsOtherFruit(newFruitPosition) && isFruitRandomPointInsideAShadow(newFruitPosition)

            fruitView.frame.origin = newFruitPosition
            fruitView.alpha = 0
            UIView.animate(withDuration: 0.2) {
                self.fruitView.alpha = 1
            }

            guard gameStage.getInt() <= Stage.normal.getInt() else {
                guard regularFruits.isEmpty else { return }
                spawnRegularFruit(1)
                return
            }

            guard let numberToSpawn = (1...5).randomElement() else { return }
            viewModel.numberOfPreviousSpawn = regularFruits.count < 10 ? CGFloat(numberToSpawn) : 1
        }
    }

    private func spawnRegularFruit(_ numberOfFruits: CGFloat) {
        for _ in (1...Int(numberOfFruits)) {
            let regularFruit = RegularFruitView()
            var newFruitPosition: CGPoint
            repeat {
                let x = CGFloat.random(in: bounds.minX..<bounds.maxX - regularFruit.frame.size.width).rounded(.down)
                let y = CGFloat.random(in: bounds.minY..<bounds.maxY - regularFruit.frame.size.height).rounded(.down)
                newFruitPosition = CGPoint(x: x, y: y)
            } while snakeView.isFruitRandomPointInsideBody(newFruitPosition) && isFruitRandomIntersectsOtherFruit(newFruitPosition) && isFruitRandomPointInsideAShadow(newFruitPosition)

            regularFruit.frame.origin = newFruitPosition
            regularFruitSetupActions(regularFruit)
            regularFruit.updateState(viewModel.state)

            addSubview(regularFruit)
            sendSubviewToBack(regularFruit)
            regularFruits.append(regularFruit)

            regularFruit.alpha = 0
            UIView.animate(withDuration: 0.2) {
                regularFruit.alpha = 1
            }
        }
    }

    private func spawnBombFromFruitConsumption() {
        guard bombs.count < (gameStage == .hard ? 6 : 11), viewModel.state == .playing else { return }
        let bomb = BombView()
        var newBombPosition: CGPoint
        repeat {
            let x = CGFloat.random(in: bounds.minX..<bounds.maxX - bomb.frame.size.width).rounded(.down)
            let y = CGFloat.random(in: bounds.minY..<bounds.maxY - bomb.frame.size.height).rounded(.down)
            newBombPosition = CGPoint(x: x, y: y)
        } while snakeView.isFruitRandomPointInsideBody(newBombPosition) && isFruitRandomIntersectsOtherFruit(newBombPosition) && isFruitRandomPointInsideAShadow(newBombPosition)

        if gameStage.isCurrentStageExclusive(.hard) {
            bomb.setCenterInsideStageForAnimation(newBombPosition)
        } else if gameStage.isCurrentStageExclusive(.normal) {
            bomb.frame.origin = newBombPosition
        }

        bombSetupActions(bomb)
        bomb.updateState(viewModel.state)

        addSubview(bomb)
        bombs.append(bomb)

        if gameStage.isCurrentStageExclusive(.hard) {
            bomb.throwBomb()
        } else if gameStage.isCurrentStageExclusive(.normal) {
            bomb.alpha = 0
            UIView.animate(withDuration: 0.2) {
                bomb.alpha = 1
            }
        }
    }

    private func isFruitRandomIntersectsOtherFruit(_ point: CGPoint) -> Bool {
        if fruitView.frame.contains(point) || isFruitIntersectsRegularFruit(point) {
            return true
        }
        return false
    }

    private func isFruitRandomPointInsideAShadow(_ point: CGPoint) -> Bool {
        for shadow in snakeShadows {
            if shadow.isFruitRandomPointInsideBody(point) {
                return true
            }
        }
        return false
    }

    private func isFruitIntersectsRegularFruit(_ point: CGPoint) -> Bool {
        for fruit in regularFruits {
            if fruit.frame.contains(point) == true {
                return true
            }
        }
        return false
    }

    private func executeAfterDelay(seconds: Double, completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }

    private func bombSetupActions(_ bomb: BombView) {
        bomb.bombDetonatedByTimerHandler = { [weak self] in
            self?.showCrater(for: bomb)
            self?.bombs.removeAll { $0 == bomb }
            self?.startScreenShake()
        }
        bomb.bombWillBeDetonatedByShadowHandler = { [weak self] in
            guard let self, let scoreIncreaseHandler else { return }
            scoreIncreaseHandler(2)
            udpateWhiteFruitCheckScore(2)
            updateBombSpawnerCheckScore(2)
        }
        if gameStage.isCurrentStageExclusive(.hard) {
            bomb.bombWillBeDetonatedBySnakeHandler = { [weak self] bombFrame in
                guard let self else { return false }
                var didIntersect = false
                if let _ = snakeView.getSnakeBodyFrames().first(where: {$0.intersects(bombFrame)}) {
                    didIntersect = true
                }
                return didIntersect
            }
            bomb.bombDetonatedBySnakeHandler = { [weak self] bombView in
                guard let self else { return }
                startScreenShake()
                snakeView.callHasCollidedWithBomb(bombView)
            }
        }
        snakeView.snakeBombCollisionHandler.removeAll()
        snakeView.snakeBombCollisionHandler.append({ [weak self] newFrame in
            guard let self else { return false }
            for bomb in bombs {
                guard newFrame.intersects(gameStage.isCurrentStageExclusive(.hard) ? bomb.getCurrentFrame(): bomb.frame) else { return false }
                return true
            }
            return false
        })
        for shadowSnake in snakeShadows {
            shadowSnake.snakeBombCollisionHandler = { [weak self] newFrame in
                guard let self else { return false }
                for bomb in bombs {
                    if newFrame.intersects(bomb.frame) {
                        guard let bombWillBeDetonatedByShadowHandler = bomb.bombWillBeDetonatedByShadowHandler else { return false }
                        bombWillBeDetonatedByShadowHandler()
                        startScreenShake()
                        return true
                    }
                }
                return false
            }
        }
    }

    private func showCrater(for bomb: BombView) {
        let crater = CraterView()
        if gameStage.isCurrentStageExclusive(.hard) {
            crater.frame = CGRect(origin: CGPoint(x: bomb.getCurrentFrame().origin.x - bomb.frame.size.width, y: bomb.getCurrentFrame().origin.y - bomb.frame.size.height), size: CGSize(width: bomb.frame.size.width * 2, height: bomb.frame.size.height * 2))
            crater.setCraterImageSize()
        } else if gameStage.isCurrentStageExclusive(.normal) {
            crater.frame.size = CGSize(width: bomb.frame.size.width * 2, height: bomb.frame.size.height * 2)
            crater.center = bomb.center
            crater.setCraterImageSize()
        }
        crater.alpha = 0
        crater.updateState(viewModel.state)
        addSubview(crater)

        UIView.transition(with: crater, duration: 0.5, options: .transitionCrossDissolve, animations: {
            crater.alpha = 1
        })
        
        snakeView.snakeCraterCollisionHandler.removeAll()
        snakeView.snakeCraterCollisionHandler.append({ [weak self] newFrame in
            guard let self, gameStage.isCurrentStageExclusive(.normal) else { return false }
            for crater in self.craters {
                guard crater.getHasJustAppeared() == false, newFrame.intersects(crater.frame) else { return false }
                return true
            }
            return false
        })

        crater.craterRemovedByTimerHandler = { [weak self] in
            self?.craters.removeAll { $0 == crater }
        }

        craters.append(crater)
    }

    private func regularFruitSetupActions(_ regularFruit: RegularFruitView) {
        regularFruit.fruitEatenHandler = { [weak self] points in
            guard let self, let scoreIncreaseHandler else { return }
            scoreIncreaseHandler(points)
            updateBombSpawnerCheckScore(points)
            if gameStage.isCurrentStageExclusive(.hard) {
                guard regularFruits.count < 6 else { return }
                spawnRegularFruit(CGFloat(points))
            }
            regularFruits.removeAll { $0 == regularFruit }
            regularFruit.removeFruit()
        }

        snakeView.snakeRegularFruitCollisionHandler.removeAll()
        snakeView.snakeRegularFruitCollisionHandler.append({ [weak self] newFrame in
            guard let self else { return false }
            for fruit in regularFruits {
                if newFrame.intersects(fruit.frame) && fruit.frame.size != .zero && fruit.alpha == 1 && fruit.isHidden == false {
                    guard let fruitWillBeEatenHandler = fruit.fruitWillBeEatenHandler else { return false }
                    fruitWillBeEatenHandler()
                    if gameStage != .casual {
                        spawnShadowSnake()
                        if gameStage == .normal {
                            spawnBombFromFruitConsumption()
                        }
                    }
                    return true
                }
            }
            return false
        })
        for shadowSnake in snakeShadows {
            shadowSnake.snakeRegularFruitCollisionHandler.removeAll()
            shadowSnake.snakeRegularFruitCollisionHandler.append({ [weak self] newFrame in
                guard let self else { return false }
                for fruit in regularFruits {
                    if newFrame.intersects(fruit.frame) && fruit.frame.size != .zero && fruit.alpha == 1 && fruit.isHidden == false {
                        guard let fruitWillBeEatenHandler = fruit.fruitWillBeEatenHandler else { return false }
                        fruitWillBeEatenHandler()
                        if gameStage != .casual {
                            spawnShadowSnake()
                            if gameStage == .normal {
                                spawnBombFromFruitConsumption()
                            }
                        }
                        return true
                    }
                }
                return false
            })
        }
    }

    private func spawnShadowSnake() {
        guard viewModel.state == .playing, snakeShadows.count < viewModel.numberOfMaxShadow else { return }
        let shadowSnake = ShadowSnakeView()

        let x = CGFloat.random(in: bounds.minX..<bounds.maxX - shadowSnake.getSegmentSize()).rounded(.down)
        let y = CGFloat.random(in: bounds.minY..<bounds.maxY - shadowSnake.getSegmentSize()).rounded(.down)
        shadowSnake.setSnakeInitialSpawnPoint(CGPoint(x: x, y: y))

        shadowSnake.frame.size = self.snakeView.frame.size
        shadowSnake.startGame()
        shadowSnakeSetupActions()
        addSubview(shadowSnake)
        sendSubviewToBack(shadowSnake)
        snakeShadows.append(shadowSnake)
    }

    private func shadowSnakeSetupActions() {
        for shadowSnake in snakeShadows {
            shadowSnake.snakeFruitCollisionHandler = { [weak self] newFrame in
                guard let self else { return false }
                if newFrame.intersects(gameStage.isCurrentStageExclusive(.normal) ? fruitView.getCurrentFrame(): fruitView.frame) {
                    guard let fruitWillBeEatenHandler = fruitView.fruitWillBeEatenHandler else { return false }
                    fruitWillBeEatenHandler()
                    self.spawnFruit()
                    self.spawnShadowSnake()
                    if gameStage.isCurrentStageExclusive(.normal) {
                        self.spawnShadowSnake()
                        if gameStage == .normal {
                            self.spawnBombFromFruitConsumption()
                        }
                    }
                    return true
                }
                return false
            }
            shadowSnake.snakeRemoveShadowHandler = { [weak self] in
                self?.snakeShadows.removeAll { $0 == shadowSnake }
            }
        }
    }

    private func isGameStatePlaying() -> Bool {
        viewModel.state == .playing && (!bounds.width.isZero && !bounds.height.isZero)
    }

    func cleanupStage() {
        for shadow in snakeShadows {
            shadow.removeShadow()
        }
        for fruit in regularFruits {
            fruit.removeFruit()
        }
        snakeShadows.removeAll()
        regularFruits.removeAll()
        removeBombsAndCrates()
    }

    func removeBombsAndCrates() {
        for bomb in bombs {
            bomb.removeBomb()
        }
        for crater in craters {
            crater.removeCrater()
        }
        bombs.removeAll()
        craters.removeAll()
    }

    private func updateBombSpawnerCheckScore(_ points: Int) {
        if gameStage.isCurrentStageExclusive(.hard) {
            viewModel.bombSpawnerScoreCounter = viewModel.bombSpawnerScoreCounter + points
            if viewModel.bombSpawnerScoreCounter >= (gameStage.isCurrentStageExclusive(.extreme) ? 3 : 5) {
                self.spawnBombFromFruitConsumption()//spawnBombFromPoints
                viewModel.bombSpawnerScoreCounter = 0
            }
        }
    }

    private func udpateWhiteFruitCheckScore(_ points: Int) {
        if gameStage.isCurrentStageExclusive(.extreme) {
            viewModel.whiteFruitScoreCounter = viewModel.whiteFruitScoreCounter + points
            guard viewModel.whiteFruitScoreCounter >= 50, fruitView.backgroundColor != .white else { return }
            removeBombsAndCrates()
            fruitView.startWhiteFruitTimer()
            viewModel.whiteFruitScoreCounter = 0
        }
    }

    func startScreenShake() {
        let shakeDuration: CFTimeInterval = 0.6

        let shakeAnimation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shakeAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        shakeAnimation.duration = shakeDuration
        shakeAnimation.values = [-20, 20, -15, 15, -10, 10, -5, 5, 0]
        shakeAnimation.repeatCount = 1

        layer.add(shakeAnimation, forKey: "shake")
    }

    func getSnakeViewTimeInterval() -> (CFTimeInterval,TimeInterval,(CFTimeInterval)->Void) {
        snakeView.getTimeInterval()
    }

    func getShadowSnakesViewTimeInterval() -> [(CFTimeInterval,TimeInterval,(CFTimeInterval)->Void)] {
        snakeShadows.map { $0.getTimeInterval() }
    }

    func getFruitTimeInterval() -> (CFTimeInterval,TimeInterval,(CFTimeInterval)->Void) {
        fruitView.getTimeInterval()
    }

    func getWhiteFruitTimeInterval() -> (CFTimeInterval,TimeInterval,(CFTimeInterval)->Void) {
        fruitView.getTimeIntervalForWhiteFruit()
    }

    func getUpdateFrame() -> (CFTimeInterval,TimeInterval,(CFTimeInterval)->Void) {
        fruitView.getUpdateFrame()
    }

    func getWhiteFruitWillStart() -> Bool {
        fruitView.getWhiteFruitWillStart()
    }

    func getRegularFruitTimeInterval() -> [(CFTimeInterval,TimeInterval,(CFTimeInterval)->Void)] {
        regularFruits.map { $0.getTimeInterval() }
    }

    func getRegularUpdateFrame() -> [(CFTimeInterval,TimeInterval,(CFTimeInterval)->Void)] {
        regularFruits.map { $0.getUpdateFrame() }
    }

    func getBombsTimeInterval() -> [(CFTimeInterval,TimeInterval,(CFTimeInterval)->Void)] {
        bombs.map { $0.getTimeInterval() }
    }

    func getBombsUpdateFrame() -> [(CFTimeInterval,TimeInterval,(CFTimeInterval)->Void)] {
        bombs.map { $0.getUpdateFrame() }
    }

    func getCratersTimeInterval() -> [(CFTimeInterval,TimeInterval,(CFTimeInterval)->Void)] {
        craters.map { $0.getTimeInterval() }
    }
}
