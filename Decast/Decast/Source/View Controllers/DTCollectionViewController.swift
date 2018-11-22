//
//  DTCollectionViewController.swift
//  Decast
//
//  Created by David Moore on 11/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import SFKit

open class DTCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Properties
    
    /// The flow layout of the collection view.
    open var collectionViewFlowLayout: UICollectionViewFlowLayout {
        return collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    /// Content size of the embedded collection view.
    open var collectionViewContentSize: CGSize {
        // Calculate the horizontal and vertical insets.
        let horizontalInsets = collectionView!.contentInset.left + collectionView!.contentInset.right + collectionViewFlowLayout.sectionInset.left + collectionViewFlowLayout.sectionInset.right
        let verticalInsets = collectionView!.contentInset.top + collectionView!.contentInset.bottom + collectionViewFlowLayout.sectionInset.top + collectionViewFlowLayout.sectionInset.bottom
        
        // Determine the content size of the collection view.
        let contentSize = CGSize(width: collectionView!.bounds.width - horizontalInsets,
                                 height: collectionView!.bounds.height - verticalInsets)
        
        return contentSize
    }
    
    // MARK: - Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Enables autosizing cells.
        // collectionViewFlowLayout.estimatedItemSize = CGSize(width: 100, height: 100)
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection == nil {
            // Update the spacing.
            updateCollectionViewSpacing(for: view.bounds.size)
        }
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    open override func appearanceStyleDidChange(_ previousAppearanceStyle: SFAppearanceStyle) {
        super.appearanceStyleDidChange(previousAppearanceStyle)
        
        let colorMetrics = UIColorMetrics(forAppearance: appearance)
        view.backgroundColor = colorMetrics.color(forRelativeHue: .white)
        collectionView?.backgroundColor = colorMetrics.color(forRelativeHue: .white)
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - Collection View Cell Management
    
    /// Loads a `NIB` for a given `SFIdentifiable` type.
    open func loadNib<T: SFIdentifiable>(for type: T.Type) -> UINib {
        return UINib(nibName: name(of: type), bundle: nil)
    }
    
    /// Registers a `UICollectionReuseableView` for a supplementary view of a kind.
    open func registerReusableView<T: UICollectionReusableView>(ofType type: T.Type, forSupplementaryViewOfKind kind: String) {
        // Load the nib from the main bundle.
        let supplementaryNib = loadNib(for: type)
        
        // Register the header nib with the collection view.
        collectionView?.register(supplementaryNib, forSupplementaryViewOfKind: kind, withReuseIdentifier: type.typeName)
    }
    
    /// Registers a `UICollectionViewCell` of type `T`.
    open func registerCollectionViewCell<T: UICollectionViewCell>(ofType type: T.Type) {
        // Load the nib from the main bundle.
        let cellNib = loadNib(for: type)
        
        // Register the cell for the generic reuse identifier.
        collectionView?.register(cellNib, forCellWithReuseIdentifier: type.typeName)
    }
    
    // MARK: - Layout Updating
    
    /// Determines the minimum interitem spacing for any number of horizontal items.
    open func minimumInteritemSpacing(for numberOfItems: Int) -> CGFloat {
        // Calculate the amount of inter-item spacing for the numberOfItems.
        let interitemSpacing = collectionViewFlowLayout.minimumInteritemSpacing * CGFloat(max(numberOfItems - 1, 0))
        
        return interitemSpacing
    }
    
    /// This method is called when the view controller's view's size is changed by its parent (i.e. for the root view controller when its window rotates or is resized).
    ///
    /// If you override this method, you should either call super to propagate the change to children or manually forward the change to children.
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Update the collection view spacing.
        updateCollectionViewSpacing(for: size)
        
        // Invalidate the layout with the collection view.
        collectionViewLayout.invalidateLayout()
    }
    
    /// Updates the spacing of the `collectionView`.
    ///
    /// - Parameter size: The size for which the collection view's spacing is updated for.
    open func updateCollectionViewSpacing(for size: CGSize) {
        collectionViewFlowLayout.minimumInteritemSpacing = 16
        collectionViewFlowLayout.minimumLineSpacing = 16
        
        collectionView?.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                             sizeForItemAt indexPath: IndexPath) -> CGSize {
        /// Calculates the width for a given number of items with a spacing constant.
        func calculatedWidth(forNumberOfItems numberOfItems: Int, withSpacingFor numberOfSpacingItems: Int) -> CGFloat {
            // Calculate the amount of inter-item spacing for the numberOfItems.
            // FIXME: Minimum interitem spacing is messing up layout.
            let interitemSpacing = minimumInteritemSpacing(for: numberOfSpacingItems)
            
            // The width is equal the content width subtract the interitemSpacing all divided by the number of items.
            return floor((collectionViewContentSize.width - interitemSpacing - collectionView.safeAreaInsets.left - collectionView.safeAreaInsets.right) / CGFloat(numberOfItems))
        }
        
        /// Calculates the width for a given number of items.
        func calculatedWidth(forNumberOfItems numberOfItems: Int) -> CGFloat {
            return calculatedWidth(forNumberOfItems: numberOfItems, withSpacingFor: numberOfItems)
        }
        
        /// Calculates the height for a given width.
        func calculatedHeight(forWidth width: CGFloat, sizeClass: UIUserInterfaceSizeClass) -> CGFloat {
            // Declare a multipler.
            let multiplier: CGFloat
            
            // Switch on the size class to provide a different multiplier for each situation.
            switch sizeClass {
            case .compact, .unspecified:
                multiplier = 820 / 1214
            case .regular:
                multiplier = 2 / 3
            }
            
            // Return the width multiplied by the pre-determined value, and then floor the output.
            return floor(width * multiplier)
        }
        
        /// Computes the size for a given `numberOfItems`.
        func calculatedSize(forNumberOfItems numberOfItems: Int, verticalSizeClass: UIUserInterfaceSizeClass) -> CGSize {
            let width = calculatedWidth(forNumberOfItems: numberOfItems)
            let height = calculatedHeight(forWidth: width, sizeClass: verticalSizeClass)
            
            return CGSize(width: width, height: height)
        }
        
        /// Calculates the size for a given number of items, altering the spacing multiplicative and the vertical size class.
        func calculatedSize(forNumberOfItems numberOfItems: Int, withSpacingFor numberOfSpacingItems: Int, verticalSizeClass: UIUserInterfaceSizeClass) -> CGSize {
            let width = calculatedWidth(forNumberOfItems: numberOfItems, withSpacingFor: numberOfSpacingItems)
            let height = calculatedHeight(forWidth: width, sizeClass: verticalSizeClass)
            
            return CGSize(width: width, height: height)
        }
        
        /// Computes the size, where a previous size has its width multiplied by the `multiplier`.
        func calculatedSize(for size: CGSize, multiplier: CGFloat) -> CGSize {
            return CGSize(width: size.width * multiplier, height: size.height)
        }
        
        // Switch on the horizontal size class.
        switch traitCollection.horizontalSizeClass {
        case .compact, .unspecified:
            return calculatedSize(forNumberOfItems: 2, verticalSizeClass: traitCollection.verticalSizeClass)
        case .regular:
            let halfWidth = collectionViewContentSize.width / 2
            
            guard halfWidth > 400 else {
                return calculatedSize(forNumberOfItems: 3, verticalSizeClass: .regular)
            }
            
            guard halfWidth < 600 else {
                return calculatedSize(forNumberOfItems: 4, verticalSizeClass: .compact)
            }
            
            // Calculate the width and height for the irregular dimensions.
            let irregularWidth = calculatedWidth(forNumberOfItems: 2, withSpacingFor: 2)
            let irregularHeight = calculatedHeight(forWidth: calculatedWidth(forNumberOfItems: 2), sizeClass: .compact)
            let irregularSize = CGSize(width: irregularWidth, height: irregularHeight)
            
            if indexPath.row % 3 == 0 {
                return calculatedSize(for: irregularSize, multiplier: 3 / 5)
            } else {
                return calculatedSize(for: irregularSize, multiplier: 2 / 5)
            }
        }
    }
}
