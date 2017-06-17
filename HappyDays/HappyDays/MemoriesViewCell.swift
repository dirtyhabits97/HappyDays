//
//  MainViewCell.swift
//  HappyDays
//
//  Created by GERH on 6/17/17.
//  Copyright © 2017 GERH. All rights reserved.
//

import UIKit
import SnapKit

class MemoriesViewCell: UICollectionViewCell {
    
    let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .lightGray
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    fileprivate func setupViews() {
        addSubview(photoImageView)
        photoImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
