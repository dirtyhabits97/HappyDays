//
//  MainViewController.swift
//  HappyDays
//
//  Created by GERH on 6/17/17.
//  Copyright © 2017 GERH. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class MemoriesViewController: UICollectionViewController {
    
    
    // MARK: - Object Ids
    fileprivate let cellId = "cellId"
    fileprivate let headerId = "headerId"
    
    // MARK: - Object Variables
    var memories = [URL]()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        collectionView?.backgroundColor = .darkGray
        registerCells()
        loadMemories()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
    }
    
    // MARK: - Setup Methods
    
    fileprivate func registerCells() {
        collectionView?.register(MemoriesViewCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.register(MemoriesViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerId)
    }
    fileprivate func setupNavBar() {
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = .white
        navigationItem.title = "Memories"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddMemory))
    }
    fileprivate func checkPermissions() {
        let photosAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission() == .granted
        let transcribeAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        let isAuthorized = photosAuthorized && recordingAuthorized && transcribeAuthorized
        if !isAuthorized {
            let welcomeController = WelcomeController()
            present(welcomeController, animated: true)
        }
    }
    
    // MARK: - Handle Methods
    
    func handleAddMemory() {
        selectImage()
    }
}

// MARK: - Logic Methods

extension MemoriesViewController {
    enum MemoryType: String {
        case jpg, thumb, m4a, txt
        var fileExtension: String {
            switch self {
            case .jpg: return ".jpg"
            case .thumb: return ".thumb"
            case .m4a: return ".m4a"
            case .txt: return ".txt"
            }
        }
    }
    // behaves as a refresh
    fileprivate func loadMemories() {
        memories.removeAll()
        // attempt to load all the memories in our documents directory
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else { return }
        for file in files {
            // name of the component, e.g. url/     swag.thumb
            let filename = file.lastPathComponent
            if filename.hasSuffix(MemoryType.thumb.fileExtension) {
                // get the root name of the memory, withouth its path extension
                let noExtension = filename.replacingOccurrences(of: MemoryType.thumb.fileExtension, with: "")
                // create a full path from the memory
                let memoryPath = getDocumentsDirectory().appendingPathComponent(noExtension)
                memories.append(memoryPath)
            }
        }
        collectionView?.reloadSections(IndexSet(integer: 0))
    }
    fileprivate func saveNewMemory(image: UIImage) {
        // create a unique name for this memory based on time so it's ez to sort
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        let imageName = memoryName + MemoryType.jpg.fileExtension
        let thumbnailName = memoryName + MemoryType.thumb.fileExtension
        do {
            // create url with the names created
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            // convert the UIImage into a JPEG data object
            if let imageJPEGData = UIImageJPEGRepresentation(image, 80) {
                // write that data to the url created
                try imageJPEGData.write(to: imagePath, options: [.atomic])
            }
            
            if let thumbnail = image.resize(to: 200) {
                let thumbnailPath = getDocumentsDirectory().appendingPathComponent(thumbnailName)
                if let thumbnailJPEGData = UIImageJPEGRepresentation(thumbnail, 80) {
                    try thumbnailJPEGData.write(to: thumbnailPath, options: [.atomic])
                }
            }
        } catch {
            print("Failed to save new memory")
        }
    }
    fileprivate func getMemoryURL(for memory: URL, type: MemoryType) -> URL {
        return memory.appendingPathExtension(type.rawValue)
    }
    fileprivate func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}

// MARK: - CollectionView Methods

extension MemoriesViewController {
    /*override func numberOfSections(in collectionView: UICollectionView) -> Int {
     return 2
     } */
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return /*section == 0 ? 0 :*/ memories.count
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MemoriesViewCell
        let memory = memories[indexPath.item]
        let imageName = getMemoryURL(for: memory, type: .thumb).path
        let image = UIImage(contentsOfFile: imageName)
        cell.photoImageView.image = image
        return cell
    }
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! MemoriesViewHeader
        return header
    }
}

// MARK: - FlowLayoutDelegate Methods

extension MemoriesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 50)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 200, height: 200)
    }
    // for lines
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    // for cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
}

// MARK: - ImagePickerDelegate Methods

extension MemoriesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func selectImage() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.modalPresentationStyle = .formSheet
        imagePickerController.delegate = self
        present(imagePickerController, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            saveNewMemory(image: image)
            loadMemories()
        } else {
            print("ImagePicker: Something went wrong")
        }
        dismiss(animated: true)
    }
}
