//
//  DTTableViewCell.swift
//  Decast
//
//  Created by David Moore on 11/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import SFKit

class DTTableViewCell: UITableViewCell {

    // MARK: - Outlets
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var containerView: UIView!
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func appearanceStyleDidChange(_ previousAppearanceStyle: SFAppearanceStyle) {
        super.appearanceStyleDidChange(previousAppearanceStyle)
        
        let colorMetrics = UIColorMetrics(forAppearance: appearance)
        
        containerView.clipsToBounds = false
        containerView.layer.cornerRadius = 8.0
        containerView.layer.shadowColor = colorMetrics.color(forRelativeHue: .black).cgColor
        containerView.layer.shadowOpacity = 0.125
        containerView.layer.shadowRadius = 4.0
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        titleLabel.textColor = colorMetrics.color(forRelativeHue: .white)
        containerView.backgroundColor = colorMetrics.color(forRelativeHue: .pink)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
