//
//  BubbleViewFactory.swift
//  AID
//
//  Created by Alexandr Sokolov on 23.03.2024.
//

import Foundation
import UIKit

final class BubbleViewFactory {

    // Создание кругов для каждой компании
    static func make(
        companies: [String],
        bubbleDidTap: @escaping (String) -> Void
    ) -> [BubbleView] {
        companies.map {
            BubbleView(companyName: $0, bubbleDidTap: bubbleDidTap)
        }
    }
}
