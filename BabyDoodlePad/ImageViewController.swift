//
//  ImageViewController.swift
//  BabyDoodlePad
//
//  Created by tai chen on 27/11/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var parentVC : AlbumCollectionViewController?
    var activityCV : UIActivityViewController?
    var imageToShow : UIImage?
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = imageToShow
        

    }

    @IBAction func closePressed(_ sender: UIButton) {
        print("dismiss")
        parentVC?.dismissModal()
    }
    
    @IBAction func sharePressed(_ sender: UIButton) {
        guard let image = imageToShow else { return }
        let items = [image]
        activityCV = UIActivityViewController(activityItems: items, applicationActivities:nil)
        activityCV?.popoverPresentationController?.sourceView = view
        present(activityCV!, animated: true, completion: nil)
    }
    

}
