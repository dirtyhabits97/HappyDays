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
import CoreSpotlight
import MobileCoreServices

class MemoriesViewController: UICollectionViewController {
    
    // MARK: - ViewController Properties
    fileprivate let cellId = "cellId"
    fileprivate let headerId = "headerId"
    let memoryManager = MemoriesManager()
    var searchQuery: CSSearchQuery?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        memoryManager.delegate = self
        setupNavBar()
        setupCollectionView()
        loadMemories()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
    }
    
    // MARK: - Setup Methods
    
    fileprivate func setupNavBar() {
        navigationItem.title = "Memories"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddMemory))
    }
    
    fileprivate func setupCollectionView() {
        collectionView?.backgroundColor = .darkGray
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.register(MemoryCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.register(MemoriesViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerId)
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

// MARK: - Memory Methods

extension MemoriesViewController: MemoriesManagerDelegate {
    func loadMemories() {
        memoryManager.loadMemories()
        collectionView?.reloadSections(IndexSet(integer: 1))
    }
    func saveNewMemory(image: UIImage) {
        memoryManager.saveNewMemory(image: image)
    }
    
    func startRecording() {
        memoryManager.audioPlayer?.stop()
        collectionView?.backgroundColor = UIColor(r: 127.5, g: 0, b: 0)
        memoryManager.startRecording()
    }
    func stopRecording(success: Bool) {
        collectionView?.backgroundColor = .darkGray
        memoryManager.stopRecording(success: success)
    }
    
    fileprivate func transcribeAudio(memory: URL) {
        memoryManager.transcribeAudio(memory: memory)
    }
    
    fileprivate func indexMemory(memory: URL, text: String) {
        memoryManager.indexMemory(memory: memory, text: text)
    }
}

// MARK: - CollectionView Methods

extension MemoriesViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
     }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? 0 : memoryManager.filteredMemories.count
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MemoryCell
        let memory = memoryManager.filteredMemories[indexPath.item]
        let imageName = memoryManager.getMemoryURL(for: memory, type: .thumb).path
        let image = UIImage(contentsOfFile: imageName)
        cell.photoImageView.image = image
        cell.delegate = self
        return cell
    }
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! MemoriesViewHeader
        header.searchBar.delegate = self
        return header
    }
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let memory = memoryManager.filteredMemories[indexPath.item]
        let fm = FileManager.default
        do {
            let audioName = memoryManager.getMemoryURL(for: memory, type: .m4a)
            let transcriptionName = memoryManager.getMemoryURL(for: memory, type: .txt)
            if fm.fileExists(atPath: audioName.path) {
                memoryManager.audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                memoryManager.audioPlayer?.play()
            }
            if fm.fileExists(atPath: transcriptionName.path) {
                let contents = try String(contentsOf: transcriptionName)
                print(contents)
            }
        } catch {
            print("Failed to load audio")
        }
    }
}



// MARK: - AVAudioRecorderDelegate Methods

extension MemoriesViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopRecording(success: false)
        }
    }
}
