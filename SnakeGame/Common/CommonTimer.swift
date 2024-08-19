//
//  CommonTimer.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/30/24.
//  Copyright (c) 2024 Ramon Jr Bahio
//
//  This file is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).
//  You may not use this file for commercial purposes. For more details, see the LICENSE file in the repository.
//
//  See the full license at https://creativecommons.org/licenses/by-nc/4.0/

import QuartzCore

class CommonTimer: CADisplayLink {
    var isTimerRunning = false
    var startTime: Date?
    var pauseTime: Date?
    var elapsedTime: TimeInterval = 0
    var timeInterval: TimeInterval = 0
    private var lastUpdateTime: CFTimeInterval = 0
    var displayLink: CADisplayLink?
    var target: Any
    var selector: Selector

    init(isTimerRunning: Bool = false, startTime: Date? = nil, pauseTime: Date? = nil, elapsedTime: TimeInterval = 0, timeInterval: TimeInterval = 0, displayLink: CADisplayLink? = nil, target: Any, selector: Selector) {
        self.isTimerRunning = isTimerRunning
        self.startTime = Date()
        self.pauseTime = pauseTime
        self.elapsedTime = elapsedTime
        self.timeInterval = timeInterval
        self.displayLink = displayLink
        self.target = target
        self.selector = selector

        self.displayLink = CADisplayLink(target: self.target, selector: self.selector)
        self.displayLink?.add(to: .main, forMode: .default)
        self.lastUpdateTime = CACurrentMediaTime()
    }

    func start() {
        if let pauseTime = pauseTime {
            let pauseDuration = Date().timeIntervalSince(pauseTime)
            startTime = startTime?.addingTimeInterval(pauseDuration)
        } else {
            startTime = Date()
        }
        isTimerRunning = true
        pauseTime = nil
    }

    func pause() {
        pauseTime = Date()
        isTimerRunning = false
    }

    func reset() {
        isTimerRunning = false
        startTime = nil
        pauseTime = nil
        elapsedTime = 0
    }

    func getElapsedTimeString() -> String {
        guard let startTime else { return "" }

        if isTimerRunning {
            elapsedTime = Date().timeIntervalSince(startTime)
        }

        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let milliseconds = Int((elapsedTime - Double(minutes * 60) - Double(seconds)) * 1000)

        guard minutes >= .zero || seconds >= .zero || milliseconds >= .zero else { return String() }

        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }

    func perform(_ action: (CFTimeInterval, TimeInterval, (CFTimeInterval) -> Void)) {
        let currentTime = CACurrentMediaTime()
        let elapsedTime = currentTime - action.0
        if elapsedTime >= action.1 {
            action.2(currentTime)
        }
    }

    func stopTimer() {
        displayLink?.invalidate()
        displayLink = nil
    }

    deinit {
        stopTimer()
    }
}
