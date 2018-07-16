//
//  ViewController.swift
//  DemoApp
//
//  Created by Michael Knoch on 16.07.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
        
        label.text = "Hello World"
        label.sizeToFit()

        view.addSubview(label)
    }

    override func viewDidLayoutSubviews() {
        label.center = view.center
    }
}

