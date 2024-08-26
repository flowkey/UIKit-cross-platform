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
        buttonForAlert.addTarget(self, action: #selector(objc_presentAlertController), for: .touchUpInside)
        buttonForActions.addTarget(self, action: #selector(objc_presentActionsController), for: .touchUpInside)
        #else
        buttonForAlert.onPress = { self.presentAlertController() }
        buttonForActions.onPress = { self.presentActionsController() }
        #endif

        view.backgroundColor = UIColor(red: 0 / 255, green: 206 / 255, blue: 201 / 255, alpha: 1)
        view.addSubview(label)
        view.addSubview(buttonForAlert)
        view.addSubview(buttonForActions)
    }

    func presentAlertController() {
        let alertController = UIAlertController(title: "Alert Message", message: alertMessage, preferredStyle: .alert)
        #if os(iOS)
        alertController.popoverPresentationController?.sourceView = buttonForAlert
        #endif
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    func presentActionsController() {
        let actionsController = UIAlertController(title: "Actions", message: nil, preferredStyle: .actionSheet)
        #if os(iOS)
        actionsController.popoverPresentationController?.sourceView = buttonForActions
        #endif
        actionsController.addAction(UIAlertAction(title: "First Action", style: .default, handler: nil))
        actionsController.addAction(UIAlertAction(title: "Second Action", style: .destructive, handler: nil))
        actionsController.addAction(UIAlertAction(title: "Third Action", style: .cancel, handler: nil))
        self.present(actionsController, animated: true, completion: nil)
    }

    #if os(iOS)
    @objc func objc_presentAlertController() {
        presentAlertController()
    }

    @objc func objc_presentActionsController() {
        presentActionsController()
    }
    #endif
}

private let alertMessage = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum."
