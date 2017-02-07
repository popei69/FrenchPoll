//
//  ViewController.swift
//  FrenchPoll
//
//  Created by Benoit PASQUIER on 06/02/2017.
//  Copyright © 2017 Benoit PASQUIER. All rights reserved.
//

import UIKit
import Foundation

import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // static api to consume
    static let url = "https://9sl1b17sd8.execute-api.us-east-1.amazonaws.com/dev/polls"
    
    var candidates : [Candidate] = []
    
    var dateFormatter = DateFormatter()
    var parseDateformatter = DateFormatter()

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        parseDateformatter.dateFormat = "YYYY-MM-dd"
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        self.pollData()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reloadData() {
        // got new data, sort and reload ui
        candidates.sort {
            $0.data.values.first! > $1.data.values.first!
        }
        
        print(candidates)
        
        tableView.reloadData()
    }

    func pollData() {
        
        Alamofire.request(ViewController.url).responseJSON { (response) in
            // print(response.request)  // original URL request
            // print(response.response) // HTTP URL response
            // print(response.data)     // server data
            // print(response.result)   // result of response serialization
            
            if let tmpJson = response.result.value {
                let swiftyJson = JSON(tmpJson)
                // print("JSON: \(swiftyJson)")
                
                // serialise data
                for (_, tmpCandidateJson) : (String, JSON) in swiftyJson["data"] {
                    
                    if let name = tmpCandidateJson["name"].string,
                        let color = tmpCandidateJson["color"].string {
                        
                        var tmpCandidate = Candidate(name: name, color: color)
                        
                        // data is an array of array
                        // get date + value
                        if let tmpData = tmpCandidateJson["data"].arrayObject as? [[String]]  {
                            
                            for currentData in tmpData {
                                
                                if let currentDate = self.parseDateformatter.date(from: currentData[0]) {
                                    
                                    tmpCandidate.data[currentDate] = Int(currentData[1])
                                }
                            }
                        }
                        
                        self.candidates.append(tmpCandidate)
                    }
                }
            }
            
            
            self.reloadData()
        }
    }
    
    // MARK: UITableViewDelegate + UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return candidates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CandidateCell", for: indexPath) as! CandidateCell
        
        let candidate = candidates[indexPath.row]
        
        cell.candidateNameLabel.text = candidate.name
        cell.positionLabel.text = String(indexPath.row + 1)
        cell.scoreLabel.text = String(candidate.data.values.first!) + "%"
        
        let imageNameString = candidate.name.replacingOccurrences(of: " ", with: "-").lowercased()
        cell.candidateImageView.image = UIImage(named: imageNameString)
        cell.candidateImageView.layer.cornerRadius = cell.candidateImageView.frame.size.width / 2
        cell.candidateImageView.layer.masksToBounds = true
        
        return cell
    }

}

