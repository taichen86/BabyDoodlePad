//
//  ParentalGateViewController.swift
//  BabyDoodlePad
//
//  Created by tai chen on 30/11/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit

class ParentalGateViewController: UIViewController {

    var answer = [Int]()
    var parentVC : DrawingViewController?
    
    let numberText = ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE"]
    @IBOutlet weak var instructionLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
instructionLabel.text = "To continue, tap: \(numberText[answer[0]-1]) and \(numberText[answer[1]-1])"    }
    

    var count : Int =  0
    @IBAction func numberPressed(_ sender: UIButton) {
        if answer[count] == sender.tag {
            if count == 1 {
                parentVC?.closeParentalGate(success: true)
            }
        }else{
            parentVC?.closeParentalGate(success: false)
        }
        count += 1
    }
    
    @IBAction func closePressed(_ sender: UIButton) {
        parentVC?.closeParentalGate(success: false)
    }
    

    


}
