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
    let manager = MemoriesManager()
    var memories = [URL]()
    var filteredMemories = [URL]()
    var activeMemory: URL!
    var audioRecorder: AVAudioRecorder?
    var recordingURL: URL!
    var audioPlayer: AVAudioPlayer?
    var searchQuery: CSSearchQuery?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        recordingURL = manager.getDocumentsDirectory().appendingPathComponent("recording"+File.m4a.fileExtension)
        setupNavBar()
        collectionView?.backgroundColor = .darkGray
        collectionView?.keyboardDismissMode = .onDrag
        registerCells()
        loadMemories()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
    }
    
    // MARK: - Setup Methods
    
    fileprivate func registerCells() {
        collectionView?.register(MemoryCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.register(MemoriesViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerId)
    }
    fileprivate func setupNavBar() {
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

// MARK: - Memory Methods

extension MemoriesViewController {
    
    // MARK: - Image Methods
    // behaves as a refresh
    func loadMemories() {
        memories.removeAll()
        // attempt to load all the memories in our documents directory
        guard let files = try? FileManager.default.contentsOfDirectory(at: manager.getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else { return }
        for file in files {
            // name of the component, e.g. url/     swag.thumb
            let filename = file.lastPathComponent
            if filename.hasSuffix(File.thumb.fileExtension) {
                // get the root name of the memory, withouth its path extension
                let noExtension = filename.replacingOccurrences(of: File.thumb.fileExtension, with: "")
                // create a full path from the memory
                let memoryPath = manager.getDocumentsDirectory().appendingPathComponent(noExtension)
                memories.insert(memoryPath, at: 0)
            }
        }
        filteredMemories = memories
        collectionView?.reloadSections(IndexSet(integer: 1))
    }
    func saveNewMemory(image: UIImage) {
        manager.saveNewMemory(image: image)
    }
    
    
    // MARK: - Audio Methods
    
    func startRecording() {
        audioPlayer?.stop()
        // 1. Set the background color to red to let the user know record starts
        collectionView?.backgroundColor = UIColor(r: 127.5, g: 0, b: 0)
        let session = AVAudioSession.sharedInstance()
        do {
            // 2. Configure the app for playing and recording audio
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            try session.setActive(true)
            // 3. Set up a recording session using high-quality AAC recording
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 44100, AVNumberOfChannelsKey: 2, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            // 4. create an AVAudioRecorder instance pointing at recorindURL
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch let error {
            print("Failed to record: ", error)
            stopRecording(success: false)
        }
    }
    func stopRecording(success: Bool) {
        // 1. dark gray background to let the user know record stopped
        collectionView?.backgroundColor = .darkGray
        // 2. stop audio recorder
        audioRecorder?.stop()
        if success {
            do {
                // 3. Create the url file
                let memoryAudioURL = activeMemory.appendingPathExtension(File.m4a.rawValue)
                let fm = FileManager.default
                // 4. Delete previous recording if it exists
                if fm.fileExists(atPath: memoryAudioURL.path) {
                    try fm.removeItem(at: memoryAudioURL)
                }
                // 5. Move the new audio to the url
                try fm.moveItem(at: recordingURL, to: memoryAudioURL)
                // 6. Start the transcription process
                transcribeAudio(memory: activeMemory)
            } catch let error {
                print("Failed to finish the recording: ", error)
            }
        }
    }
    
    
    // MARK: - TextTranscription Methods
    
    fileprivate func transcribeAudio(memory: URL) {
        // 1. get paths to where the audio is, and where the transcription should be
        let audio = manager.getMemoryURL(for: memory, type: .m4a)
        let transcription = manager.getMemoryURL(for: memory, type: .txt)
        // 2. create a new recognizer and point it at our audio
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audio)
        // 3. start the recognition
        recognizer?.recognitionTask(with: request, resultHandler: { [unowned self](result, error) in
            if let err = error {
                print("Failed to start audio recognition: ", err)
                return
            }
            // 4. write the transcription to disk
            guard let result = result else { print("Failed to start audio recognition"); return }
            if result.isFinal {
                // pull out the best transcription
                let text = result.bestTranscription.formattedString
                // write to disk
                do {
                    try text.write(to: transcription, atomically: true, encoding: .utf8)
                    print(text)
                    self.indexMemory(memory: memory, text: text)
                } catch let error {
                    print("Failed to save transcription on disk: ", error)
                }
            }
        })
    }
    
    // MARK: - Search Methods
    
    fileprivate func indexMemory(memory: URL, text: String) {
        // create a basic attribute set 
        // attributes to be set to the searchable item
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = "Happy Days Memory"
        attributeSet.contentDescription = text
        attributeSet.thumbnailURL = manager.getMemoryURL(for: memory, type: .thumb)
        // searchable item, using the memory path
        let item = CSSearchableItem(uniqueIdentifier: memory.path, domainIdentifier: "com.gerh", attributeSet: attributeSet)
        // never expire
        item.expirationDate = Date.distantFuture
        // ask Spotlight to index the item
        CSSearchableIndex.default().indexSearchableItems([item]) { (error) in
            if let err = error {
                print("Failed while trying to index: ", err)
            } else {
                print("Succesfully indexed search item: ", text)
            }
        }
    }
}

// MARK: - CollectionView Methods

extension MemoriesViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
     }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? 0 : filteredMemories.count
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MemoryCell
        let memory = filteredMemories[indexPath.item]
        let imageName = manager.getMemoryURL(for: memory, type: .thumb).path
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
        let memory = filteredMemories[indexPath.item]
        let fm = FileManager.default
        do {
            let audioName = manager.getMemoryURL(for: memory, type: .m4a)
            let transcriptionName = manager.getMemoryURL(for: memory, type: .txt)
            if fm.fileExists(atPath: audioName.path) {
                audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                audioPlayer?.play()
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
