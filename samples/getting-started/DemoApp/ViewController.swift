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
    let buttonForAlert = Button()
    let buttonForAction = Button()
    
    let alertController = UIAlertController(title: "Alert Message", message: alertMessageShortest, preferredStyle: .alert)
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
        buttonForAlert.frame.midX = view.frame.midX
        buttonForAlert.frame.minY = label.frame.maxY + 10
        buttonForAlert.onPress = {
            self.present(self.alertController, animated: true, completion: {})
        }
        
        buttonForAction.setTitle("Show Actions", for: .normal)
        buttonForAction.titleLabel?.font = .systemFont(ofSize: 20)
        buttonForAction.sizeToFit()
        buttonForAction.frame.midX = view.frame.midX
        buttonForAction.frame.minY = buttonForAlert.frame.maxY
        buttonForAction.onPress = {
            self.present(self.actionsController, animated: true, completion: nil)
        }
        
        actionsController.addAction(UIAlertAction(title: "First Action", style: .default, handler: nil))
        actionsController.addAction(UIAlertAction(title: "Second Action", style: .cancel, handler: nil))
        actionsController.addAction(UIAlertAction(title: "Third Action", style: .destructive, handler: nil))
        
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))

        view.backgroundColor = UIColor(red: 0 / 255, green: 206 / 255, blue: 201 / 255, alpha: 1)
        view.addSubview(label)
        view.addSubview(buttonForAlert)
        view.addSubview(buttonForAction)
    }
}

private let alertMessage = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum."

private let alertMessageShort = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore."

private let alertMessageShortest = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr."
