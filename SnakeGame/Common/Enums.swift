//
//  Enums.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/22/24.
//

import UIKit


enum GameStatus {
    case loading, initial, playing, paused, gameOver
}

enum PlayStatus: String {
    case play, pause, restart
}

enum TitleSize: CGFloat {
    case big = 0.25
    case small = 0.1
}

enum FruitBombSize: CGFloat {
    case regular = 15
    case medium = 25
    case large = 35

    static var random: FruitBombSize {
        let fruitBombSizes: [FruitBombSize] = [.regular, .medium, .large]
        guard let randomElement = fruitBombSizes.randomElement() else { return .regular}
        return randomElement
    }

    func getValue() -> CGFloat {
        switch self {
        case .regular: screenWidth * 0.035
        case .medium: screenWidth * 0.045
        case .large: screenWidth * 0.055
        }
    }

    func getPoints() -> Int {
        switch self {
        case .regular: 1
        case .medium: 2
        case .large: 3
        }
    }

    func getAdditionalTime() -> Int {
        switch self {
        case .regular: 5
        case .medium: 10
        case .large: 15
        }
    }
}

enum Stage: String {
    case casual
    case easy
    case normal
    case hard
    case extreme

    func getInt() -> Int {
        switch self {
        case .casual: 0
        case .easy: 1
        case .normal: 2
        case .hard: 3
        case .extreme: 4
        }
    }

    func getSnakeSpeed(for currentMoveInterval: TimeInterval) -> TimeInterval {
        currentMoveInterval > getSnakeSpeedMax() ? currentMoveInterval : getSnakeSpeedInitial()
    }

    func getSnakeSpeedInitial() -> TimeInterval {
        switch self {
        case .casual: 0.1
        case .easy: 0.09
        case .normal: 0.08
        case .hard: 0.07
        case .extreme: 0.06
        }
    }

    private func getSnakeSpeedMax() -> TimeInterval {
        switch self {
        case .casual: 0.03
        case .easy: 0.02
        case .normal: 0.01
        case .hard: 0.009
        case .extreme: 0.008
        }
    }

    func getColor(_ stage: Stage = gameStage) -> UIColor {
        ColorSet.level.color(stage)
    }

    func changeStage(toIncrease: Bool) -> Stage {
        switch self {
        case .casual: toIncrease ? .easy : .extreme
        case .easy: toIncrease ? .normal : .casual
        case .normal: toIncrease ? .hard : .easy
        case .hard: toIncrease ? .extreme : .normal
        case .extreme: toIncrease ? .casual : .hard
        }
    }

    func isCurrentStageExclusive(_ stage: Stage) -> Bool {
        stage.getInt() <= getInt()
    }

    static func getStage(_ string: String) -> Stage {
        let stages: [Stage] = [.casual, .easy, .normal, .hard, .extreme]
        if let stageToReturn = stages.first(where: { $0.rawValue == string}) {
            return stageToReturn
        }
        return .normal
    }

    func getSnakePattern() -> UIImage {
        switch self {
        case .casual:
            guard let image = UIImage(named: SnakePattern.casualSnakePattern.rawValue) else { return UIImage() }
            return image
        case .easy:
            guard let image = UIImage(named: SnakePattern.easySnakePattern.rawValue) else { return UIImage() }
            return image
        case .normal:
            guard let image = UIImage(named: SnakePattern.normalSnakePattern.rawValue) else { return UIImage() }
            return image
        case .hard:
            guard let image = UIImage(named: SnakePattern.hardSnakePattern.rawValue) else { return UIImage() }
            return image
        case .extreme:
            guard let image = UIImage(named: SnakePattern.extremeSnakePattern.rawValue) else { return UIImage() }
            return image
        }
    }

