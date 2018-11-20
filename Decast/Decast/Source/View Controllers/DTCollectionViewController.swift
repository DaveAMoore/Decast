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
    
    /// Add a comment.
    final lazy var headerTemplateView: DTBoldHeaderView = {
        // Instantiate the NIB from the main bundle.
        let headerTemplateViewNib = loadNib(for: DTBoldHeaderView.self)
        
        // Get the BoldHeaderView from the NIB.
        let headerTemplateView = headerTemplateViewNib.instantiate(withOwner: self, options: nil).first as! DTBoldHeaderView
        
        return headerTemplateView
    }()
    
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
        
        // Register the bold header view for the section header.
        register(DTBoldHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
        
        // Register the generic cell.
        register(DTCollectionViewCell.self)
        
        // Enables autosizing cells.
        collectionViewFlowLayout.estimatedItemSize = CGSize(width: 100, height: 100)
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection == nil {
            // Update the spacing.
            updateCollectionViewSpacing(for: view.bounds.size)
        }
    }
    
    /* Reorder support.
     @objc func handleLongGesture(_ gesture: UILongPressGestureRecognizer) {
     switch gesture.state {
     case .began:
     guard let selectedIndexPath = collectionView!.indexPathForItem(at: gesture.location(in: collectionView)) else { break }
     collectionView?.beginInteractiveMovementForItem(at: selectedIndexPath)
     case .changed:
     collectionView?.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view))
     case .ended:
     collectionView?.endInteractiveMovement()
     default:
     collectionView?.cancelInteractiveMovement()
     }
     } */
    
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
    private func loadNib<T: SFIdentifiable>(for type: T.Type) -> UINib {
        return UINib(nibName: name(of: type), bundle: nil)
    }
    
    /// Registers a `UICollectionReuseableView` for a supplementary view of a kind.
    private func register<T: UICollectionReusableView>(_ type: T.Type, forSupplementaryViewOfKind kind: String) {
        // Load the nib from the main bundle.
        let supplementaryNib = loadNib(for: type)
        
        // Register the header nib with the collection view.
        collectionView?.register(supplementaryNib, forSupplementaryViewOfKind: kind, withReuseIdentifier: type.typeName)
    }
    
    /// Registers a `UICollectionViewCell` of type `T`.
    private func register<T: UICollectionViewCell>(_ type: T.Type) {
        // Load the nib from the main bundle.
        let cellNib = loadNib(for: type)
        
        // Register the cell for the generic reuse identifier.
        collectionView?.register(cellNib, forCellWithReuseIdentifier: type.typeName)
    }
    
    // MARK: - Layout Updating
    
    /// Predicts the number of horizontal cells that can be fit into the width.
    open func estimatedHorizontalCells(forWidth width: CGFloat) -> Int {
        return max(Int(round(collectionViewContentSize.width / (width + collectionViewFlowLayout.minimumInteritemSpacing))), 1)
    }
    
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
        // Perform additional layout adjustments.
        
        // Update the collection view spacing.
        updateCollectionViewSpacing(for: size)
        
        // Invalidate the layout with the collection view.
        collectionViewLayout.invalidateLayout()
    }
    
    /// Updates the spacing of the `collectionView`.
    ///
    /// - Parameter size: The size for which the collection view's spacing is updated for.
    open func updateCollectionViewSpacing(for size: CGSize) {
        // Declare fractionals for both axes.
        let horizontalMultiplier: CGFloat = 0.035
        let verticalMultiplier: CGFloat = horizontalMultiplier
        
        // Delcare the axes products.
        let horizontalProduct: CGFloat
        let verticalProduct: CGFloat
        
        // Switch on the horizontal size class.
        switch traitCollection.horizontalSizeClass {
        case .compact, .unspecified:
            // Set the products.
            horizontalProduct = 16
            verticalProduct = 16
        case .regular:
            // Calculate the products.
            horizontalProduct = size.width * horizontalMultiplier
            verticalProduct = size.height * verticalMultiplier
        }
        
        // Set the spacing for the flow layout.
        collectionViewFlowLayout.minimumInteritemSpacing = horizontalProduct
        collectionViewFlowLayout.minimumLineSpacing = horizontalProduct
        collectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 16, left: 0, bottom: verticalProduct * 2, right: 0)
        
        // Set the collection view's content inset property, which insets all content within the collection view.
        collectionView!.contentInset = UIEdgeInsets(top: 8, left: horizontalProduct, bottom: 8, right: horizontalProduct)
    }
    
    // MARK: - Supplementary Element Sizing
    
    /// Specifies the size for a given header view; indicated by section number, as opposed to `IndexPath`.
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        // Calculate the width as being the current view's width subtracting the left & right edge insets sum.
        let headerTemplateViewWidth = collectionViewContentSize.width
        
        // Set the width of the view's frame
        headerTemplateView.frame.size.width = headerTemplateViewWidth
        
        // Re-layout the header template view.
        headerTemplateView.setNeedsLayout()
        headerTemplateView.layoutIfNeeded()
        
        // Calculate the fitting size for the system layout at the compressed size.
        let fittingSize = headerTemplateView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        
        return fittingSize
    }
}
