//
//  BoardView.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/22/24.
//

import UIKit
import Combine

@MainActor
class BoardView: UIView {
    private lazy var playPauseButton: UIButton = {
        let view = UIButton()
        view.layer.borderWidth = screenWidth * 0.005
        view.layer.cornerRadius = screenWidth * 0.03
        view.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: screenWidth * 0.065), forImageIn: .normal)
        view.titleLabel?.font = .boldSystemFont(ofSize: screenWidth * 0.065)
        return view
    }()

    private lazy var tutorialLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.isHidden = true
        view.setCustomFont(for: screenWidth * 0.06)
        view.numberOfLines = 0
        view.lineBreakMode = .byWordWrapping
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.alpha = 0
        return view
    }()

    private lazy var levelView: LevelView = LevelView(stage: .normal)

    private lazy var leaderboardView: LeaderboardView = LeaderboardView()

    private lazy var scoreView: ScoreView = ScoreView()
    private lazy var timeElapsedView: TimeElapsedView = TimeElapsedView()

    private let viewModel = BoardViewModel()
    lazy var cancellables = Set<AnyCancellable>()

    var playPauseTapHandler: (() -> Void)?
    var updateStageHandler: (() -> Void)?
    var scoreUpdateHandler: ((Int) -> Void)?
    var updateTimerStatusHandler: ((PlayStatus) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    init(gameStatus: GameStatus) {
        super.init(frame: .zero)
        setup()
        viewModel.state = gameStatus
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        self.layer.cornerRadius = screenWidth * 0.03
        self.backgroundColor = ColorSet.board.color()
        self.layer.borderColor = ColorSet.boardBorder.color().cgColor
        self.layer.borderWidth = screenWidth * 0.0075
        setupBindings()

        playPauseButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)

        addSubview(titleLabel)
        addSubview(playPauseButton)
        addSubview(levelView)
        addSubview(leaderboardView)
        addSubview(scoreView)
        addSubview(timeElapsedView)
        addSubview(tutorialLabel)

        scoreView.frame.origin = CGPoint(x: screenWidth * 0.025, y: screenWidth * 0.025)
        scoreView.frame.size.height = screenWidth * 0.1

        timeElapsedView.alpha = 0

        clipsToBounds = true

        setupActions()
    }

    private func setupBindings() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .initial:
                    self?.setInitialView()
                case .loading: break
                case .playing:
                    self?.setPlayView()
                case .paused:
                    self?.setPauseView()
                case .gameOver:
                    self?.setGameOverView()
                }
                self?.leaderboardView.alpha = state == .gameOver ? 1 : 0
            }
            .store(in: &cancellables)
    }

    func setStatusToInitial() {
        viewModel.state = .initial
    }

    private func setupActions() {
        levelView.changeLevelTapHandler = { [weak self] in
            guard let self else { return }
            UIView.animate(withDuration: 0.2) {
                self.levelView.frame.origin.x = (self.frame.size.width - self.levelView.frame.size.width) / 2
            }
            updateStage()
            guard let updateStageHandler else { return }
            updateStageHandler()
        }
        leaderboardView.inputNameHandler = { [weak self] string in
            self?.levelView.updatePlayerNameLabel(string)
        }
        scoreUpdateHandler = { [weak self] points in
            guard let self, let scoreIncreaseHandler = self.scoreView.scoreIncreaseHandler, viewModel.state == .playing || viewModel.state == .paused else { return }
            scoreIncreaseHandler(points)
        }
        scoreView.scoreUpdateHandler = { [weak self] score in
            guard let self, let scoreUpdateHandler = self.leaderboardView.scoreUpdateHandler else { return }
            scoreUpdateHandler(score)
        }
        timeElapsedView.updateTimeElapsedHandler = { [weak self] timeElapsedString in
            guard let self else { return }
            self.timeElapsedView.frame.origin = CGPoint(x: self.playPauseButton.frame.origin.x - self.timeElapsedView.frame.size.width, y: screenWidth * 0.025)
            guard !timeElapsedString.isEmpty else { return }
            self.leaderboardView.updateCurrentTime(timeElapsedString)
        }
        timeElapsedView.updateTimerStatusHandler = { [weak self] playStatus in
            guard let self, let updateTimerStatusHandler else { return }
            updateTimerStatusHandler(playStatus)
        }
    }

    private func updateStage() {
        setInitialView()
        backgroundColor = ColorSet.board.color()
        layer.borderColor = ColorSet.boardBorder.color().cgColor
    }

    @objc func buttonTap(_ : UIButton) {
        guard let playPauseTapHandler else { return }
        playPauseTapHandler()
    }

    private func setInitialView() {
        UIView.animate(withDuration: 0.2) {
            self.titleLabel.alpha = 1
            self.setPauseView()
            self.levelView.center = CGPoint(x: self.playPauseButton.center.x, y:  self.playPauseButton.center.y + screenWidth * 0.15)
            self.levelView.alpha = 1
        } completion: { _ in
            self.showTutorial()
        }
    }

    private func setTitleSize(_ size: TitleSize) {
        self.titleLabel.setCustomFont(for: UIScreen.main.bounds.size.width * size.rawValue)
        self.titleLabel.text = size == .big || viewModel.state == .gameOver ? (gameStage.isCurrentStageExclusive(.normal) ? "Snake💣" : "Snake") : (gameStage.isCurrentStageExclusive(.normal) ? "💣" : "")
        self.titleLabel.sizeToFit()
        self.titleLabel.frame = size == .big ?
        CGRect(origin: CGPoint(x: .zero, y: self.titleLabel.frame.height / 2),
               size: CGSize(width: self.frame.width, height: self.titleLabel.frame.height)) :
        CGRect(origin: CGPoint(x: (screenWidth - self.titleLabel.frame.width) / 2,
                               y: (screenWidth * 0.15 - self.titleLabel.frame.height) / 2),
               size: CGSize(width: self.titleLabel.frame.width, height: self.titleLabel.frame.height))
    }

    private func setPlayView() {
        UIView.animate(withDuration: 0.2) {
            self.setTitleSize(.small)
            self.playPauseButton.setImage(.init(systemName: PlayStatus.pause.rawValue), for: .normal)
            self.playPauseButton.tintColor = ColorSet.pauseTint.color()
            self.playPauseButton.frame.origin = CGPoint(x: self.frame.width - screenWidth * 0.125, y: screenWidth * 0.025)
            self.playPauseButton.frame.size = CGSize(width: screenWidth * 0.1, height: screenWidth * 0.1)
            self.playPauseButton.setTitle("", for: .normal)
            self.playPauseButton.layer.borderColor = ColorSet.pauseBorder.color().withAlphaComponent(0.5).cgColor
            self.timeElapsedView.frame.origin = CGPoint(x: self.playPauseButton.frame.origin.x - self.timeElapsedView.frame.size.width, y: screenWidth * 0.01)
            self.timeElapsedView.alpha = 1
        }
        self.timeElapsedView.startTimer()
        Impact.medium.fire()
    }

    private func setPauseView() {
        UIView.animate(withDuration: 0.2) {
            self.setTitleSize(.big)
            self.playPauseButton.setImage(.init(systemName: PlayStatus.play.rawValue), for: .normal)
            self.playPauseButton.tintColor = ColorSet.playTint.color()
            self.playPauseButton.setTitle(" \(PlayStatus.play.rawValue.uppercased())", for: .normal)
            self.playPauseButton.setTitleColor(ColorSet.playText.color(), for: .normal)
            self.playPauseButton.frame.size = CGSize(width: screenWidth * 0.25, height: screenWidth * 0.1)
            self.playPauseButton.frame.origin = CGPoint(
                x: (self.frame.size.width - screenWidth * 0.25) / 2,
                y: self.titleLabel.frame.origin.y + self.titleLabel.frame.height + 20
            )
            self.playPauseButton.layer.borderColor = ColorSet.playBorder.color().cgColor
            self.levelView.alpha = 0
        }
        self.timeElapsedView.alpha = 0
        self.timeElapsedView.pauseTimer()
        Impact.light.fire()
    }

    private func setGameOverView() {
        UIView.animate(withDuration: 0.2) {
            self.setTitleSize(.small)
            self.playPauseButton.setImage(.init(systemName: PlayStatus.restart.rawValue), for: .normal)
            self.playPauseButton.tintColor = ColorSet.resetTint.color()
            self.playPauseButton.setTitle(" \(PlayStatus.restart.rawValue.uppercased())", for: .normal)
            self.playPauseButton.setTitleColor(ColorSet.resetText.color(), for: .normal)
            self.playPauseButton.frame.size = CGSize(width: screenWidth * 0.38, height: screenWidth * 0.1)
            self.playPauseButton.frame.origin = CGPoint(x: self.frame.size.width - screenWidth * 0.405, y: self.frame.size.height - screenWidth * 0.125)
        }
        self.leaderboardView.frame = CGRect(origin: CGPoint(x: .zero, y: self.titleLabel.frame.size.height),
                                            size: CGSize(
                                                width: self.frame.size.width, height: self.levelView.frame.origin.y - self.titleLabel.frame.size.height
                                            ))
        self.leaderboardView.updateBoard()
        self.leaderboardView.showKeyboardForPlayerName()
        self.scoreView.reset()
        self.timeElapsedView.alpha = 0
        self.timeElapsedView.alpha = 0
        self.timeElapsedView.resetTimer()
        Impact.medium.fire()
    }

    func updateGameStatus(gameStatus: GameStatus) {
        viewModel.state = gameStatus
    }

    func setElapsedTime(_ elapsedTimeString: String) {
        timeElapsedView.updateTimerLabel(elapsedTimeString)
    }

    private func showTutorial() {
        if checkTutorial() {
            tutorialLabel.alpha = 0
            tutorialLabel.isHidden = false
            tutorialLabel.backgroundColor = ColorSet.board.color()
            tutorialLabel.text = {
                switch gameStage {
                case .casual: viewModel.casualSubtitle
                case .easy: viewModel.easySubtitle
                case .normal: viewModel.normalSubtitle
                case .hard: viewModel.hardSubtitle
                case .extreme: viewModel.extremeSubtitle
                }
            }()

            guard let tutorialLabelText = tutorialLabel.text else { return }
            tutorialLabel.text = "\(gameStage.rawValue.uppercased())\n\n" + tutorialLabelText + "\n\n Tap anywhere to continue"

            tutorialLabel.frame.origin = CGPoint(x: 20, y: .zero)
            tutorialLabel.frame.size = CGSize(width: screenWidth - 40, height: screenWidth)
            UIView.animate(withDuration: 0.2) {
                self.tutorialLabel.alpha = 1
            }

            setTutorialToShown()
        }
    }

    private func checkTutorial() -> Bool {
        UserDefaults.standard.value(forKey: gameStage.rawValue) == nil
    }

    private func setTutorialToShown() {
        UserDefaults.standard.setValue(1, forKey: gameStage.rawValue)
    }

    func hideTutorial() {
        tutorialLabel.isHidden = true
    }
}
