//
//  Candidate.swift
//  FrenchPoll
//
//  Created by Benoit PASQUIER on 06/02/2017.
//  Copyright © 2017 Benoit PASQUIER. All rights reserved.
//

import Foundation

struct Candidate {
    
    var name : String
    var color : String
    
    var data : [Score]
    
    init(name: String, color: String) {
        self.name = name
        self.color = color
        self.data = []
    }
    
    // if > 0, candidate did better
    // if < 0, candidate did worst
    func compareLatestValues() -> Int {
        
        if data.count >= 2 {
            return data[0].value - data[1].value
        }
        
        return 0
    }
    
    func getImageName() -> String {
        
        // replace space by dash, then split in array
        let names = self.name.replacingOccurrences(of: " ", with: "-").lowercased().components(separatedBy: "-")
        
        var finalImageNameString = ""
        for tmpName in names {
            finalImageNameString.append(tmpName[tmpName.startIndex])
        }
        return finalImageNameString
    }
    
    func getCurrentScore() -> String {
        
        if data.count > 0 {
            return String(data[0].value) + "%"
        }
        
        return ""
    }
    
    func getLatestUpdate() -> Date? {
        if data.count > 0 {
            return data[0].date
        }
        
        return nil
    }
}
