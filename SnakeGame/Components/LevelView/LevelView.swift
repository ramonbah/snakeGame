//
//  LevelView.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/23/24.
//

import UIKit
import Combine

@MainActor
class LevelView: UIView {
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.text = "Stage"
        view.font = .boldSystemFont(ofSize: screenWidth * 0.05)
        view.textAlignment = .center
        return view
    }()

    private lazy var levelLabel: UILabel = {
        let view = UILabel()
        view.setCustomFont(for: screenWidth * 0.08)
        view.textAlignment = .center
        return view
    }()

    private lazy var decreaseButton: UIButton = {
        let view = UIButton()
        view.setImage(.init(systemName: "arrowshape.left"), for: .normal)
        view.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: screenWidth * 0.065), forImageIn: .normal)
        return view
    }()

    private lazy var increaseButton: UIButton = {
        let view = UIButton()
        view.setImage(.init(systemName: "arrowshape.right"), for: .normal)
        view.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: screenWidth * 0.065), forImageIn: .normal)
        return view
    }()

    private let viewModel = LevelViewModel()
    lazy var cancellables = Set<AnyCancellable>()

    var changeLevelTapHandler: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    init(stage: Stage) {
        super.init(frame: .zero)
        setup()
    }

    private func setupBindings() {
        viewModel.$stage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stage in
                UIView.animate(withDuration: 0.2) {
                    self?.setColors()
                    self?.setupSubviews()
                }
            }
            .store(in: &cancellables)
    }

    func updatePlayerNameLabel(_ string: String) {
        titleLabel.text = string
    }

    private func setup() {
        setupBindings()
        
        addSubview(titleLabel)
        addSubview(levelLabel)
        addSubview(decreaseButton)
        addSubview(increaseButton)

        decreaseButton.addTarget(self, action: #selector(decreaseTap(_:)), for: .touchUpInside)
        increaseButton.addTarget(self, action: #selector(increaseTap(_:)), for: .touchUpInside)
    }

    private func setupSubviews() {
        levelLabel.sizeToFit()
        titleLabel.sizeToFit()

        frame.size = CGSize(width: levelLabel.frame.size.width + screenWidth * 0.375, height:titleLabel.frame.size.height / 2 + screenWidth * 0.15)

        titleLabel.frame = CGRect(origin: .zero,
                                  size: CGSize(width: frame.size.width, height: titleLabel.frame.size.height))
        decreaseButton.frame = CGRect(origin: CGPoint(x: 0, y: titleLabel.frame.size.height / 2),
                                      size: CGSize(width: screenWidth * 0.15, height: screenWidth * 0.15))
        levelLabel.frame = CGRect(origin: CGPoint(x: screenWidth * 0.15, y: titleLabel.frame.size.height / 2),
                                  size: CGSize(width: levelLabel.frame.size.width + screenWidth * 0.075, height: screenWidth * 0.15))
        increaseButton.frame = CGRect(origin: CGPoint(x: levelLabel.frame.size.width + screenWidth * 0.15,
                                                      y: titleLabel.frame.size.height / 2),
                                      size: CGSize(width: screenWidth * 0.15, height: screenWidth * 0.15))
    }

    private func setColors(){
        titleLabel.textColor = ColorSet.level.color()
        decreaseButton.tintColor = ColorSet.level.color()
        increaseButton.tintColor = ColorSet.level.color()
        levelLabel.textColor = ColorSet.level.color()
        levelLabel.text = gameStage.rawValue.uppercased()
    }

    @objc func decreaseTap(_ : UIButton) {
        didChangeLevel(forIncrease: false)
    }

    @objc func increaseTap(_ : UIButton) {
        didChangeLevel(forIncrease: true)
    }

    private func didChangeLevel(forIncrease: Bool) {
        gameStage = viewModel.stage.changeStage(toIncrease: forIncrease)
        viewModel.stage = viewModel.stage.changeStage(toIncrease: forIncrease)
        guard let changeLevelTapHandler else { return }
        Task { @MainActor in
            try await Task.sleep(nanoseconds: UInt64(0.2))
            changeLevelTapHandler()
        }
    }
}
