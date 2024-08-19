//
//  Extensions.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/26/24.
//

import Foundation
import UIKit

extension UILabel {
    func setCustomFont(for size: CGFloat) {
        guard let customFont = UIFont(name: "Wake-Snake", size: size) else { return }
        self.font = customFont
    }
}
