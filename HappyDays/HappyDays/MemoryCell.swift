//
//  MainViewCell.swift
//  HappyDays
//
//  Created by GERH on 6/17/17.
//  Copyright © 2017 GERH. All rights reserved.
//

import UIKit
import SnapKit

class MemoryCell: UICollectionViewCell {
    
    // MARK: - Cell Properties
    
    weak var delegate: MemoryCellDelegate?
    
    // MARK: - Interface Objects
    
    let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .lightGray
        iv.contentMode = .scaleAspectFill
        iv.layer.masksToBounds = true
        return iv
    }()
    
    // MARK: - View Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 3
        layer.cornerRadius = 10
        layer.masksToBounds = true
        setupLongPress()
        setupViews()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    fileprivate func setupViews() {
        addSubview(photoImageView)
        photoImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    fileprivate func setupLongPress() {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        recognizer.minimumPressDuration = 0.5
        addGestureRecognizer(recognizer)
    }
    
    // MARK: - Handle Methods
    
    func handleLongPress(sender: UILongPressGestureRecognizer) {
        delegate?.handleLongPress(sender: sender)
    }
}