    func getFruitRandomImage() -> UIImage {
        switch self {
        case .casual:
            guard let imageString = ["flower1","flower2","flower3"].randomElement(), let image = UIImage(named: imageString) else { return UIImage() }
            return image
        case .easy:
            guard let imageString = ["mushroom1","mushroom2","mushroom3"].randomElement(), let image = UIImage(named: imageString) else { return UIImage() }
            return image
        case .normal:
            guard let imageString = ["puzzle1","puzzle2","puzzle3"].randomElement(), let image = UIImage(named: imageString) else { return UIImage() }
            return image
        case .hard:
            guard let imageString = ["animal1","animal2","animal3"].randomElement(), let image = UIImage(named: imageString) else { return UIImage() }
            return image
        case .extreme:
            guard let imageString = ["fire1","fire2","fire3"].randomElement(), let image = UIImage(named: imageString) else { return UIImage() }
            return image
        }
    }

    func getFruitImage() -> UIImage {
        switch self {
        case .casual:
            guard let image = UIImage(named: "flower") else { return UIImage() }
            return image
        case .easy:
            guard let image = UIImage(named: "fairyWings") else { return UIImage() }
            return image
        case .normal:
            guard let image = UIImage(named: "creature") else { return UIImage() }
            return image
        case .hard:
            guard let image = UIImage(named: "beetle") else { return UIImage() }
            return image
        case .extreme:
            guard let image = UIImage(named: "skull") else { return UIImage() }
            return image
        }
    }

    func getCraterImage() -> UIImage {
        switch self {
        case .casual: return UIImage()
        case .easy: return UIImage()
        case .normal:
            guard let image = UIImage(named: "oldCrater") else { return UIImage() }
            return image
        case .hard:
            guard let image = UIImage(named: "newCrater") else { return UIImage() }
            return image
        case .extreme:
            guard let image = UIImage(named: "volcanicCrater") else { return UIImage() }
            return image
        }
    }
}

enum SnakePattern: String{
    case casualSnakePattern, easySnakePattern, normalSnakePattern, hardSnakePattern, extremeSnakePattern
}

typealias Impact = UIImpactFeedbackGenerator.FeedbackStyle
extension UIImpactFeedbackGenerator.FeedbackStyle {
    func fire() {
        let generator = UIImpactFeedbackGenerator(style: self)
        generator.prepare()
        generator.impactOccurred()
    }
}

enum ColorSet {
    case loading
    case abyss
    case board
    case boardBorder
    case level
    case stage
    case pauseTint
    case pauseBorder
    case pauseText
    case playTint
    case playBorder
    case playText
    case resetTint
    case resetBorder
    case resetText
    case shadowSnake
    case snake
    case fruit
    case regularFruit

    func color(_ stage: Stage = gameStage) -> UIColor {
        switch stage {
        case .casual: getCasualColor()
        case .easy: getEasyColor()
        case .normal: getNormalColor()
        case .hard: getHardColor()
        case .extreme: getExtremeColor()
        }
    }

    private func getCasualColor() -> UIColor {
        switch self {
        case .loading: .casualLoading
        case .abyss: .casualAbyss
        case .board: .casualBoard
        case .boardBorder: .casualBoardBorder
        case .level: .casualLevel
        case .stage: .casualStage
        case .pauseTint: .casualPauseTint
        case .pauseBorder: .casualPauseBorder
        case .pauseText: .casualPauseText
        case .playTint: .casualPlayTint
        case .playBorder: .casualPlayBorder
        case .playText: .casualPlayText
        case .resetTint: .casualResetTint
        case .resetBorder: .casualResetBorder
        case .resetText: .casualResetText
        case .snake: .clear
        case .shadowSnake: .casualShadowSnake
        case .fruit: .casualFruit
        case .regularFruit: .casualRegularFruit
        }
    }

