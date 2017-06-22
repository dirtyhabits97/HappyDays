//
//  MemoriesManager.swift
//  HappyDays
//
//  Created by Gonzalo Reyes Huertas on 6/21/17.
//  Copyright © 2017 GERH. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech
import CoreSpotlight

import MobileCoreServices

class MemoriesManager {
    
    // MARK: - Properties
    weak var delegate: MemoriesManagerDelegate?
    var activeMemory: Memory!
    var recordingURL: URL!
    var memories = [Memory]()
    var filteredMemories = [Memory]()
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    
    init() {
        self.recordingURL = getDocumentsDirectory().appendingPathComponent("recording"+File.m4a.fileExtension)
    }
    
    // MARK: - GetURL Methods
    
    func getMemoryURL(for memory: Memory, type: File) -> URL {
        return memory.directory.appendingPathExtension(type.rawValue)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    // MARK: - Memory Methods
    
    func loadMemories() {
        memories.removeAll()
        let directory = getDocumentsDirectory()
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: []) else { return }
        for file in files {
            // name of the component, e.g. url/     swag.thumb
            let filename = file.lastPathComponent
            if filename.hasSuffix(File.thumb.fileExtension) {
                // get the root name of the memory, withouth its path extension
                let noExtension = filename.replacingOccurrences(of: File.thumb.fileExtension, with: "")
                // create a full path from the memory
                let memoryPath = directory.appendingPathComponent(noExtension)
                let memory = Memory(directory: memoryPath, name: noExtension)
                memories.insert(memory, at: 0)
            }
        }
        filteredMemories = memories
    }
    
    func saveNewMemory(image: UIImage) {
        // create a unique name for this memory based on time so it's ez to sort
        let name = "memory-\(Date().timeIntervalSince1970)"
        let imageName = name + File.jpg.fileExtension
        let thumbnailName = name + File.thumb.fileExtension
        do {
            let directory = getDocumentsDirectory()
            // create url with the names created
            let imagePath = directory.appendingPathComponent(imageName)
            // convert the UIImage into a JPEG data object
            if let imageJPEGData = UIImageJPEGRepresentation(image, 80) {
                // write that data to the url created
                try imageJPEGData.write(to: imagePath, options: [.atomic])
            }
            
            if let thumbnail = image.resize(to: 200) {
                let thumbnailPath = directory.appendingPathComponent(thumbnailName)
                if let thumbnailJPEGData = UIImageJPEGRepresentation(thumbnail, 80) {
                    try thumbnailJPEGData.write(to: thumbnailPath, options: [.atomic])
                }
            }
        } catch {
            print("Failed to save new memory")
        }
    }
    
    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            // 2. Configure the app for playing and recording audio
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            try session.setActive(true)
            // 3. Set up a recording session using high-quality AAC recording
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 44100, AVNumberOfChannelsKey: 2, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            // 4. create an AVAudioRecorder instance pointing at recorindURL
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = delegate
            audioRecorder?.record()
        } catch let error {
            print("Failed to record: ", error)
            stopRecording(success: false)
        }
    }
    
    func stopRecording(success: Bool) {
        // 2. stop audio recorder
        audioRecorder?.stop()
        if success {
            do {
                // 3. Create the url file
                let memoryAudioURL = activeMemory.directory.appendingPathExtension(File.m4a.rawValue)
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
    
    func transcribeAudio(memory: Memory) {
        // 1. get paths to where the audio is, and where the transcription should be
        let audio = getMemoryURL(for: memory, type: .m4a)
        let transcription = getMemoryURL(for: memory, type: .txt)
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
    
    func indexMemory(memory: Memory, text: String) {
        // create a basic attribute set
        // attributes to be set to the searchable item
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = "Happy Days Memory"
        attributeSet.contentDescription = text
        attributeSet.thumbnailURL = getMemoryURL(for: memory, type: .thumb)
        // searchable item, using the memory path
        let item = CSSearchableItem(uniqueIdentifier: memory.name, domainIdentifier: "com.gerh", attributeSet: attributeSet)
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
