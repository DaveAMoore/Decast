//
//  DTHeaderView.swift
//  Decast
//
//  Created by David Moore on 7/15/17.
//  Copyright © 2017 Moore Development. All rights reserved.
//

import SFKit

class DTHeaderView: UICollectionReusableView {

    // MARK: - Outlets
    
    /// Title label which displays the large title.
    @IBOutlet var titleLabel: UILabel?
    
    /// Label which is intended to display a description of sorts.
    @IBOutlet var subtitleLabel: UILabel?
    
    // MARK: - Lifecycle
    
    override func appearanceStyleDidChange(_ previousAppearanceStyle: SFAppearanceStyle) {
        super.appearanceStyleDidChange(previousAppearanceStyle)
        
        backgroundColor = .clear
        
        let colorMetrics = UIColorMetrics(forAppearance: appearance)
        titleLabel?.textColor = colorMetrics.color(forRelativeHue: .black)
        subtitleLabel?.textColor = colorMetrics.color(forRelativeHue: .gray)
    }
}
