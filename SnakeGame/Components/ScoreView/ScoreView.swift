//
//  ScoreView.swift
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

class ScoreView: UIView {
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.text = "Score"
        view.setCustomFont(for: 15)
        return view
    }()

    private lazy var scoreLabel: UILabel = {
        let view = UILabel()
        view.setCustomFont(for: 20)
        return view
    }()

    private let viewModel = ScoreViewModel()

    var scoreIncreaseHandler: ((Int) -> Void)?
    var scoreUpdateHandler: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        addSubview(titleLabel)
        addSubview(scoreLabel)

        setupSubviews()
        setupAction()
    }

    private func setupAction() {
        scoreIncreaseHandler = { [weak self] points in
            guard let self else { return }
            
            viewModel.score = viewModel.score + points
            scoreLabel.text = String(viewModel.score)
            UIView.animate(withDuration: 0.2) {
                self.setupSubviews()
            }
            guard let scoreUpdateHandler else { return }
            scoreUpdateHandler(viewModel.score)
        }
    }

    private func setupSubviews() {
        titleLabel.setCustomFont(for: frame.size.height * 0.2)
        scoreLabel.setCustomFont(for: frame.size.height * 0.8)

        titleLabel.sizeToFit()
        scoreLabel.sizeToFit()

        guard let maxWidth = [titleLabel.frame.size.width, scoreLabel.frame.size.width].max() else { return }

        frame.size.width = maxWidth
        titleLabel.frame = CGRect(origin: .zero, size: CGSize(width: frame.size.width, height: titleLabel.frame.size.height))
        scoreLabel.frame = CGRect(origin: CGPoint(x: .zero, y: titleLabel.frame.size.height / 2), size: CGSize(width: frame.size.width, height: scoreLabel.frame.size.height))
    }

    func reset() {
        titleLabel.frame.size = .zero
        scoreLabel.text = String()
        viewModel.score = 0
    }
}
