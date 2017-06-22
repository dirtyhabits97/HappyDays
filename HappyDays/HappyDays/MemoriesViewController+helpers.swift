//
//  MemoriesViewController+helpers.swift
//  HappyDays
//
//  Created by Gonzalo Reyes Huertas on 6/21/17.
//  Copyright © 2017 GERH. All rights reserved.
//

import UIKit
import CoreSpotlight

// MARK: - FlowLayoutDelegate Methods

extension MemoriesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return section == 1 ? CGSize.zero : CGSize(width: view.frame.width, height: 50)
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

// MARK: - MemoryCellDelegate Methods

extension MemoriesViewController: MemoryCellDelegate {
    func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let cell = sender.view as! MemoryCell
            if let index = collectionView?.indexPath(for: cell) {
                memoryManager.activeMemory = memoryManager.filteredMemories[index.item]
                startRecording()
            }
        } else if sender.state == .ended {
            stopRecording(success: true)
        }
    }
}

// MARK: - SearchBarDelegate Methods

extension MemoriesViewController: UISearchBarDelegate {
    func filterMemories(text: String) {
        var allItems = [CSSearchableItem]()
        if text.isEmpty {
            memoryManager.filteredMemories = memoryManager.memories
            UIView.performWithoutAnimation {
                collectionView?.reloadSections(IndexSet(integer: 1))
            }
            return
        }
        let queryString = "contentDescription == \"*\(text)*\"c"
        searchQuery = CSSearchQuery(queryString: queryString, attributes: nil)
        searchQuery?.foundItemsHandler = { items in
            allItems.append(contentsOf: items)
        }
        searchQuery?.completionHandler = { error in
            DispatchQueue.main.async { [unowned self] in
                self.activateFilter(matches: allItems)
            }
        }
        searchQuery?.start()
    }
    func activateFilter(matches: [CSSearchableItem]) {
        memoryManager.filteredMemories = matches.map { item in
            return Memory(directory: memoryManager.getDocumentsDirectory().appendingPathComponent(item.uniqueIdentifier), name: item.uniqueIdentifier)
        }
        UIView.performWithoutAnimation {
            collectionView?.reloadSections(IndexSet(integer: 1))
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterMemories(text: searchText)
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
