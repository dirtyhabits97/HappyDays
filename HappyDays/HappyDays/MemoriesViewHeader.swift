//
//  MainViewHeader.swift
//  HappyDays
//
//  Created by GERH on 6/17/17.
//  Copyright © 2017 GERH. All rights reserved.
//

import UIKit
import SnapKit

class MemoriesViewHeader: UICollectionViewCell {
    
    lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "What to search for?"
        sb.searchBarStyle = .minimal
        UILabel.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = UIColor(white: 0.82, alpha: 1)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = .white
        return sb
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .darkGray
        setupSearchBar()
    }
    
    fileprivate func setupSearchBar() {
        addSubview(searchBar)
        searchBar.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
