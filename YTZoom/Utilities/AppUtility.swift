//
//  AppUtility.swift
//  YoutubeMagicDrag
//
//  Created by Aleix Baggerman on 11/02/2018.
//  Copyright © 2018 Aleix Baggerman. All rights reserved.
//

import UIKit

struct AppUtility {
    static func lockOrientation (_ orientation: UIInterfaceOrientationMask) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
}
