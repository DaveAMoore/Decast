//
//  DTLibraryViewController.swift
//  Decast
//
//  Created by David Moore on 11/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import SFKit
import RemoteKit

class DTLibraryViewController: DTCollectionViewController {

    // MARK: - Properties
    
    /// All of the sessions for different devices.
    var sessions: [RKSession] = []
    
    /// Collection of the users remotes.
    var remotes: [RKRemote] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // Register the cell.
        registerCollectionViewCell(ofType: DTRemoteCell.self)
        
        RKSessionManager.shared.fetchAllDevices { devices, error in
            guard let devices = devices else {
                fatalError("Failed fetching devices: \(error!.localizedDescription)")
            }
            
            for device in devices {
                let session = RKSession(device: device)
                session.activate()
                
                self.sessions.append(session)
            }
            
            // Query the remotes.
            RKSessionManager.shared.fetchAllRemotes { remotes, error in
                guard let remotes = remotes else {
                    fatalError("Failed querying remotes: \(error!.localizedDescription)")
                }
                
                DispatchQueue.main.async {
                    self.remotes = remotes
                    self.collectionView.reloadData()
                }
            }
        }
    }

    override func appearanceStyleDidChange(_ previousAppearanceStyle: SFAppearanceStyle) {
        super.appearanceStyleDidChange(previousAppearanceStyle)
    }
    
    // MARK: - Data Model
    
    func remote(forItemAt indexPath: IndexPath) -> RKRemote {
        return remotes[indexPath.row]
    }
    
    // MARK: - Collection View Data Source
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return remotes.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: DTRemoteCell.self, for: indexPath)
        
        let item = remote(forItemAt: indexPath)
        
        // Configure the cell.
        cell.titleLabel.text = item.localizedTitle
        cell.setWidth(to: collectionViewContentSize.width / 2 - 8.1)
        
        return cell
    }
    
    // MARK: - Collection View Delegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = remote(forItemAt: indexPath)
        performSegue(withIdentifier: "Foo", sender: item)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if let destination = segue.destination as? DTRemoteCollectionViewController, let remote = sender as? RKRemote {
            destination.sessions = sessions
            destination.remote = remote
        }
    }
}
