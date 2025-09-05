//
//  MeteringView.swift
//  UIKit
//
//  Created by Geordie Jay on 10.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

class MeteringView: UILabel {
    convenience init(metric: String) {
        self.init(frame: .zero)
        self.metric = metric
        backgroundColor = UIColor(hex: 0x555555, alpha: 0.75)
        textAlignment = .right
        font = .boldSystemFont(ofSize: 20)
        textColor = .red
        updateDisplay(to: 0)
    }

    var metric: String = ""
    var measurementsToAverage = 15
    private var measurementsCount = 0
    private var measurementsTotal: Double = 0

    func addMeasurement(_ measurement: Double) {
        measurementsTotal += measurement
        measurementsCount += 1
        if measurementsCount >= measurementsToAverage {
            let averageValue = measurementsTotal / Double(measurementsCount)
            updateDisplay(to: averageValue)
            measurementsTotal = 0
            measurementsCount = 0
        }
    }

    private func updateDisplay(to value: Double) {
        guard value.isFinite else { return }
        let value = Int(value.rounded())
        self.text = metric + ": \(value)"
        self.sizeToFit()
    }
}
