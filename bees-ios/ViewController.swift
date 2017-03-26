//
//  ViewController.swift
//  bees-ios
//
//  Created by Cameron Deardorff on 10/4/16.
//  Copyright © 2016 Cameron Deardorff. All rights reserved.
//

import UIKit
import Charts
import FLAnimatedImage

class ViewController: UIViewController {
    
    // ui references
    @IBOutlet var loadingImage: FLAnimatedImageView?
    @IBOutlet var lineChartView: LineChartView?
    @IBOutlet var refreshButton: UIBarButtonItem?
    
    
    var beesCommunicator: BeesCommunicator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLineChart()
        
        // get the gif if it exists
        if let gif = getLoadingGif() {
            loadingImage?.animatedImage = gif
            showLoadingAnimation()
        }
        
        // get the data and display it
        self.reloadChart(completion: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.hideLoadingAnimation()
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("view did appear")
    }
    override func viewWillAppear(_ animated: Bool) {
        print("view will appear")
    }
    override func viewDidDisappear(_ animated: Bool) {
        print("view did disappear")
    }
    
    //MARK: UI modifiers
    
    private func showLoadingAnimation() {
        loadingImage?.layer.zPosition = 10
        loadingImage?.startAnimating()
    }
    
    private func hideLoadingAnimation() {
        loadingImage?.layer.zPosition = -10
        loadingImage?.stopAnimating()
    }
    
    private func showErrorMessage() {
        lineChartView?.noDataText = "No chart data available."
        lineChartView?.notifyDataSetChanged()
    }
    
    // function called on refresh button press. updates the chart
    @IBAction func refreshButtonWasPressed(_ sender: AnyObject) {
        showLoadingAnimation()
        self.reloadChart(completion: { [weak self] in
            if let strongSelf = self {
                strongSelf.hideLoadingAnimation()
            }
        })
    }
    
    
    //MARK: chart functions
    // configures the chart before the data is displayed
    private func configureLineChart() {
        
        let noDescription = Description()
        noDescription.text = nil
        lineChartView?.noDataText = ""
        lineChartView?.chartDescription = noDescription
        
        lineChartView?.xAxis.labelPosition = .bottom
        lineChartView?.xAxis.labelTextColor = .black
        lineChartView?.viewPortHandler.setMaximumScaleX(3)
        lineChartView?.rightAxis.enabled = false
        lineChartView?.animate(yAxisDuration: 2.0, easingOption: .easeInOutCubic)
    }
    
    // transforms BeesRecords into data points appropriate for the charts and displays them
    func displayData(records: [BeesRecord]) {
        
        // turn the records into a series of points
        let points : [ChartDataEntry] = records.enumerated().map { (index, record) in
            ChartDataEntry(x: Double(index), y: record.loudness)
        }
        // configure this dataset
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
        loudnessDataSet.label = "MVNU Cafeteria Loudness in Decibels, Today"
        loudnessDataSet.drawFilledEnabled = true
        
        
        //set the dataset to the chart
        let lineChartData = LineChartData(dataSet: loudnessDataSet)
        
        lineChartData.setValueTextColor(.clear)
        lineChartView?.data = lineChartData
        lineChartView?.xAxis.valueFormatter = AxisFormatter(records: records)
        
    }
    
   
    //MARK: resource loading
    // gets the gif from the bundle and returns it
    private func getLoadingGif() -> FLAnimatedImage? {
        if let path =  Bundle.main.path(forResource: "jumpy", ofType: "gif") {
            if let data = NSData(contentsOfFile: path) {
                return FLAnimatedImage(animatedGIFData: data as Data!)
            }
        }
        return nil
    }
    
    /**
     # Reload Chart
     asynchronously leverages the BeesCommunicator class object to get data for the chart. The data is then sent to the appropriate functions to display the chart
     - Parameter completion: a closure to mark the end of the asynchrous task.
     */
    func reloadChart(completion: @escaping () -> Void) {
        var localTimeZoneName: String { return (NSTimeZone.local as NSTimeZone).name }
        
        if (beesCommunicator == nil) {
            beesCommunicator = BeesCommunicator()
        }
        
        guard let bc = beesCommunicator else {
            completion()
            return
        }
        
        bc.getTodaysRecords(inTimeZone: localTimeZoneName) { [weak self] (error, records) in
            // make sure that the reference is still good
            guard let strongSelf = self else {
                completion()
                return
            }
            // use the information given
            if error == nil && records == nil {
                print("there was a problem decoding the message")
                strongSelf.showErrorMessage()
            } else {
                if let recs = records {
//                    print(recs)
                    strongSelf.displayData(records: recs)
                } else {
                    if let err = error {
                        print(err)
                        strongSelf.showErrorMessage()
                    }
                }
            }
            // all done
            completion()
        }
    }
}

// axis formatter for the chart: takes the BeesRecords and formats them into axis value tics
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
