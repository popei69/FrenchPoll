//
//  AppHelper.swift
//  FrenchPoll
//
//  Created by Benoit PASQUIER on 11/02/2017.
//  Copyright © 2017 Benoit PASQUIER. All rights reserved.
//

import UIKit
import Foundation

struct AppHelper {
    
    // static api to consume
    static let url = "https://9sl1b17sd8.execute-api.us-east-1.amazonaws.com/dev/polls"
    static let storeUrl = "itms://itunes.apple.com/us/app/apple-store/id1206141960?mt=8"
    
    // green colour #3EDE59
    static let greenColour = UIColor(red: 62/255, green: 222/255, blue: 89/255, alpha: 1.0)
    
    // red colour #FF6260
    static let redColour = UIColor(red: 255/255, green: 98/255, blue: 96/255, alpha: 1.0)
    
    static func savePollData(jsonString: String?) {
        
        let standard = UserDefaults.standard
        standard.set(jsonString, forKey: "data")
        standard.synchronize()
    }

    
    static func fetchSavedData() -> String? {
        return UserDefaults.standard.object(forKey: "data") as? String
    }
}
