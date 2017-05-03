//
//  FinalRoundViewController.swift
//  FrenchPoll
//
//  Created by Benoit PASQUIER on 03/05/2017.
//  Copyright © 2017 Benoit PASQUIER. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class FinalRoundViewController: UIViewController {
    
    var candidates : [Candidate] = []
    var firstCandidate : Candidate?
    var secondCandidate : Candidate?
    var methodologyString = ""
    
    var pollingTimer : Timer?
    let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.apple.com")
    
    
    var dateFormatter = DateFormatter()
    var parseDateformatter = DateFormatter()
    
    // UI
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var voteLabel: UILabel!
    @IBOutlet weak var noAvailableLabel: UILabel!
    
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    // first candidate UI
    @IBOutlet weak var firstCandidateImageView: UIImageView!
    @IBOutlet weak var firstScoreLabel: UILabel!
    @IBOutlet weak var firstScoreEvolutionLabel: UILabel!
    @IBOutlet weak var firstScoreImageView: UIImageView!
    
    // second candidate UI
    @IBOutlet weak var secondCandidateImageView: UIImageView!
    @IBOutlet weak var secondScoreLabel: UILabel!
    @IBOutlet weak var secondScoreEvolutionLabel: UILabel!
    @IBOutlet weak var secondScoreImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = NSLocalizedString("Second round", comment: "Second round")
        
        parseDateformatter.dateFormat = "YYYY-MM-dd"
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        
        voteLabel.text = NSLocalizedString("Don't forget", comment: "Don't forget to vote")
        noAvailableLabel.text = NSLocalizedString("No availability", comment: "No data available")
        
        if let lastRefreshData = AppHelper.fetchSavedData() {
            populateDataFromResult(jsonString: lastRefreshData)
        }
        
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
        
        // set color gradients
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.backgroundView.bounds
        
        let greyColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0) // #F1F1F1
        gradientLayer.colors = [UIColor.white.cgColor, greyColor.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.cornerRadius = 10.0
        
        let maskPath = UIBezierPath(roundedRect: self.backgroundView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10))
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        self.backgroundView.layer.mask = maskLayer
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
        
        firstCandidate = candidates[0]
        secondCandidate = candidates[1]
        
        updateLayouts()
    }
    
    func pollData() {
        
        Alamofire.request(AppHelper.url).responseString { (response) in
            // print(response.request)  // original URL request
            // print(response.response) // HTTP URL response
            // print(response.data)     // server data
//             print(response.result)   // result of response serialization
            
            if let tmpJson = response.result.value {
                
                self.populateDataFromResult(jsonString: tmpJson)
            }
        }
    }
    
    private func populateDataFromResult(jsonString: String) {
        
        let swiftyJson = JSON.init(parseJSON: jsonString)
         print("JSON: \(swiftyJson)")
        
        guard let data = swiftyJson["data"] as? JSON else {
            return
        }
        
        AppHelper.savePollData(jsonString: jsonString)
        
        if let methodology = data["methodologie"].string, let finalString = self.convertedEncodedToString(sourceString: methodology) {
            self.methodologyString = finalString
        }
        
        self.candidates.removeAll()
        
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
                
                self.candidates.append(tmpCandidate)
            }
        }
        
        self.reloadData()
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
    
    func updateLayouts() {
        
        if let firstCandidate = firstCandidate,
            let secondCandidate = secondCandidate {
            
            firstScoreLabel.text = firstCandidate.getCurrentScore()
            firstCandidateImageView.image = UIImage(named: firstCandidate.getImageName())
            firstCandidateImageView.layer.cornerRadius = firstCandidateImageView.frame.size.width / 2
            firstCandidateImageView.layer.masksToBounds = true
            firstCandidateImageView.layer.borderColor = UIColor.darkGray.cgColor
            firstCandidateImageView.layer.borderWidth = 1
            
            secondScoreLabel.text = secondCandidate.getCurrentScore()
            secondCandidateImageView.image = UIImage(named: secondCandidate.getImageName())
            secondCandidateImageView.layer.cornerRadius = secondCandidateImageView.frame.size.width / 2
            secondCandidateImageView.layer.masksToBounds = true
            secondCandidateImageView.layer.borderColor = UIColor.darkGray.cgColor
            secondCandidateImageView.layer.borderWidth = 1
            
            // first score
            let firstScoreEvolution = firstCandidate.compareLatestValues()
            if firstScoreEvolution > 0 {
                
                firstScoreImageView.image = UIImage(named: "top-arrow")
                firstScoreImageView.isHidden = false
                
                firstScoreEvolutionLabel.text = "+" + String(firstScoreEvolution)
                firstScoreEvolutionLabel.textColor = AppHelper.greenColour
                firstScoreEvolutionLabel.isHidden = false
                
            } else if firstScoreEvolution < 0 {
                
                firstScoreImageView.image = UIImage(named: "bottom-arrow")
                firstScoreImageView.isHidden = false
                
                firstScoreEvolutionLabel.text = String(firstScoreEvolution)
                firstScoreEvolutionLabel.textColor = AppHelper.redColour
                firstScoreEvolutionLabel.isHidden = false
                
            } else {
                firstScoreImageView.isHidden = true
                firstScoreEvolutionLabel.isHidden = true
            }
            
            if let date = candidates[0].getLatestUpdate() {
                dateLabel.text = NSLocalizedString("Last update", comment: "Last update") + dateFormatter.string(from: date)
            } else {
                dateLabel.text = ""
            }
            
            
            // second score
            let secondScoreEvolution = secondCandidate.compareLatestValues()
            if secondScoreEvolution > 0 {
                
                secondScoreImageView.image = UIImage(named: "top-arrow")
                secondScoreImageView.isHidden = false
                
                secondScoreEvolutionLabel.text = "+" + String(secondScoreEvolution)
                secondScoreEvolutionLabel.textColor = AppHelper.greenColour
                secondScoreEvolutionLabel.isHidden = false
                
            } else if secondScoreEvolution < 0 {
                
                secondScoreImageView.image = UIImage(named: "bottom-arrow")
                secondScoreImageView.isHidden = false
                
                secondScoreEvolutionLabel.text = String(secondScoreEvolution)
                secondScoreEvolutionLabel.textColor = AppHelper.redColour
                secondScoreEvolutionLabel.isHidden = false
                
            } else {
                secondScoreImageView.isHidden = true
                secondScoreEvolutionLabel.isHidden = true
            }
        }
    }
    
    // MARK: Share button
    
    @IBAction func showShareButton(_ sender: Any) {
        
        let alertController = UIAlertController(title: NSLocalizedString("Share your love", comment: "Share your love"), message: NSLocalizedString("Share it", comment: "Share it"), preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Rate it on App Store", comment: "Rate it on App Store"), style: .default, handler: { alertAction in
            
            guard let url = URL(string: AppHelper.storeUrl) else { return }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(url)
            }
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
