//
//  LocationsCell.swift
//  Uber
//
//  Created by Umang Kedan on 21/02/24.
//

import UIKit

class LocationsCell: UITableViewCell {

    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setLocationData(name : String , from : String , to : String){
        nameLabel.text = name
        toLabel.text = to
        fromLabel.text = from
        
    }
    
}
