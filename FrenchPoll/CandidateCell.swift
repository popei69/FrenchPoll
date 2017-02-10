//
//  CandidateCell.swift
//  FrenchPoll
//
//  Created by Benoit PASQUIER on 07/02/2017.
//  Copyright © 2017 Benoit PASQUIER. All rights reserved.
//

import UIKit

class CandidateCell: UITableViewCell {

    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var candidateImageView: UIImageView!
    @IBOutlet weak var candidateNameLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    @IBOutlet weak var scoreImageView: UIImageView!
    @IBOutlet weak var scorePositionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
