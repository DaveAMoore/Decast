//
//  DTCollectionViewCell.swift
//  Decast
//
//  Created by David Moore on 11/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import SFKit

class DTCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    var widthConstraint: NSLayoutConstraint!
    
    // MARK: - Outlets
    
    /// Label which displays the title.
    @IBOutlet var titleLabel: UILabel?
    
    /// Label which is intended to display detail.
    @IBOutlet var detailLabel: UILabel?
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // translatesAutoresizingMaskIntoConstraints = false
        //widthConstraint = widthAnchor.constraint(equalToConstant: 0)
    }
    
    override func appearanceStyleDidChange(_ previousAppearanceStyle: SFAppearanceStyle) {
        super.appearanceStyleDidChange(previousAppearanceStyle)
        
        let colorMetrics = UIColorMetrics(forAppearance: appearance)
        titleLabel?.textColor = colorMetrics.color(forRelativeHue: .white)
        detailLabel?.textColor = colorMetrics.color(forRelativeHue: .lightGray)
        contentView.backgroundColor = colorMetrics.color(forRelativeHue: .blue)
        
        layer.cornerRadius = 8.0
    }
    
    // MARK: - Layout
    
    /*func setWidth(to width: CGFloat) {
        widthConstraint.constant = width
        widthConstraint.isActive = true
    }*/
}
