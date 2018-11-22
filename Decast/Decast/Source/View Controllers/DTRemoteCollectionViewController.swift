//
//  DTRemoteCollectionViewController.swift
//  Decast
//
//  Created by David Moore on 11/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import SFKit
import RemoteKit

class DTRemoteCollectionViewController: DTCollectionViewController {
    
    // MARK: - Properties
    
    var sessions: [RKSession]!
    var remote: RKRemote!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessions.forEach { $0.delegate = self }
        
        // Register the cell.
        registerCollectionViewCell(ofType: DTCommandCell.self)
        
        // Update the title.
        title = remote.localizedTitle
    }
    
    override func appearanceStyleDidChange(_ previousAppearanceStyle: SFAppearanceStyle) {
        super.appearanceStyleDidChange(previousAppearanceStyle)
    }
    
    // MARK: - Data Model
    
    func command(forItemAt indexPath: IndexPath) -> RKCommand {
        return remote.commands[indexPath.row]
    }
    
    // MARK: - Collection View Data Source
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return remote.commands.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: DTCommandCell.self, for: indexPath)
        
        // Retrieve the command.
        let item = command(forItemAt: indexPath)
        
        // Configure the cell.
        cell.titleLabel.text = item.localizedTitle
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = super.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
        
        size.height *= 2 / 3
        
        return size
    }
    
    // MARK: - Collection View Delegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = command(forItemAt: indexPath)
        sessions.forEach { $0.send(item, for: remote) }
    }
}

extension DTRemoteCollectionViewController: RKSessionDelegate {
    
    func sessionDidActivate(_ session: RKSession) {
        
    }
    
    func session(_ session: RKSession, didFailWithError error: Error) {
        
    }
    
    func session(_ session: RKSession, didSendCommand command: RKCommand, forRemote remote: RKRemote) {
        
    }
    
    func session(_ session: RKSession, didFailToSendCommand command: RKCommand, forRemote remote: RKRemote, withError error: Error) {
        
    }
}
