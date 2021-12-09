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

    let label = UILabel()
    let buttonForAlert = Button()
    let buttonForActions = Button()
    
    let alertController = UIAlertController(title: "Alert Message", message: alertMessage, preferredStyle: .alert)
    let actionsController = UIAlertController(title: "Actions", message: nil, preferredStyle: .actionSheet)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        label.text = "Hello World"
        label.font = .systemFont(ofSize: 30)
        label.sizeToFit()
        label.center = view.center
        
        buttonForAlert.setTitle("Show Alert", for: .normal)
        buttonForAlert.titleLabel?.font = .systemFont(ofSize: 20)
        buttonForAlert.sizeToFit()
        buttonForAlert.center.x = view.frame.midX
        buttonForAlert.center.y = label.frame.maxY + 30

        buttonForActions.setTitle("Show Actions", for: .normal)
        buttonForActions.titleLabel?.font = .systemFont(ofSize: 20)
        buttonForActions.sizeToFit()
        buttonForActions.center.x = view.frame.midX
        buttonForActions.center.y = buttonForAlert.frame.maxY + 10
        
        #if os(iOS)
        buttonForAlert.addTarget(self, action: #selector(presentAlertController), for: .touchDown)
        buttonForActions.addTarget(self, action: #selector(presentActionsController), for: .touchDown)
        #else
        buttonForAlert.onPress = {
            self.present(self.alertController, animated: true, completion: nil)
        }
        buttonForActions.onPress = {
            self.present(self.actionsController, animated: true, completion: nil)
        }
        #endif
        
        actionsController.addAction(UIAlertAction(title: "First Action", style: .default, handler: nil))
        actionsController.addAction(UIAlertAction(title: "Second Action", style: .destructive, handler: nil))
        actionsController.addAction(UIAlertAction(title: "Third Action", style: .cancel, handler: nil))
        
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))

        view.backgroundColor = UIColor(red: 0 / 255, green: 206 / 255, blue: 201 / 255, alpha: 1)
        view.addSubview(label)
        view.addSubview(buttonForAlert)
        view.addSubview(buttonForActions)
    }
    
    #if os(iOS)
    @objc func presentAlertController() {
        self.present(self.alertController, animated: true, completion: nil)
    }
    @objc func presentActionsController() {
        self.present(self.actionsController, animated: true, completion: nil)
    }
    #endif
}

private let alertMessage = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum."
