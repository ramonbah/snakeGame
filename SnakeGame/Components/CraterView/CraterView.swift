//
//  CraterView.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/30/24.
//  Copyright (c) 2024 Ramon Jr Bahio
//
//  This file is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).
//  You may not use this file for commercial purposes. For more details, see the LICENSE file in the repository.
//
//  See the full license at https://creativecommons.org/licenses/by-nc/4.0/

import UIKit
import Combine

@MainActor
class CraterView: UIView {
    private lazy var craterImage: UIImageView = {
        let view = UIImageView()
        view.image = gameStage.getCraterImage()
        view.contentMode = .scaleToFill
        return view
    }()
    private let craterSize: FruitBombSize = .regular
    private let craterTimeLabel = UILabel()
    private let viewModel = CraterViewModel()
    lazy var cancellables = Set<AnyCancellable>()

    var craterRemovedByTimerHandler: (() -> Void)?

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
                craterTimeLabel.frame = CGRect(origin: .zero, size: CGSize(width: frame.size.width, height: frame.size.height))
            }
            .store(in: &cancellables)
        viewModel.$craterTimerValue
            .receive(on: DispatchQueue.main)
            .sink { [weak self] craterTimerValue in
                guard let self else { return }
                craterTimerUpdate(craterTimerValue)
            }
            .store(in: &cancellables)
    }

    private func setup() {
        setupBindings()
        frame.origin = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midX)
        frame.size = CGSize(width: craterSize.getValue(), height: craterSize.getValue())
        craterImage.frame = CGRect(origin: .zero, size: frame.size)

        addSubview(craterImage)

        setupActions()

        viewModel.hasJustAppeared = true
    }

    func getHasJustAppeared() -> Bool {
        viewModel.hasJustAppeared
    }

    private func setupActions() {

    }

    func getTimeInterval() -> (CFTimeInterval,TimeInterval,(CFTimeInterval)->Void) {
        return (viewModel.lastUpdateTime,viewModel.timeIntervalForTimer,{ lastUpdateTime in
            self.viewModel.lastUpdateTime = lastUpdateTime
            self.craterTimerAction()
        })
    }

    func craterTimerAction() {
        if viewModel.state == .playing {
            viewModel.hasJustAppeared = false
            viewModel.craterTimerValue = viewModel.craterTimerValue - 1
        }
    }

    func setCraterImageSize() {
        self.craterImage.frame.origin = .zero
        self.craterImage.frame.size = self.frame.size
    }

    private func craterTimerUpdate(_ value:Int) {
        guard value == 0 else {
            craterTimeLabel.text = String(value)
            return
        }
        guard let craterRemovedByTimerHandler else { return }

        craterRemovedByTimerHandler()
        Impact.light.fire()
        removeCrater()
    }

    func updateState(_ gameState: GameStatus) {
        viewModel.state = gameState
    }

    func removeCrater() {
        removeFromSuperview()
    }
}
