//
//  ViewController.swift
//  bees-ios
//
//  Created by Cameron Deardorff on 10/4/16.
//  Copyright © 2016 Cameron Deardorff. All rights reserved.
//

import UIKit
import Charts
import SwiftGifOrigin

class ViewController: UIViewController {
    
    @IBOutlet var loadingImage: UIImageView!
    @IBOutlet var lineChartView: LineChartView!
    @IBOutlet var refreshButton: UIBarButtonItem!
    
    var beesCommunicator = BeesCommunicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let img = UIImage.gif(name: "jumpy")
        loadingImage.image = img
        
        showLoadingAnimation()
        configureLineChart()
        reloadChart(completion: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.hideLoadingAnimation()
            })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func refreshButtonWasPressed(_ sender: AnyObject) {
        showLoadingAnimation()
        reloadChart(completion: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.hideLoadingAnimation()
            })
    }
    
    func reloadChart(completion: @escaping () -> Void) {
        var localTimeZoneName: String { return (NSTimeZone.local as NSTimeZone).name }
        beesCommunicator.getTodaysRecords(inTimeZone: localTimeZoneName) { [weak self] (error, records) in
            // make sure that the reference is still good
            guard let strongSelf = self else {
                completion()
                return
            }            
            // use the information given
            if error == nil && records == nil {
                print("there was a problem decoding the message")
            } else {
                if let recs = records {
                    print(recs)
                    strongSelf.displayData(records: recs)
                } else {
                    if let err = error {
                        print(err)
                    }
                }
            }
            // all done
            completion()
        }
    }
    
    
    func showLoadingAnimation() {
        loadingImage.layer.zPosition = 10
    }
    
    func hideLoadingAnimation() {
        loadingImage.layer.zPosition = -10
    }
    
    
    func configureLineChart() {
//        lineChartView.gridBackgroundColor = .black
//        lineChartView.backgroundColor = .white
        
        let noDescription = Description()
        noDescription.text = nil
        
        lineChartView.chartDescription = noDescription
        
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.labelTextColor = .black
        lineChartView.rightAxis.enabled = false
        lineChartView.animate(yAxisDuration: 2.0, easingOption: .easeInOutCubic)
    }
    
    func displayData(records: [BeesRecord]) {
        
        var points = [ChartDataEntry]()
        for i in 0..<records.count {
            let point = ChartDataEntry(x: Double(i), y: records[i].loudness)
            
            points.append(point)
        }
        
        
        let loudnessDataSet = LineChartDataSet(values: points, label: nil)
        loudnessDataSet.circleColors = [BEES_GREY]
        loudnessDataSet.mode = .cubicBezier
        loudnessDataSet.circleHoleColor = BEES_BLUE.withAlphaComponent(0.9)
        loudnessDataSet.circleRadius = 4
        loudnessDataSet.circleHoleRadius = 3
        loudnessDataSet.setColor(BEES_GREY)
        loudnessDataSet.lineWidth = 2
        loudnessDataSet.fillColor = BEES_BLUE
        loudnessDataSet.fillAlpha = 1
        loudnessDataSet.valueTextColor = BEES_BLUE
        loudnessDataSet.label = "MVNU Cafeteria Loudness Today"
        loudnessDataSet.drawFilledEnabled = true
        
        let lineChartData = LineChartData(dataSet: loudnessDataSet)
        
        lineChartData.setValueTextColor(.clear)
        lineChartView.data = lineChartData
        lineChartView.xAxis.valueFormatter = AxisFormatter(records: records)
        
    }
    
    
}


class AxisFormatter: NSObject, IAxisValueFormatter {
    
    var records: [BeesRecord]
    
    init(records: [BeesRecord]) {
        self.records = records
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if value.truncatingRemainder(dividingBy: 1.0) == 0 {
            return self.records[Int(value)].range.from
        } else {
            return ""
        }
    }
}


struct BeesRecord {
    var loudness: Double
    var range: BeesRange
}

struct BeesRange {
    var from: String
    var to: String
}

struct BeesError {
    var message: String
    var code: String
}
