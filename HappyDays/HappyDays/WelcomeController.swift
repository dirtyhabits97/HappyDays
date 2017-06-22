//
//  ViewController.swift
//  HappyDays
//
//  Created by GERH on 6/17/17.
//  Copyright © 2017 GERH. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech
import SnapKit

class WelcomeController: UIViewController {
    
    // MARK: - Interface Objects
    
    let welcomeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "In order to work fully, Happy Days needs to read your photo library, record your voice, and transcribe what you said. When you click the button below you will be asked to grant those permissions, but you can change your mind later in Settings"
        return label
    }()
    
    let permissionButton : UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 25)
        button.addTarget(self, action: #selector(handleContinue), for: .touchUpInside)
        return button
    }()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Welcome"
        view.backgroundColor = .white
        setupViews()
    }
    
    // MARK: - Setup Methods
    
    fileprivate func setupViews() {
        let stackView = UIStackView(arrangedSubviews: [welcomeLabel, permissionButton])
        stackView.axis = .vertical
        stackView.spacing = 50
        view.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.center.equalTo(self.view)
            make.width.equalTo(self.view).offset(-40)
        }
    }
    
    // MARK: - RequestPermission Methods
    
    fileprivate func requestPhotosPermission() {
        PHPhotoLibrary.requestAuthorization { [unowned self](authStatus) in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.requestRecordPermission()
                } else {
                    self.welcomeLabel.text = "Photos permission was declined; please enable it in settings then tap Continue again."
                }
            }
        }
    }
    fileprivate func requestRecordPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [unowned self] (allowed) in
            DispatchQueue.main.async {
                if allowed {
                    self.requestTranscribePermission()
                } else {
                    self.welcomeLabel.text = "Recording permission was declined; please enable it in settings then tap Continue again."
                }
            }
        }
    }
    fileprivate func requestTranscribePermission() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] (authStatus) in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.authorizationComplete()
                } else {
                    self.welcomeLabel.text = "Transcription permission was declined; please enable it in settings then tap Continue again."
                }
            }
        }
    }
    fileprivate func authorizationComplete() {
        let memoriesViewController = MemoriesViewController(collectionViewLayout: UICollectionViewFlowLayout())
        navigationController?.pushViewController(memoriesViewController, animated: true)
    }
    
    // MARK: - Handle Methods
    
    func handleContinue() {        
        requestPhotosPermission()
    }
}

