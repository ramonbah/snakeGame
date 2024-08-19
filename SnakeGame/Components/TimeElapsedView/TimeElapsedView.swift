//
//  TimeElapsedView.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/29/24.
//

import Foundation
import UIKit

class TimeElapsedView: UILabel {
    private lazy var timerLabel: UILabel = UILabel()

    var updateTimeElapsedHandler: ((String) -> Void)?
    var updateTimerStatusHandler: ((PlayStatus) -> Void)?

    var lastUpdateTime = CFTimeInterval()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(timerLabel)
        timerLabel.setCustomFont(for: screenWidth * 0.06)
        timerLabel.text = "00:00.000"
        sizeToFit()

        guard let updateTimerStatusHandler else { return }
        updateTimerStatusHandler(.play)
    }

    func startTimer() {
        guard let updateTimerStatusHandler else { return }
        updateTimerStatusHandler(.play)
    }

    func pauseTimer() {
        guard let updateTimerStatusHandler else { return }
        updateTimerStatusHandler(.pause)
    }

    func resetTimer() {
        guard let updateTimerStatusHandler else { return }
        updateTimerStatusHandler(.restart)
        timerLabel.text = "00:00.000"
        sizeToFit()
    }

    override func sizeToFit() {
        timerLabel.sizeToFit()
        timerLabel.frame.origin.x = screenWidth * 0.025
        timerLabel.frame.size.height = screenWidth * 0.1
        frame.size = CGSize(width: timerLabel.frame.size.width, height: timerLabel.frame.size.height)
    }

    func updateTimerLabel(_ elapsedTimeString: String) {
        timerLabel.text = elapsedTimeString

        guard let updateTimeElapsedHandler else { return }
        updateTimeElapsedHandler(elapsedTimeString)
    }
}
