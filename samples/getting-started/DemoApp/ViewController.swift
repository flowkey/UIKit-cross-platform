//
//  ViewController.swift
//  DemoApp
//
//  Created by Michael Knoch on 16.07.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import UIKit

#if os(iOS)
typealias Button = UIButton
#endif

class ViewController: UIViewController {

    let childView = UIView()

    convenience init() {
        self.init(nibName: nil, bundle: nil)

        self.view.addSubview(childView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.view.bounds.origin.x -= 400

        childView.backgroundColor = .red
        childView.frame = CGRect(x: 100, y: 100, width: 200, height: 200)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(touches.first?.location(in: self.view))
    }
}
