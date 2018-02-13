//
//  Constants.swift
//  YoutubeMagicDrag
//
//  Created by Aleix Baggerman on 05/02/2018.
//  Copyright © 2018 Aleix Baggerman. All rights reserved.
//

import UIKit

struct Constants {
    
    /// The ratio of the top view container. By default is 16/9.
    var videoRatio:CGFloat = 16/9
    
    /// The velocity of the drag. Min value 0. By default 0.9.
    var dragVelocity: CGFloat = 1 {
        didSet {
            dragVelocity = dragVelocity < 0 ? 0 : dragVelocity
        }
    }
    
    /// Top margin. By default is the height of the status bar frame.
    var topMargin = UIApplication.shared.statusBarFrame.height
    
    /// Final scale value for the top view container. Values between 0 and 1. By default 0.4.
    var finalScaleFactor: CGFloat = 1 {
        didSet {
            finalScaleFactor = finalScaleFactor < 0 ? 0 : finalScaleFactor
            finalScaleFactor = finalScaleFactor > 1 ? 1 : finalScaleFactor
        }
    }
    
    /// Final alpha value for the bottom view container. Values between 0 and 1. By default 0.0 .
    var finalAlphaFactor: CGFloat = 0.0
    
    /// Duration of all the animations of the views. By default is 0.3.
    var animationDuration = 0.3
    
    /// Velocity needed to launch the translation animation. By default is 2000.
    var launchVelocityNeeded:CGFloat                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                = 2000
    /// Bottom margin of the top view container on its final position. Min value: 0. Max value: 100. By default is 10.
    var bottomMargin: CGFloat = 10 {
        didSet {
            bottomMargin = bottomMargin < 0 ? 0: bottomMargin
            bottomMargin = bottomMargin > 100 ? 100 : bottomMargin
        }
    }
}
