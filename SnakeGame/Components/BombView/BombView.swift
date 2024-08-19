//
//  BombView.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/29/24.
//

import UIKit
import Combine

@MainActor
class BombView: UIView {
    private lazy var warningView = UIView()
    private lazy var bombImageLabel: UILabel = {
        let view = UILabel()
        view.text = "💣"
        return view
    }()
    private let bombSize: FruitBombSize = gameStage == .extreme ? .random: .regular
    private let bombTimeLabel = UILabel()
    private let viewModel = BombViewModel()
    lazy var cancellables = Set<AnyCancellable>()

    var bombDetonatedByTimerHandler: (() -> Void)?
    var bombWillBeDetonatedByShadowHandler: (() -> Void)?
    var bombWillBeDetonatedBySnakeHandler: ((CGRect) -> Bool)?
    var bombDetonatedBySnakeHandler: ((BombView) -> Void)?

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
            }
            .store(in: &cancellables)
        viewModel.$bombTimerValue
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bombTimerValue in
                guard let self else { return }
                bombTimerUpdate(bombTimerValue)
            }
            .store(in: &cancellables)
    }

    func startBlinking() {
        UIView.animate(withDuration: 0.5, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.warningView.alpha = 0
            self.warningView.frame = CGRect(origin: CGPoint(x: (self.frame.size.width / 2), y: (self.frame.size.width / 2)), size: .zero)
            self.warningView.layer.cornerRadius = .zero

        }, completion: nil)
    }

    private func setup() {
        setupBindings()
        frame.origin = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midX)
        frame.size = CGSize(width: bombSize.getValue() * 1.5, height: bombSize.getValue() * 1.5)
        viewModel.bombTimerValue = gameStage == .extreme ? viewModel.bombTimerValue + bombSize.getAdditionalTime(): viewModel.bombTimerValue
        bombTimeLabel.text = String(viewModel.bombTimerValue)
        bombTimeLabel.textColor = .white
        bombTimeLabel.setCustomFont(for: bombSize.getValue() * 0.5)
        bombTimeLabel.sizeToFit()
        bombTimeLabel.frame = CGRect(origin: .zero, size: frame.size)
        bombTimeLabel.textAlignment = .center

        bombImageLabel.textAlignment = .center
        bombImageLabel.setCustomFont(for: bombSize.getValue() * 0.8)
        bombImageLabel.sizeToFit()
        bombImageLabel.frame = CGRect(origin: .zero, size: frame.size)
        bombImageLabel.clipsToBounds = false

        warningView.frame = CGRect(origin: CGPoint(x: -(frame.size.width / 2), y: -(frame.size.width / 2)), size: CGSize(width: frame.size.width * 2, height: frame.size.width * 2))
        warningView.layer.cornerRadius = warningView.frame.size.width / 2
        warningView.clipsToBounds = true
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = warningView.bounds
        gradientLayer.colors = [UIColor.red.cgColor, ColorSet.stage.color().cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.type = .radial
        warningView.layer.addSublayer(gradientLayer)

        startBlinking()

        clipsToBounds = false

        addSubview(warningView)
        addSubview(bombImageLabel)
        addSubview(bombTimeLabel)

        setupActions()
    }

    func getTimeInterval() -> (CFTimeInterval,TimeInterval,(CFTimeInterval)->Void) {
        (viewModel.lastUpdateTime,viewModel.timeIntervalForTimer,{ lastUpdateTime in
            self.bombTimerAction()
            self.viewModel.lastUpdateTime = lastUpdateTime
        })
    }

    func getUpdateFrame() -> (CFTimeInterval,TimeInterval,(CFTimeInterval)->Void) {
        (viewModel.lastUpdateTimeForFrame,.zero,{ lastUpdateTime in
            self.updateFrame()
            self.viewModel.lastUpdateTimeForFrame = lastUpdateTime
        })
    }

    func updateFrame() {
        if let presentationLayer = layer.presentation() {
            viewModel.currentFrame = presentationLayer.frame
            guard let bombWillBeDetonatedBySnakeHandler else { return }
            if bombWillBeDetonatedBySnakeHandler(presentationLayer.frame) {
                bombDetonatedBySnake(presentationLayer.frame)
            }
        }
    }

    private func bombDetonatedBySnake(_ bombFrame: CGRect) {
        guard let bombDetonatedBySnakeHandler else { return }
        bombDetonatedBySnakeHandler(self)
    }

    func getCurrentFrame() -> CGRect{
        guard let currentFrame = viewModel.currentFrame else { return .zero }
        return currentFrame
    }

    private func setupActions() {

    }

    func bombTimerAction() {
        if viewModel.state == .playing {
            viewModel.bombTimerValue = viewModel.bombTimerValue - 1
        }
    }

    private func bombTimerUpdate(_ value:Int) {
        guard value == 0 else {
            bombTimeLabel.text = String(value)
            return
        }

        removeBomb()
        guard let bombDetonated = bombDetonatedByTimerHandler else { return }
        
        switch bombSize {
        case .regular: Impact.light.fire()
        case .medium: Impact.medium.fire()
        case .large: Impact.heavy.fire()
        }
        bombDetonated()
    }

    func setCenterInsideStageForAnimation(_ point: CGPoint) {
        repeat {
            center = randomPointOutsideScreen()
        } while distanceBetweenPoints(center, point) < screenWidth / 2
        viewModel.centerInsideStageForAnimation = point
    }

    func curvedPath(from startPoint: CGPoint, to endPoint: CGPoint) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: startPoint)

        let controlPoint1 = CGPoint(x: startPoint.x + (endPoint.x - startPoint.x) / 3, y: startPoint.y - 100)
        let controlPoint2 = CGPoint(x: startPoint.x + 2 * (endPoint.x - startPoint.x) / 3, y: startPoint.y - 100)

        path.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        return path
    }

    func throwBomb() {
        guard let centerInsideStageForAnimation = viewModel.centerInsideStageForAnimation else { return }

        let path = curvedPath(from: center, to: centerInsideStageForAnimation)

        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.path = path.cgPath
        animation.duration = distanceBetweenPoints(center, centerInsideStageForAnimation) / 100
        animation.autoreverses = true
        animation.repeatCount = .infinity

        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = distanceBetweenPoints(center, centerInsideStageForAnimation) / 100 / 2
        rotation.repeatCount = .infinity

        layer.add(animation, forKey: "curvedAnimation")
        layer.add(rotation, forKey: "rotationAnimation")
    }

    private func distanceBetweenPoints(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx*dx + dy*dy)
    }

    func randomPointOutsideScreen() -> CGPoint {
        let randomSide = ScreenSide.random

        switch randomSide {
        case .top:
            return CGPoint(x: CGFloat.random(in: 0...screenWidth), y: -(bombSize.getValue()))
        case .bottom:
            return CGPoint(x: CGFloat.random(in: 0...screenWidth), y: screenWidth + (bombSize.getValue()))
        case .left: return .zero
        case .right: return .zero
        }
    }

    func updateState(_ gameState: GameStatus) {
        viewModel.state = gameState
    }

    func removeBomb() {
        removeFromSuperview()
    }
}
