//
//  CandidateListController.swift
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
    var methodologyString = ""
    
    var pollingTimer : Timer?
    let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.apple.com")
    
    
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
    var isFirstRoundDisplay = true
    var secondRoundCandidates : [Candidate] = []
    
    // second round 
    var secondRoundController : SecondRoundViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        titleLabel.text = NSLocalizedString("First round", comment: "First round")
        
        parseDateformatter.dateFormat = "YYYY-MM-dd"
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        
        self.tableView.backgroundColor = UIColor.clear
        
        self.pollData()
        self.startNetworkReachabilityObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if pollingTimer == nil {
            pollingTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(CandidateListController.pollData), userInfo: nil, repeats: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let timer = pollingTimer {
            timer.invalidate()
            pollingTimer = nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func startNetworkReachabilityObserver() {
        reachabilityManager?.listener = { status in
            
            switch status {
                
            case .notReachable:
                print("The network is not reachable")
                self.displayNetworkDialog()
                break
                
            case .reachable(.ethernetOrWiFi):
                print("The network is reachable over the WiFi connection")
                self.pollData()
                break
                
            default:
                break
            }
        }
        
        // start listening
        reachabilityManager?.startListening()
    }
    
    func displayNetworkDialog() {
        let alertController = UIAlertController(title: "Network issue", message: "Verify your connection and try again.", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: "Close"), style: .cancel, handler: { alertAction in
            alertController.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func reloadData() {
        // got new data, sort and reload ui
        candidates.sort {
            $0.data.first!.value > $1.data.first!.value
        }
        secondRoundCandidates.sort {
            $0.data.first!.value > $1.data.first!.value
        }
        
        tableView.reloadData()
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
                
                if let methodology = swiftyJson["data"]["methodologie"].string, let finalString = self.convertedEncodedToString(sourceString: methodology) {
                    self.methodologyString = finalString
                }
                
                self.candidates.removeAll()
                self.secondRoundCandidates.removeAll()
                
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
    
    private func convertedEncodedToString(sourceString: String) -> String? {
        if let htmldata = sourceString.data(using: String.Encoding.utf8),
            let attributedString = try? NSAttributedString(data: htmldata, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil) {
            let finalString = attributedString.string
            return finalString
        }
        
        return nil
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
            label.text = NSLocalizedString("Last update", comment: "Last update") + dateFormatter.string(from: date)
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
    
    // MARK: Animation
    
    @IBAction func showFirstTurn(_ sender: Any) {
        // will show first turn
        print("show first turn")
        
        if let controller = self.secondRoundController {
            
            controller.dismiss(animated: true, completion: nil)
            secondRoundController = nil
        }
        
        if isFirstRoundDisplay { // stop here
            return
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.titleLabel.alpha = 0.0
        }) { success in
            
            self.titleLabel.text = NSLocalizedString("First round", comment: "First round")
            self.pageControl.currentPage = 0
            self.isFirstRoundDisplay = true
            
            UIView.animate(withDuration: 0.3, animations: {
                self.titleLabel.alpha = 1.0
            })
        }
    }
    
    @IBAction func showSecondTurn(_ sender: Any) {
        // will show second turn
        print("show second turn")
        
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "SecondRoundViewController") as? SecondRoundViewController {
//            secondRoundCandidates.count == 2 {
            
//            controller.firstCandidate = secondRoundCandidates[0]
//            controller.secondCandidate = secondRoundCandidates[1]
            controller.delegate = self
            controller.view.backgroundColor = UIColor.clear
            controller.modalPresentationStyle = .overCurrentContext
            self.secondRoundController = controller
            self.present(controller, animated: true, completion: nil)
        }
        
        if !isFirstRoundDisplay { // stop here
            return
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.titleLabel.alpha = 0.0
        }) { success in
            
            self.titleLabel.text = NSLocalizedString("Second round", comment: "Second round")
            self.pageControl.currentPage = 1
            self.isFirstRoundDisplay = false
            
            UIView.animate(withDuration: 0.3, animations: {
                self.titleLabel.alpha = 1.0
            })
        }
    }
    
    // MARK: Share button
    
    @IBAction func showShareButton(_ sender: Any) {
        
        let alertController = UIAlertController(title: NSLocalizedString("Share your love", comment: "Share your love"), message: NSLocalizedString("Share it", comment: "Share it"), preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Rate it on App Store", comment: "Rate it on App Store"), style: .default, handler: { alertAction in
            
            guard let url = URL(string: AppHelper.storeUrl) else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { alertAction in
            alertController.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func showInfoButton(_ sender: Any) {
        
        // get the data from server side
        if !methodologyString.isEmpty {
            
            let message = NSLocalizedString("App based data", comment: "App based data") + "\n\n \"" + methodologyString + "\""
            
            let alertController = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: message, preferredStyle: .actionSheet)
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: "Close"), style: .cancel, handler: { alertAction in
                alertController.dismiss(animated: true, completion: nil)
            }))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    

}

