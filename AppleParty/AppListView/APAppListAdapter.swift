//
//  APAppListAdapter.swift
//  AppleParty
//
//  Created by HTC on 2022/3/17.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APAppListAdapter: NSObject {
    
    public var purchseHandle: ((_ app: App) -> Void)?
    public var screenshotHandle: ((_ app: App) -> Void)?
    
    fileprivate static let numberOfSections = 1
    fileprivate static let itemId = "APAppListCell"
    
    fileprivate var items = [App]() {
        didSet {
            collectionView.reloadData()
        }
    }
    private var collectionView: NSCollectionView
    
    init(collectionView: NSCollectionView) {
        self.collectionView = collectionView
        super.init()
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.register(APAppListCell.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: APAppListAdapter.itemId))
        
        let itemWidth = CGFloat(350.0)
        let itemHeight = CGFloat(150.0)
        let itemSpacing = CGFloat(80.0)
        let itemPadding = CGFloat(30.0)
        
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.itemSize = NSMakeSize(itemWidth, itemHeight)
        flowLayout.minimumInteritemSpacing = itemSpacing
        flowLayout.minimumLineSpacing = itemSpacing
        flowLayout.sectionInset = NSEdgeInsetsMake(itemPadding, itemPadding, itemPadding, itemPadding)
        self.collectionView.collectionViewLayout = flowLayout
    }
    
    func set(items: [App]) {
        self.items = items
    }
}


extension APAppListAdapter: NSCollectionViewDataSource, NSCollectionViewDelegate {
    func numberOfSectionsInCollectionView(collectionView: NSCollectionView) -> Int {
        return APAppListAdapter.numberOfSections
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: APAppListAdapter.itemId), for: indexPath)
        guard let collectionViewItem = item as? APAppListCell else { return item }
        
        collectionViewItem.configure(app: items[indexPath.item])
        collectionViewItem.purchseHandle = purchseHandle
        collectionViewItem.screenshotHandle = screenshotHandle
        
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        collectionView.deselectItems(at: indexPaths)
    }
}
