//
//  DrawingViewController.swift
//  BabyDoodlePad
//
//  Created by tai chen on 22/11/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit

enum DrawMode {
    case standard
    case rainbow
    case sticker
}


class DrawingViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var brushStackWidth: NSLayoutConstraint!
    @IBOutlet weak var leftOptionsStackWidth: NSLayoutConstraint!
    
    var lastPoint = CGPoint(x: 0, y: 0)
    var currentColor = UIColor.white.cgColor
    var currentColorIndex = 0
    
    var drawMode = DrawMode.standard
    var currentSticker : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    
    // MARK: left panel buttons

    @IBAction func stickerOptionPressed(_ sender: UIButton) {
        drawMode = .sticker
        toggleLeftOptionsStack()
    }
    
    func toggleLeftOptionsStack() {
        leftOptionsStackWidth.constant = (leftOptionsStackWidth.constant == CGFloat(0)) ? 80 : 0
    }
    
    @IBAction func leftOptionPressed(_ sender: UIButton) {
        currentSticker = sender.tag
    }
    
    @IBAction func saveOptionPressed(_ sender: UIButton) {
        print("save image...")
        if let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
            let picture = Picture(context: context)
            picture.name = "Doodle"
            if let image = imageView.image {
                print("saving...")
                picture.image = UIImageJPEGRepresentation(image, 1)
                (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
            }
             
        }
    }
    
    @IBAction func deleteOptionPressed(_ sender: UIButton) {
        imageView.image = nil
    }
    
    // MARK: right panel buttons
    
    @IBAction func brushOptionsPressed(_ sender: UIButton) {
        drawMode = .standard
    //    toggleBrushPanel()
    }

    func toggleBrushPanel() {
        brushStackWidth.constant = (brushStackWidth.constant == CGFloat(0)) ? 80 : 0
    }
    
    @IBAction func colorPressed(_ sender: UIButton) {
        currentColorIndex = sender.tag
        currentColor = Palette.colors[currentColorIndex].cgColor
        drawMode = .standard
    }
    @IBAction func rainbowPressed(_ sender: UIButton) {
        drawMode = .rainbow
    }
    
  
    // MARK: touch events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let beginPoint = touches.first?.location(in: imageView) else { return }
        lastPoint = beginPoint
        leftOptionsStackWidth.constant = 0
        brushStackWidth.constant = 0
        
        switch drawMode {
        case .sticker:
            animateSticker(p1: lastPoint)
            placeSticker(p1: lastPoint)
        case .rainbow:
            colorChangedAt = beginPoint
        default:
            break
        }
        
 
        
    }
    
    var colorChangedAt = CGPoint.zero
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let movedPoint = touches.first?.location(in: imageView) else { return }
        
        switch drawMode {
        case .standard:
            drawLine(p1: lastPoint, p2: movedPoint)
        case .rainbow:
            if distanceBetween(p1: colorChangedAt, p2: movedPoint) > 50 {
                currentColorIndex += 1
                currentColor = Palette.colors[currentColorIndex % 5].cgColor
                colorChangedAt = movedPoint
            }
            drawLine(p1: lastPoint, p2: movedPoint)
        default: // sticker
            break
            
        }
                
        lastPoint = movedPoint
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let endPoint = touches.first?.location(in: imageView) else { return }
        
    }
    
    func distanceBetween(p1: CGPoint, p2: CGPoint) -> Float {
        return Float(abs(p2.x - p1.x)) + Float(abs(p2.y - p1.y))
    }

    
    // MARK: draw
    
    func drawLine(p1: CGPoint, p2: CGPoint) {
        UIGraphicsBeginImageContext(imageView.frame.size)
        imageView.image?.draw(in: CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height))
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.move(to: p1)
        context.addLine(to: p2)
        context.setLineWidth(10)
        context.setLineCap(.round)
        context.setStrokeColor(currentColor)
        context.strokePath()
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    // MARK: sticker
    func placeSticker(p1: CGPoint) {
        let size = CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height)
        UIGraphicsBeginImageContext(size)
        imageView.image?.draw(in: CGRect(origin: CGPoint.zero, size: size))
        UIImage(named: "sticker01.png")!.draw(in: CGRect(origin: CGPoint(x: p1.x-32, y: p1.y-32), size: CGSize(width: 64, height: 64)))
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func animateSticker(p1: CGPoint) {
        let image = UIImage(named: "sticker01.png")!
        let imageView = UIImageView(image: image)
        let startSize : CGFloat = 100
        let endSize : CGFloat = 64
        imageView.frame = CGRect(origin: CGPoint(x: p1.x-50, y: p1.y-50), size: CGSize(width: startSize, height: startSize))
        self.imageView.addSubview(imageView)

        UIView.animate(withDuration: 0.13, animations: {
            imageView.frame.size.width = 64
            imageView.frame.size.height = 64
            imageView.frame.origin.x += (startSize-endSize)/2
            imageView.frame.origin.y += (startSize-endSize)/2
        }) { (complete) in
            imageView.removeFromSuperview()
        }
        
        
        
    }

}
