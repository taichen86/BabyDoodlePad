//
//  AlbumCollectionViewController.swift
//  BabyDoodlePad
//
//  Created by tai chen on 23/11/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit

private let reuseIdentifier = "AlbumCell"

class AlbumCollectionViewController: UICollectionViewController {

    var pictures : [Picture] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getPictures()
    }

    func getPictures() {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else { return }

        print("get pictures...")
        if let result = try? context.fetch(Picture.fetchRequest()) as? [Picture] {
            if let pics = result {
                print("reload pics")
                pictures = pics
                collectionView?.reloadData()
            }
        }
        
    }
    
    func deletePicture(_ index: Int) {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else { return }
        print("delete...")
        context.delete(pictures[index])
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        pictures.remove(at: index)
        collectionView?.reloadData()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return pictures.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumCell
        cell.parentView = self
        cell.index = indexPath.row
        let picture = pictures[indexPath.row]
        if let imageData = picture.image {
            cell.imageView.image = UIImage(data: imageData)
        }
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! AlbumCell
        cell.showOptions(true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! AlbumCell
        cell.showOptions(false)
    }

}

class AlbumCell : UICollectionViewCell
{
    
    var parentView : AlbumCollectionViewController?
    var index : Int = 0
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    var picture = Picture()
    @IBAction func deletePressed(_ sender: UIButton) {
        parentView?.deletePicture(index)
    }
    
    func showOptions(_ stat:Bool) {
        deleteButton.isHidden = !stat
    }
    
}
