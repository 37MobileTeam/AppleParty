//
//  APCollectionView.swift
//  AppleParty
//
//  Created by HTC on 2022/3/14.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APCollectionView: NSView {

    lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        let margin: CGFloat = 20
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsetsMake(0, margin, 0, margin)
        scrollView.scrollerInsets = NSEdgeInsetsMake(0, 0, 0, -margin)
        return scrollView
    }()

    lazy var collectionView: NSCollectionView = {
        let itemWidth = CGFloat(150.0)
        let itemHeight = CGFloat(150.0)
        let itemSpacing = CGFloat(100.0)
        let itemPadding = CGFloat(50.0)
        
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.itemSize = NSMakeSize(itemWidth, itemHeight)
        flowLayout.minimumInteritemSpacing = itemSpacing
        flowLayout.minimumLineSpacing = itemSpacing
        flowLayout.sectionInset = NSEdgeInsetsMake(itemPadding, itemPadding, itemPadding, itemPadding)

        let collection = NSCollectionView()
        collection.collectionViewLayout = flowLayout
        collection.isSelectable = true
        return collection
    }()
    
    init() {
        super.init(frame: .zero)
        addSubviews()
        addConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension APCollectionView {
    
    func configure(superView: NSView) {
        superView.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: superView.topAnchor),
            self.leadingAnchor.constraint(equalTo: superView.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: superView.trailingAnchor),
            self.bottomAnchor.constraint(equalTo: superView.bottomAnchor)
        ])
    }
    
    private func addSubviews() {
        scrollView.documentView = collectionView
        [scrollView].forEach(addSubview)
    }
    
    private func addConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: scrollView.superview!.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: scrollView.superview!.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: scrollView.superview!.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: scrollView.superview!.bottomAnchor)
        ])
    }
}
