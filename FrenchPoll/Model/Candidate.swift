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
    
    var data : [Date: Int]
    
    init(name: String, color: String) {
        self.name = name
        self.color = color
        self.data = [:]
    }
}
