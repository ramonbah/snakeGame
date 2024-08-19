//
//  ViewController.swift
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
class ViewController: UIViewController {
    private lazy var loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.color = ColorSet.loading.color()
        view.alpha = 0
        view.startAnimating()
        return view
    }()

    private lazy var directionGestureUp = UISwipeGestureRecognizer(
        target: self, action: #selector(checkDirection(_:))
    )
    private lazy var directionGestureDown = UISwipeGestureRecognizer(
        target: self, action: #selector(checkDirection(_:))
    )
    private lazy var directionGestureLeft = UISwipeGestureRecognizer(
        target: self, action: #selector(checkDirection(_:))
    )
    private lazy var directionGestureRight = UISwipeGestureRecognizer(
        target: self, action: #selector(checkDirection(_:))
    )

    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAnywhere(_:))
    )


    private var boardView: BoardView = BoardView(gameStatus: .initial)
    private var stageView: StageView = StageView(gameStatus: .initial)

    private let viewModel = ViewModel()
    lazy var cancellables = Set<AnyCancellable>()

    var commonTimer: CommonTimer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSet.abyss.color()
        // Do any additional setup after loading the view.
        viewModel.load()
        setupBindings()
        setupActions()

        commonTimer = CommonTimer(target: self, selector: #selector(timerSender))
    }

    private func setupBindings(){
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .loading:
                    self?.setupLoading()
                case .initial:
                    self?.setupInitialView()
                case .playing:
                    self?.setupPlaying()
                case .paused:
                    self?.setupPaused()
                case .gameOver:
                    self?.setupGameOverView()
                }
                self?.boardView.updateGameStatus(gameStatus: state)
                self?.stageView.updateGameStatus(gameStatus: state)
            }
            .store(in: &cancellables)
        viewModel.$snakeCurrentDirection
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snakeCurrentDirection in
                if self?.viewModel.state == .playing {
                    self?.stageView.updateSnakeDirection(snakeDirection: snakeCurrentDirection)
                }
            }
            .store(in: &cancellables)
    }

    private func setupActions(){
        boardView.updateStageHandler = { [weak self] in
            guard let self else { return }
            UIView.animate(withDuration: 0.2) {
                self.loadingView.color = ColorSet.loading.color()
                self.view.backgroundColor = ColorSet.abyss.color()
            }
            stageView.resetStage()
            updateColorsForStage()
            boardView.setStatusToInitial()
        }
        boardView.updateTimerStatusHandler =  { [weak self] playStatus in
            guard let self, let commonTimer else { return }
            switch playStatus {
            case .play:
                commonTimer.start()
            case .pause:
                commonTimer.pause()
            case .restart:
                commonTimer.reset()
            }
        }
        stageView.scoreIncreaseHandler = { [weak self] points in
            guard let self, let scoreUpdateHandler = boardView.scoreUpdateHandler else { return }
            scoreUpdateHandler(points)
        }
        stageView.updateGameStatusHandler = { [weak self] state in
            guard let self else { return }
            viewModel.state = state
        }
    }

    private func setupLoading() {
        view.addSubview(loadingView)
        loadingView.center = view.center

        UIView.animate(withDuration: 0.5, delay: 0.1) {
            self.loadingView.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.loadingView.alpha = 0
            } completion: { _ in
                self.loadingView.removeFromSuperview()
                self.viewModel.state = .initial
            }
        }
    }

    private func updateColorsForStage() {
        stageView.backgroundColor = ColorSet.stage.color()
        viewModel.hasLoaded = true

        boardView.frame.size = CGSize(width: view.frame.width, height: view.frame.width)
        boardView.center = view.center
        stageView.frame.origin.y = boardView.frame.origin.y + boardView.frame.size.height

        boardView.playPauseTapHandler = { [weak self] in
            guard let self else { return }

            if viewModel.state == .playing {
                viewModel.state = .paused
            } else {
                viewModel.state = .playing
            }
        }
    }

    private func setupInitialView() {
        stageView.backgroundColor = ColorSet.stage.color()
        if !viewModel.hasLoaded {
            view.addSubview(boardView)
            view.addSubview(stageView)
        }
        viewModel.hasLoaded = true
        view.addGestureRecognizer(directionGestureUp)
        view.addGestureRecognizer(directionGestureDown)
        view.addGestureRecognizer(directionGestureLeft)
        view.addGestureRecognizer(directionGestureRight)
        view.addGestureRecognizer(tapGesture)
        boardView.alpha = 0

        UIView.animate(withDuration: 0.2) {
            self.boardView.alpha = 1
        }

        boardView.frame.size = CGSize(width: view.frame.width, height: view.frame.width)
        boardView.center = view.center
        stageView.frame.origin.y = boardView.frame.origin.y + boardView.frame.size.height

        directionGestureUp.direction = .up
        directionGestureDown.direction = .down
        directionGestureRight.direction = .right
        directionGestureLeft.direction = .left
        directionGestureUp.numberOfTouchesRequired = 1
        directionGestureDown.numberOfTouchesRequired = 1
        directionGestureRight.numberOfTouchesRequired = 1
        directionGestureLeft.numberOfTouchesRequired = 1

        boardView.playPauseTapHandler = { [weak self] in
            guard let self else { return }

            if viewModel.state == .playing {
                viewModel.state = .paused
            } else {
                viewModel.state = .playing
            }
        }
    }

    private func showBoardView(_ show: Bool = true) {
        if show {
            UIView.animate(withDuration: 0.2) {
                self.boardView.frame = CGRect(origin: .zero,
                                              size: CGSize(
                                                width: screenWidth, height: screenWidth
                                              ))
                self.boardView.center = self.view.center
                self.boardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                self.stageView.frame.origin = CGPoint(
                    x: .zero, y: self.view.center.y - screenWidth / 2
                )
                self.stageView.frame.size = CGSize(width: screenWidth, height: .zero)
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                self.stageView.frame.origin.y = self.view.center.y - screenWidth / 2
                self.stageView.frame.size = CGSize(width: screenWidth, height: screenWidth)
                self.boardView.frame = CGRect(x: 0, y: self.view.center.y - screenWidth / 2 - screenWidth * 0.15,
                                              width: screenWidth, height: screenWidth * 0.15)
                self.boardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            }
        }

    }

    private func setupPaused() {
        showBoardView()
    }

    private func setupPlaying() {
        showBoardView(false)
    }

    private func setupGameOverView() {
        showBoardView()
        stageView.cleanupStage()
    }

    @objc func checkDirection(_ gesture: UISwipeGestureRecognizer) {
        var directionDetected: SnakeDirection = .right

        switch gesture.direction {
        case .up: directionDetected = .up
        case .down: directionDetected = .down
        case .left: directionDetected = .left
        default: directionDetected = .right
        }

        var snakeCurrentDirection: SnakeDirection {
            stageView.getCurrentSnakeDirection()
        }
        
        if snakeCurrentDirection != directionDetected &&
            snakeCurrentDirection.oppositeDirection() != directionDetected &&
            stageView.isValidDirectionChange(directionDetected) {
            viewModel.snakeCurrentDirection = directionDetected
        }
    }

    @objc func tapAnywhere(_ gesture: UITapGestureRecognizer) {
        boardView.hideTutorial()
    }

    @objc func timerSender() {
        guard let commonTimer else { return }

        boardView.setElapsedTime(commonTimer.getElapsedTimeString())
        
        let timeIntervalAndActionForSnake = stageView.getSnakeViewTimeInterval()
        commonTimer.perform(timeIntervalAndActionForSnake)

        for shadowSnakesInterval in stageView.getShadowSnakesViewTimeInterval() {
            commonTimer.perform(shadowSnakesInterval)
        }

        if gameStage.isCurrentStageExclusive(.easy) {
            let timeIntervalAndActionForFruit = stageView.getFruitTimeInterval()
            commonTimer.perform(timeIntervalAndActionForFruit)

            let actionForFruitUpdateFrame = stageView.getUpdateFrame()
            commonTimer.perform(actionForFruitUpdateFrame)
        }

        if stageView.getWhiteFruitWillStart() {
            let timeIntervalAndActionForWhiteFruit = stageView.getWhiteFruitTimeInterval()
            commonTimer.perform(timeIntervalAndActionForWhiteFruit)
        }

        if gameStage.isCurrentStageExclusive(.normal) {
            for regularFruitsTimeInterval in stageView.getRegularFruitTimeInterval() {
                commonTimer.perform(regularFruitsTimeInterval)
            }
            for regularFruitsUpdateFrame in stageView.getRegularUpdateFrame() {
                commonTimer.perform(regularFruitsUpdateFrame)
            }
        }

        for bombsTimeInterval in stageView.getBombsTimeInterval() {
            commonTimer.perform(bombsTimeInterval)
        }

        if gameStage.isCurrentStageExclusive(.hard) {
            for bombsUpdateFrame in stageView.getBombsUpdateFrame() {
                commonTimer.perform(bombsUpdateFrame)
            }
        }

        for cratersTimeInterval in stageView.getCratersTimeInterval() {
            commonTimer.perform(cratersTimeInterval)
        }
    }
}

