//
//  CGSize+Aspect.swift
//  MachineLearningClassifier
//
//  Created by Nicky Taylor on 2/21/23.
//

import Foundation

extension CGSize {
    func getAspectFill(_ size: CGSize) -> CGSize {
        var result = CGSize(width: width, height: height)
        if width > 1.0 && height > 1.0 && size.width > 1.0 && size.height > 1.0 {
            if (size.width / size.height) < (width / height) {
                result.width = width
                result.height = (width / size.width) * size.height
            } else {
                result.width = (height / size.height) * size.width
                result.height = height
            }
        }
        return result
    }
}
