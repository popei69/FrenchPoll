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

class CandidateListController: UIViewController, UITableViewDelegate, UITableViewDataSource {
        
    var candidates : [Candidate] = []
    
    var dateFormatter = DateFormatter()
    var parseDateformatter = DateFormatter()

    // UI
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    // UI Animation
    var isAnimating = false
    var isFirstRoundDisplay = true
    var secondRoundCandidates : [Candidate] = []
    
    // second round 
    var secondRoundController : SecondRoundViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        titleLabel.text = "Premier tour"
        
        parseDateformatter.dateFormat = "YYYY-MM-dd"
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        
//        self.view.backgroundColor = UIColor.red
        self.tableView.backgroundColor = UIColor.clear
        
//        self.tableView.layer.cornerRadius = 15.0
//        self.tableView.layer.masksToBounds = true
        
        let maskPath = UIBezierPath(roundedRect: self.tableView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10))
        let maskLayer = CAShapeLayer();
        maskLayer.path = maskPath.cgPath
        self.backgroundView.layer.mask = maskLayer;
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.tableView.bounds
        
        let greyColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0) // #F1F1F1
        gradientLayer.colors = [UIColor.white.cgColor, greyColor.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        self.backgroundView.layer.addSublayer(gradientLayer)
        
        self.pollData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func reloadData() {
        // got new data, sort and reload ui
        candidates.sort {
            $0.data.first!.value > $1.data.first!.value
        }
        secondRoundCandidates.sort {
            $0.data.first!.value > $1.data.first!.value
        }
        
        print(candidates)
        
        tableView.reloadData()
        
        // build second round
        secondRoundController = self.storyboard?.instantiateViewController(withIdentifier: "SecondRoundViewController") as? SecondRoundViewController
        
        if let controller = secondRoundController, secondRoundCandidates.count == 2 {
            controller.firstCandidate = secondRoundCandidates[0]
            controller.secondCandidate = secondRoundCandidates[1]
            controller.delegate = self
        }
        
    }

    func pollData() {
        
        Alamofire.request(AppHelper.url).responseJSON { (response) in
            // print(response.request)  // original URL request
            // print(response.response) // HTTP URL response
            // print(response.data)     // server data
            // print(response.result)   // result of response serialization
            
            if let tmpJson = response.result.value {
                let swiftyJson = JSON(tmpJson)
                // print("JSON: \(swiftyJson)")
                
                // serialise data for first round
                for (_, tmpCandidateJson) : (String, JSON) in swiftyJson["data"]["premier_tour"] {
                    
                    if let name = tmpCandidateJson["name"].string,
                        let color = tmpCandidateJson["color"].string {
                        
                        var tmpCandidate = Candidate(name: self.getConvertedName(name: name), color: color)
                        
                        // data is an array of array
                        // get date + value
                        if let tmpData = tmpCandidateJson["data"].arrayObject as? [[String]]  {
                            
                            for currentData in tmpData {
                                
                                if let currentDate = self.parseDateformatter.date(from: currentData[0]),
                                    let currentValue = Int(currentData[1]) {
                                    
                                    let newScore = Score(date: currentDate, value: currentValue)
                                    tmpCandidate.data.append(newScore)
                                }
                            }
                            
                            // sort data by date
                            tmpCandidate.data.sort { $0.date > $1.date }
                        }
                        
                        self.candidates.append(tmpCandidate)
                    }
                }
                
                // serialise data for second round
                for (_, tmpCandidateJson) : (String, JSON) in swiftyJson["data"]["second_tour"] {
                    
                    if let name = tmpCandidateJson["name"].string,
                        let color = tmpCandidateJson["color"].string {
                        
                        var tmpCandidate = Candidate(name: self.getConvertedName(name: name), color: color)
                        
                        // data is an array of array
                        // get date + value
                        if let tmpData = tmpCandidateJson["data"].arrayObject as? [[String]]  {
                            
                            for currentData in tmpData {
                                
                                if let currentDate = self.parseDateformatter.date(from: currentData[0]),
                                    let currentValue = Int(currentData[1]) {
                                    
                                    let newScore = Score(date: currentDate, value: currentValue)
                                    tmpCandidate.data.append(newScore)
                                }
                            }
                            
                            // sort data by date
                            tmpCandidate.data.sort { $0.date > $1.date }
                        }
                        
                        self.secondRoundCandidates.append(tmpCandidate)
                    }
                }
                
            }
            
            
            self.reloadData()
        }
    }
    
    private func getConvertedName(name: String) -> String {
        let convertedString = name.mutableCopy() as! NSMutableString
        CFStringTransform(convertedString, nil, "Any-Hex/Java" as NSString, true)
        return convertedString as String
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
        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.clear
        
        let candidate = candidates[indexPath.row]
        
        cell.candidateNameLabel.text = candidate.name
        cell.positionLabel.text = String(indexPath.row + 1)
        cell.scoreLabel.text = candidate.getCurrentScore()
        
        let scoreEvolution = candidate.compareLatestValues()
        if scoreEvolution > 0 {
            
            cell.scoreImageView.image = UIImage(named: "top-arrow")
            cell.scoreImageView.isHidden = false
            
            cell.scorePositionLabel.text = "+" + String(scoreEvolution)
            cell.scorePositionLabel.textColor = AppHelper.greenColour
            cell.scorePositionLabel.isHidden = false
            
        } else if scoreEvolution < 0 {
            
            cell.scoreImageView.image = UIImage(named: "bottom-arrow")
            cell.scoreImageView.isHidden = false
            
            cell.scorePositionLabel.text = String(scoreEvolution)
            cell.scorePositionLabel.textColor = AppHelper.redColour
            cell.scorePositionLabel.isHidden = false
            
        } else {
            cell.scoreImageView.isHidden = true
            cell.scorePositionLabel.isHidden = true
        }
        
        cell.candidateImageView.image = UIImage(named: candidate.getImageName())
        cell.candidateImageView.layer.cornerRadius = cell.candidateImageView.frame.size.width / 2
        cell.candidateImageView.layer.masksToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40.0))
            
        let label = UILabel()
        label.frame = view.frame
        label.textAlignment = .center
        label.backgroundColor = UIColor.white
        label.layer.cornerRadius = 10.0
        label.layer.masksToBounds = true
        label.textColor = UIColor.lightGray
        label.font = UIFont(name: "Avenir-BookOblique", size: 13.0)
    
        if candidates.count > 0,
            let date = candidates[0].getLatestUpdate() {
            label.text = "Last updated " + dateFormatter.string(from: date)
        } else {
            label.text = ""
        }
        
        view.backgroundColor = UIColor.clear
        view.addSubview(label)
        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
    
    // MARK - Animation
    
    @IBAction func showFirstTurn(_ sender: Any) {
        // will show first turn
        print("show first turn")
        
        if isFirstRoundDisplay || isAnimating { // stop here
            return
        }
        
        self.hideSecondRound()
        UIView.animate(withDuration: 0.3, animations: {
            self.titleLabel.alpha = 0.0
        }) { success in
            
            self.titleLabel.text = "Premier tour"
            self.pageControl.currentPage = 0
            self.isFirstRoundDisplay = true
//            self.hideSecondRound()
            
            UIView.animate(withDuration: 0.3, animations: {
                self.titleLabel.alpha = 1.0
            })
        }
    }
    
    @IBAction func showSecondTurn(_ sender: Any) {
        // will show second turn
        print("show second turn")
        
        if !isFirstRoundDisplay || isAnimating { // stop here
            return
        }
        
        self.showSecondRound()
        UIView.animate(withDuration: 0.3, animations: {
            self.titleLabel.alpha = 0.0
        }) { success in
            
            self.titleLabel.text = "Second tour"
            self.pageControl.currentPage = 1
            self.isFirstRoundDisplay = false
//            self.showSecondRound()
            
            UIView.animate(withDuration: 0.3, animations: {
                self.titleLabel.alpha = 1.0
            })
        }
    }
    
    func showSecondRound() {
        
        if let controller = secondRoundController {
            
            let startFrame = CGRect(x: 0, y: self.view.frame.maxY, width: self.view.frame.size.width, height: self.view.frame.size.height)
            
            let endFrame = self.view.frame
            
            controller.view.frame = startFrame
            controller.updateLayouts()
            self.view.addSubview(controller.view)
            
            UIView.animate(withDuration: 0.3, animations: {
                controller.view.frame = endFrame
            })
            
        }
    }
    
    func hideSecondRound() {
        
        if let controller = secondRoundController {
            
            let endFrame = CGRect(x: 0, y: controller.view.frame.maxY, width: controller.view.frame.size.width, height: controller.view.frame.size.height)
            
            UIView.animate(withDuration: 0.3, animations: { 
                controller.view.frame = endFrame
            }, completion: { success in
                controller.view.removeFromSuperview()
            })
            
        }
        
    }

}

