//
//  LeaderboardView.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/23/24.
//

import UIKit

@MainActor
class LeaderboardView: UIView {
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.text = "LEADERBOARD"
        view.textAlignment = .center
        view.setCustomFont(for: screenWidth * 0.09)
        return view
    }()

    private lazy var scoreLabel: UILabel = {
        let view = UILabel()
        view.text = "SCORE"
        view.textAlignment = .center
        view.font = .boldSystemFont(ofSize: screenWidth * 0.06)
        return view
    }()

    private lazy var playerLabel: UILabel = {
        let view = UILabel()
        view.text = "PLAYER"
        view.textAlignment = .center
        view.font = .boldSystemFont(ofSize: screenWidth * 0.06)
        return view
    }()

    private lazy var timeLabel: UILabel = {
        let view = UILabel()
        view.text = "TIME"
        view.textAlignment = .center
        view.font = .boldSystemFont(ofSize: screenWidth * 0.06)
        return view
    }()

    private lazy var playerNameTextField: UITextField = {
        let view = UITextField()
        view.frame.origin.x = -200
        view.delegate = self
        return view
    }()

    private let viewModel = LeaderboardViewModel()

    var scoreUpdateHandler: ((Int) -> Void)?
    var inputNameHandler: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        viewModel.load()
        addSubview(titleLabel)
        addSubview(scoreLabel)
        addSubview(playerLabel)
        addSubview(timeLabel)
        addSubview(playerNameTextField)

        titleLabel.sizeToFit()
        scoreLabel.sizeToFit()
        playerLabel.sizeToFit()
        timeLabel.sizeToFit()

        updateSubviews()

        setupActions()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func setupActions() {
        scoreUpdateHandler = { [weak self] score in
            self?.viewModel.currentPlayerScore = score
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        guard let inputNameHandler else { return }

        inputNameHandler("Stage")
        guard let playerNameTextFieldText = playerNameTextField.text else { return }
        viewModel.currentPlayerName = playerNameTextFieldText.uppercased()
        if viewModel.currentPlayerName.isEmpty {
            viewModel.currentPlayerName = "OOO"
        }
        
        guard viewModel.willCurrentPlayerBeAddedOnBoard() else { return }
        addCurrentPlayer()
    }

    private func addCurrentPlayer() {
        viewModel.topPlayersScores[gameStage.getInt()] = viewModel.currentPlayerScore
        viewModel.topPlayersTime[gameStage.getInt()] = viewModel.currentPlayerTime
        viewModel.topPlayersName[gameStage.getInt()] = viewModel.currentPlayerName
        viewModel.saveNewValues()
        updateBoard()
    }

    func updateBoard() {
        for view in subviews {
            if view.tag == 3 {
                view.removeFromSuperview()
            }
        }

        Task { updateSubviews() }
    }

    func updateCurrentTime(_ string: String) {
        viewModel.currentPlayerTime = string
    }

    func updateSubviews() {
        titleLabel.frame = CGRect(origin: .zero,
                                  size: CGSize(width: frame.size.width, height: titleLabel.frame.size.height))

        scoreLabel.frame = CGRect(origin: CGPoint(x: .zero, y: titleLabel.frame.size.height),
                                  size: CGSize(width: frame.size.width / 3, height: scoreLabel.frame.size.height))
        playerLabel.frame = CGRect(origin: CGPoint(x: scoreLabel.frame.size.width, y: titleLabel.frame.size.height),
                                   size: CGSize(width: frame.size.width / 3, height: playerLabel.frame.size.height))
        timeLabel.frame = CGRect(origin: CGPoint(x: playerLabel.frame.size.width * 2, y: titleLabel.frame.size.height),
                                   size: CGSize(width: frame.size.width / 3, height: timeLabel.frame.size.height))

        let leaderboardTotalHeight = frame.size.height - (timeLabel.frame.maxY)

        if !(viewModel.topPlayersName.isEmpty && viewModel.topPlayersScores.isEmpty && viewModel.topPlayersTime.isEmpty) {
            addLeaderboardContents(with: timeLabel.frame.maxY, and: leaderboardTotalHeight)
        }
    }

    func showKeyboardForPlayerName() {
        if viewModel.currentPlayerName == String() {
            guard let inputNameHandler else { return }

            inputNameHandler("ENTER PLAYER NAME:")
            Task{ playerNameTextField.becomeFirstResponder() }
        } else {
            guard viewModel.willCurrentPlayerBeAddedOnBoard() else { return }
            addCurrentPlayer()
        }
    }

    private func addLeaderboardContents(with currentOriginY: CGFloat, and totalHeight: CGFloat) {
        var currentY = currentOriginY
        let numberOfTopPlayers = viewModel.topPlayersScores.count
        for i in (0...(numberOfTopPlayers > 4 ? 4 : numberOfTopPlayers - 1)) {
            let playerScoreLabel = UILabel()
            playerScoreLabel.text = String(viewModel.topPlayersScores[i])
            playerScoreLabel.textColor = gameStage.getColor(viewModel.topPlayersStage[i])
            playerScoreLabel.textAlignment = .center
            playerScoreLabel.font = .boldSystemFont(ofSize: screenWidth * 0.05)
            playerScoreLabel.sizeToFit()
            playerScoreLabel.tag = 3
            playerScoreLabel.frame = CGRect(origin: CGPoint(x: .zero, y: currentY),
                                            size: CGSize(width: frame.size.width / 3, height: totalHeight / 5))
            addSubview(playerScoreLabel)

            let playerNameLabel = UILabel()
            playerNameLabel.text = viewModel.topPlayersName[i]
            playerNameLabel.textColor = gameStage.getColor(viewModel.topPlayersStage[i])
            playerNameLabel.textAlignment = .center
            playerNameLabel.setCustomFont(for: screenWidth * 0.05)
            playerNameLabel.sizeToFit()
            playerNameLabel.tag = 3
            playerNameLabel.frame = CGRect(origin: CGPoint(x: playerScoreLabel.frame.size.width, y: currentY),
                                           size: CGSize(width: frame.size.width / 3, height: totalHeight / 5))
            addSubview(playerNameLabel)

            let playerTimeLabel = UILabel()
            playerTimeLabel.text = viewModel.topPlayersTime[i]
            playerTimeLabel.textColor = gameStage.getColor(viewModel.topPlayersStage[i])
            playerTimeLabel.textAlignment = .center
            playerTimeLabel.font = .boldSystemFont(ofSize: screenWidth * 0.05)
            playerTimeLabel.sizeToFit()
            playerTimeLabel.tag = 3
            playerTimeLabel.frame = CGRect(origin: CGPoint(x: playerNameLabel.frame.size.width * 2, y: currentY),
                                           size: CGSize(width: frame.size.width / 3, height: totalHeight / 5))
            addSubview(playerTimeLabel)

            currentY = currentY + totalHeight / CGFloat(numberOfTopPlayers)
        }
    }
}

extension LeaderboardView: UITextFieldDelegate {
    func textField(
        _ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String
    ) -> Bool {
        let allowedCharacters = CharacterSet.letters
        let characterSet = CharacterSet(charactersIn: string)
        if !allowedCharacters.isSuperset(of: characterSet) {
            return false
        }

        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)

        if updatedText.count > 3 {
            return false
        }
        guard let inputNameHandler else { return false }

        inputNameHandler("ENTER PLAYER NAME: \(updatedText.uppercased())")
        if updatedText.count == 3 {
            playerNameTextField.text = updatedText
            textField.resignFirstResponder()
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
