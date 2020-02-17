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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let scrollView = UIScrollView(frame: CGRect(x: 200, y: 100, width: 300, height: 150))
        scrollView.contentSize = CGSize(width: 600, height: 300)
        scrollView.backgroundColor = .white
//        scrollView.showsVerticalScrollIndicator = false
//        scrollView.showsHorizontalScrollIndicator = false

        label.text = "Hello World"
        label.font = .systemFont(ofSize: 30)
        label.sizeToFit()
        label.center = view.center

        view.backgroundColor = UIColor(red: 0 / 255, green: 206 / 255, blue: 201 / 255, alpha: 1)
        scrollView.addSubview(label)
        view.addSubview(scrollView)

        print(scrollView.subviews)
    }
}

