//
//  APRootCollectionAdapter.swift
//  AppleParty
//
//  Created by HTC on 2022/3/14.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APRootCollectionAdapter: NSObject {
    fileprivate static let numberOfSections = 1
    fileprivate static let itemId = "APRootCollectionCell"
    
    fileprivate var items = [APRootCollectionModel]() {
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
        self.collectionView.register(APRootCollectionCell.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: APRootCollectionAdapter.itemId))
    }
    
    func set(items: [APRootCollectionModel]) {
        self.items = items
    }
}


extension APRootCollectionAdapter: NSCollectionViewDataSource, NSCollectionViewDelegate {
    func numberOfSectionsInCollectionView(collectionView: NSCollectionView) -> Int {
        return APRootCollectionAdapter.numberOfSections
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: APRootCollectionAdapter.itemId), for: indexPath)
        guard let collectionViewItem = item as? APRootCollectionCell else { return item }
        
        let name = items[indexPath.item].name
        let icon = items[indexPath.item].icon
        collectionViewItem.configure(name: name, icon: icon)
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        collectionView.deselectItems(at: indexPaths)
        if let item = indexPaths.first?.item, let handler = items[item].handler {
            handler()
        }
    }
}