    private func getEasyColor() -> UIColor {
        switch self {
        case .loading: .easyLoading
        case .abyss: .easyAbyss
        case .board: .easyBoard
        case .boardBorder: .easyBoardBorder
        case .level: .easyLevel
        case .stage: .easyStage
        case .pauseTint: .easyPauseTint
        case .pauseBorder: .easyPauseBorder
        case .pauseText: .easyPauseText
        case .playTint: .easyPlayTint
        case .playBorder: .easyPlayBorder
        case .playText: .easyPlayText
        case .resetTint: .easyResetTint
        case .resetBorder: .easyResetBorder
        case .resetText: .easyResetText
        case .snake: .clear
        case .fruit: .easyFruit
        case .shadowSnake: .easyShadowSnake
        case .regularFruit: .easyRegularFruit
        }
    }

    private func getNormalColor() -> UIColor {
        switch self {
        case .loading: .normalLoading
        case .abyss: .normalAbyss
        case .board: .normalBoard
        case .boardBorder: .normalBoardBorder
        case .level: .normalLevel
        case .stage: .normalStage
        case .pauseTint: .normalPauseTint
        case .pauseBorder: .normalPauseBorder
        case .pauseText: .normalPauseText
        case .playTint: .normalPlayTint
        case .playBorder: .normalPlayBorder
        case .playText: .normalPlayText
        case .resetTint: .normalResetTint
        case .resetBorder: .normalResetBorder
        case .resetText: .normalResetText
        case .snake: .clear
        case .fruit: .normalFruit
        case .shadowSnake: .normalShadowSnake
        case .regularFruit: .normalRegularFruit
        }
    }

    private func getHardColor() -> UIColor {
        switch self {
        case .loading: .hardLoading
        case .abyss: .hardAbyss
        case .board: .hardBoard
        case .boardBorder: .hardBoardBorder
        case .level: .hardLevel
        case .stage: .hardStage
        case .pauseTint: .hardPauseTint
        case .pauseBorder: .hardPauseBorder
        case .pauseText: .hardPauseText
        case .playTint: .hardPlayTint
        case .playBorder: .hardPlayBorder
        case .playText: .hardPlayText
        case .resetTint: .hardResetTint
        case .resetBorder: .hardResetBorder
        case .resetText: .hardResetText
        case .snake: .clear
        case .fruit: .hardFruit
        case .shadowSnake: .hardShadowSnake
        case .regularFruit: .hardRegularFruit
        }
    }

    private func getExtremeColor() -> UIColor {
        switch self {
        case .loading: .extremeLoading
        case .abyss: .extremeAbyss
        case .board: .extremeBoard
        case .boardBorder: .extremeBoardBorder
        case .level: .extremeLevel
        case .stage: .extremeStage
        case .pauseTint: .extremePauseTint
        case .pauseBorder: .extremePauseBorder
        case .pauseText: .extremePauseText
        case .playTint: .extremePlayTint
        case .playBorder: .extremePlayBorder
        case .playText: .extremePlayText
        case .resetTint: .extremeResetTint
        case .resetBorder: .extremeResetBorder
        case .resetText: .extremeResetText
        case .snake: .clear
        case .fruit: .extremeFruit
        case .shadowSnake: .extremeShadowSnake
        case .regularFruit: .extremeRegularFruit
        }
    }
}

enum FruitDirection {
    case up, down, left, right

    static var random: FruitDirection {
        let directions: [FruitDirection] = [.up, .down, .left, .right]
        guard let randomElement = directions.randomElement() else { return .right}
        return randomElement
    }
}

enum SnakeDirection: String {
    case up, down, left, right

    func oppositeDirection() -> SnakeDirection {
        switch self {
        case .up: .down
        case .down: .up
        case .left: .right
        case .right: .left
        }
    }

    static var random: SnakeDirection {
        let directions: [SnakeDirection] = [.up, .down, .left, .right]
        guard let randomElement = directions.randomElement() else { return .right}
        return randomElement
    }
}

enum ScreenSide {
    case top, bottom, left, right

    static var random: ScreenSide {
        let sides: [ScreenSide] = [.top, .bottom]
        guard let randomElement = sides.randomElement() else { return .right}
        return randomElement
    }
}

enum TopPlayers: String {
    case name, score, time, stage
}


