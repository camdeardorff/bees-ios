//
//  BeesCommunicator.swift
//  bees-ios
//
//  Created by Cameron Deardorff on 12/21/16.
//  Copyright © 2016 Cameron Deardorff. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class BeesCommunicator {
    
    
    
    func getTodaysRecords(inTimeZone: String, completion: @escaping (BeesError?, [BeesRecord]?) -> Void) {
        print("CD: get todays records with time zone: ", inTimeZone)
        
        getData(tz: inTimeZone) { [weak self] (data) in
            if let strongSelf = self {
                guard let d = data else {
                    completion(nil, nil)
                    return
                }
                let result = strongSelf.decodeMessage(d)
                completion(result.error, result.records)
            } else {
                completion(nil, nil)
            }
        }
    }
    
    
    private func getData(tz: String, completion: @escaping (Data?) -> Void) {
        print("CD: get data")
        
        let SLASH = "*=SLASH=*"
        let timeZone = tz.replacingOccurrences(of: "/", with: SLASH)
        
        Alamofire.request("https://cafbees.herokuapp.com/report/today/" + timeZone)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                
                guard response.result.isSuccess else {
                    print("Error while fetching remote rooms: \(response.result.error)")
                    completion(nil)
                    return
                }
                
                completion(response.data)
        }
    }
    
    private func decodeMessage(_ data: Data) -> (error: BeesError?, records: [BeesRecord]?) {
        print("CD: decode message")
        
        let json = JSON(data: data)
        guard let success = json["success"].bool else { return (nil, nil) }
        
        if success {
            var records = [BeesRecord]()
            // get some records
            guard let jsonRecords = json["records"].array else { return (nil, nil) }
            
            for jsonRecord in jsonRecords {
                // put the json records into BeesRecord form
                guard let loudness = jsonRecord["loudness"].double,
                    let to = jsonRecord["range"]["to"].string,
                    let from = jsonRecord["range"]["from"].string else { return (nil, nil)  }
                let range = BeesRange(from: from, to: to)
                let record = BeesRecord(loudness: loudness, range: range)
                records.append(record)
            }
            return (nil, records)
        } else {
            // find out why it was unsuccessful
            guard let errorMessage = json["error"]["message"].string,
                let errorCode = json["error"]["code"].string else { return (nil, nil) }
            return (BeesError(message: errorMessage, code: errorCode), nil)
        }
    }
}
