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


        let scrollView1 = UITouchyView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/2))
//        scrollView1.contentSize = CGSize(width: UIScreen.main.bounds.width*2, height: UIScreen.main.bounds.height*2)
        scrollView1.backgroundColor = .green

        let scrollView2 = UITouchyView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height/2, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/2))
//        scrollView2.contentSize = CGSize(width: UIScreen.main.bounds.width*2, height: UIScreen.main.bounds.height*2)
        scrollView2.backgroundColor = .red

        view.addSubview(scrollView2)
        view.addSubview(scrollView1)
    }
}


class UITouchyView: UIView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
//        let a = UIEvent.activeEvents.count
        print("Touches began with event that has \(event!.allTouches!.count) touches: (\(event!)")
//        print("event type is touches  \(event!.type == .touches) subtype none \(event!.subtype == .none)")

    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
//        print("Touches moved with evenv that has \(event!.allTouches!.count) touches (\(event!) ")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        print("Touches ENDED with event (\(event!)")
    }
}
