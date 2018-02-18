//
//  UIEvent.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

enum UIEventType: Int {
    case touches
}

public class UIEvent {
    var type: UIEventType = .touches
}
