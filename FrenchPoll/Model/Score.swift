//
//  Score.swift
//  FrenchPoll
//
//  Created by Benoit PASQUIER on 07/02/2017.
//  Copyright © 2017 Benoit PASQUIER. All rights reserved.
//

import Foundation

struct Score {
    
    var date : Date
    var value : Int
    
    init(date: Date, value: Int) {
        self.date = date
        self.value = value
    }
}
