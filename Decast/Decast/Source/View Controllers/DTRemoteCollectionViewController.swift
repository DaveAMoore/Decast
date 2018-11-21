//
//  DTRemoteCollectionViewController.swift
//  Decast
//
//  Created by David Moore on 11/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import SFKit

class DTRemoteCollectionViewController: DTCollectionViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func appearanceStyleDidChange(_ previousAppearanceStyle: SFAppearanceStyle) {
        super.appearanceStyleDidChange(previousAppearanceStyle)
    }
    
    // MARK: - Collection View Data Source
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2;
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DTRemoteCell.typeName, for: indexPath) as! DTRemoteCell
        
        /*cell.titleLabel?.text = NSLocalizedString("Hello World", comment: "")
        cell.detailLabel?.text = NSLocalizedString("Okay", comment: "")
        
        if cell.widthConstraint == nil {
            //cell.widthConstraint = cell.widthAnchor.constraint(equalTo: collectionView.widthAnchor, constant: 80)
            //cell.widthConstraint.isActive = true
        }
        */
        // cell.setWidth(to: collectionView.bounds.width - 60)
        
        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
}
