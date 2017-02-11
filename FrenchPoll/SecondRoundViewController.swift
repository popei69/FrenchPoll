//
//  SecondRoundViewController.swift
//  FrenchPoll
//
//  Created by Benoit PASQUIER on 10/02/2017.
//  Copyright © 2017 Benoit PASQUIER. All rights reserved.
//

import UIKit

class SecondRoundViewController: UIViewController {
    
    // logic
    var firstCandidate : Candidate?
    var secondCandidate : Candidate?
    
    var delegate : CandidateListController?
    
    @IBOutlet weak var contentView: UIView!
    
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

        // Do any additional setup after loading the view.
        
        self.view.backgroundColor = UIColor.clear
        
        // set color gradients
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.contentView.bounds
        
        let greyColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0) // #F1F1F1
        gradientLayer.colors = [UIColor.white.cgColor, greyColor.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.cornerRadius = 10.0
        
//        self.contentView.layer.addSublayer(gradientLayer)
        
//        self.contentView.layer.borderColor = UIColor.black.cgColor //UIColor(red: 151/255, green: 151/255, blue: 151/255, alpha: 31/255).cgColor // #979797
//        self.contentView.layer.borderWidth = 2.0
        self.contentView.layer.cornerRadius = 10.0
        
        self.contentView.layer.shadowColor = UIColor.black.cgColor
        self.contentView.layer.shadowOpacity = 0.8
        self.contentView.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.contentView.layer.shadowRadius = 10
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
            
            
            // second score
            let secondScoreEvolution = secondCandidate.compareLatestValues()
            if secondScoreEvolution > 0 {
                
                secondScoreImageView.image = UIImage(named: "top-arrow")
                secondScoreImageView.isHidden = false
                
                secondScoreEvolutionLabel.text = "+" + String(secondScoreEvolution)
                secondScoreEvolutionLabel.textColor = AppHelper.greenColour
                secondScoreEvolutionLabel.isHidden = false
                
            } else if firstScoreEvolution < 0 {
                
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func hideLayout(_ sender: Any) {
        
        if let delegate = delegate {
            delegate.showFirstTurn(sender)
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
