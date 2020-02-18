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

//        label.text = "Hello World"
//        label.font = .systemFont(ofSize: 30)
//        label.sizeToFit()
//        label.center = view.center
//        scrollView.addSubview(label)

        let colors: [UIColor] = [.green, .orange, .red]
        var views = [UIView]()

        for (i, color) in colors.enumerated() {
            let view = UIView(frame: CGRect(origin: CGPoint(x: 220+20*i, y: 10+20*i), size: CGSize(width: 100, height: 100)))
            view.backgroundColor = color
            views.append(view)
            scrollView.addSubview(view)
        }


        let blackView = UIView(frame: CGRect(origin: CGPoint(x: 225+20*2 - 50, y: 15+20*2), size: CGSize(width: 150, height: 10)))
        blackView.backgroundColor = .blue

        scrollView.insertSubview(blackView, at: 6)
        print(scrollView.subviews.index(of: blackView) ?? -1)


        view.backgroundColor = UIColor(red: 0 / 255, green: 206 / 255, blue: 201 / 255, alpha: 1)


        view.addSubview(scrollView)

        print(scrollView.subviews.count, " count")
    }

}

