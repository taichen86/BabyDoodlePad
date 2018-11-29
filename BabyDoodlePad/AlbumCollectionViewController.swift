//
//  AlbumCollectionViewController.swift
//  BabyDoodlePad
//
//  Created by tai chen on 23/11/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit

private let reuseIdentifier = "AlbumCell"

class AlbumCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    var pictures : [Picture] = [] // TODO: reverse pictures
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getPictures()
       imageSelected = -1
    }

    func getPictures() {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else { return }
        if let result = try? context.fetch(Picture.fetchRequest()) as? [Picture] {
            if let pics = result {
                pictures = pics
                pictures = pictures.reversed()
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
    
    var imageSelected : Int = -1
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToImageView" {
            if let vc = segue.destination as? ImageViewController {
                print("image selected \(imageSelected)")
                let image = UIImage(data: pictures[imageSelected].image!)
                vc.imageToShow = image
                vc.parentVC = self
            }
        }
    }
    
    func dismissModal() {
       dismiss(animated: true, completion: nil)
    }

    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width/3-10, height: collectionView.frame.width/3-10)
    }
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
        cell.layer.borderWidth = 0
        cell.showOptions(false)
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("didSelectItem \(indexPath)")
        let cell = collectionView.cellForItem(at: indexPath) as! AlbumCell
        cell.layer.borderWidth = 14
        cell.layer.borderColor = Palette.colors[Int(arc4random_uniform(4))].cgColor
        cell.showOptions(true)
        // double tap
        if imageSelected == indexPath.row {
            performSegue(withIdentifier: "goToImageView", sender: self)
        }
        imageSelected = indexPath.row

    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! AlbumCell
        cell.layer.borderWidth = 0
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
