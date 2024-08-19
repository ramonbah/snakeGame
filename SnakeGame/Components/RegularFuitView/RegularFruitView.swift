//
//  RegularFruitView.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/29/24.
//

import UIKit
import Combine

@MainActor
class RegularFruitView: UIView {
    private lazy var fruitImage: UIImageView = {
        let view = UIImageView()
        view.image = gameStage.getFruitRandomImage()
        return view
    }()
    private let fruitSize: FruitBombSize = gameStage.isCurrentStageExclusive(.hard) ? FruitBombSize.random: .regular
    private let viewModel = RegularFruitViewModel()
    lazy var cancellables = Set<AnyCancellable>()

    var fruitWillBeEatenHandler: (() -> Void)?
    var fruitEatenHandler: ((Int) -> Void)?

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
    }

    private func setup() {
        setupBindings()
        frame.origin = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midX)
        frame.size = CGSize(width: fruitSize.getValue(), height: fruitSize.getValue())
        fruitImage.frame = CGRect(origin: .zero, size: frame.size)
        layer.cornerRadius = fruitSize.getValue() / 2
        clipsToBounds = true

        addSubview(fruitImage)

        setupActions()
    }

    func getTimeInterval() -> (CFTimeInterval,TimeInterval,(CFTimeInterval)->Void) {
        (viewModel.lastUpdateTime,viewModel.timeIntervalForMovement,{ lastUpdateTime in
            self.moveFruit()
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
        }
    }

    func getCurrentFrame() -> CGRect {
        guard let currentFrame = viewModel.currentFrame else { return .zero }
        return currentFrame
    }

    func moveFruit() {
        if viewModel.state == .playing {
            guard let superview else { return }
            var newFruitPosition: CGPoint
            repeat {
                let x = CGFloat.random(in: superview.bounds.minX..<superview.bounds.maxX - self.fruitSize.getValue()).rounded(.down)
                let y = CGFloat.random(in: superview.bounds.minY..<superview.bounds.maxY - self.fruitSize.getValue()).rounded(.down)
                newFruitPosition = CGPoint(x: x, y: y)
            } while self.isNewPointInsideStage(newFruitPosition) && self.isNewPointOutsideStageViews(CGRect(origin: newFruitPosition, size: self.frame.size))

            self.frame.origin = newFruitPosition
        }
    }

    private func isNewPointOutsideStageViews(_ newFrame: CGRect) -> Bool {
        guard let superview, let _ = superview.subviews.first(where: {$0.frame.intersects(newFrame)}) else { return true }
        return false
    }

    private func isNewPointInsideStage(_ newPoint: CGPoint) -> Bool {
        guard superview?.frame.contains(newPoint) == true else { return false }
        return true
    }

    private func setupActions() {
        fruitWillBeEatenHandler = { [weak self] in
            guard let self, let fruitEatenHandler else { return }
            fruitEatenHandler(fruitSize.getPoints())
            Impact.light.fire()
        }
    }

    func updateState(_ gameState: GameStatus) {
        viewModel.state = gameState
    }

    func removeFruit() {
        removeFromSuperview()
    }
}

