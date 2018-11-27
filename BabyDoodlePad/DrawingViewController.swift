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
    case particles
}


class DrawingViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var brushStackWidth: NSLayoutConstraint!
    @IBOutlet weak var leftOptionsStackWidth: NSLayoutConstraint!
    @IBOutlet weak var effectsStackWidth: NSLayoutConstraint!
    
    var lastPoint = CGPoint(x: 0, y: 0)
    var currentColor = UIColor.white.cgColor
    var currentColorIndex = 0
    
    var drawMode = DrawMode.standard
    var currentLeftOption : Int = 1 // stickers , effects
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Audio.playAudioFile("bgtrack")

        createSnowEmitter()
        createBubbleEmitter()
        
    }


    // MARK: left panel buttons
    @IBAction func newOptionPressed(_ sender: UIButton) {
        imageView.image = nil
    }
    
    @IBAction func stickerOptionPressed(_ sender: UIButton) {
        drawMode = .sticker
        toggleLeftOptionsStack()
    }
    
    @IBAction func effectsOptionPressed(_ sender: UIButton) {
        drawMode = .particles
     toggleEffectsStack()
    }
    

    func toggleLeftOptionsStack() {
        leftOptionsStackWidth.constant = (leftOptionsStackWidth.constant == CGFloat(0)) ? 120 : 0
    }
    
    func toggleEffectsStack() {
        effectsStackWidth.constant = (effectsStackWidth.constant == CGFloat(0)) ? 120 : 0
    }
    
    @IBAction func leftOptionPressed(_ sender: UIButton) {
        currentLeftOption = sender.tag
    }
    
    var effectType = 0 // 1 - snow , 2 - bubbles
    @IBAction func effectSelected(_ sender: UIButton) {
        effectType = sender.tag
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
                performSegue(withIdentifier: "goToAlbum", sender: self)
            }
        }
    }
    
    @IBAction func photoOptionPressed(_ sender: UIButton) {
        importPhoto()
    }
    
    

    // MARK: right panel buttons
    @IBAction func brushOptionsPressed(_ sender: UIButton) {
        drawMode = .standard
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
            animateSticker(p1: lastPoint, "sticker\(currentLeftOption).png")
            placeSticker(p1: lastPoint, "sticker\(currentLeftOption).png")
        case .rainbow:
            colorChangedAt = beginPoint
        case .particles:
            animateSticker(p1: lastPoint, "effect\(effectType).png")
            placeSticker(p1: lastPoint, "effect\(effectType).png")
            doEffect()
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
    func placeSticker(p1: CGPoint , _ stickerName : String) {
        let size = CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height)
        UIGraphicsBeginImageContext(size)
        imageView.image?.draw(in: CGRect(origin: CGPoint.zero, size: size))
        UIImage(named: stickerName)!.draw(in: CGRect(origin: CGPoint(x: p1.x-32, y: p1.y-32), size: CGSize(width: 64, height: 64)))
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func animateSticker(p1: CGPoint , _ stickerName: String) {
        let image = UIImage(named: stickerName)!
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
    
    // MARK: particles
    
    func doEffect() {
    //    print("do effect \(effectType)")
        switch effectType{
        case 1:
            snowTimeRemaining = 2
            if snowEffectRunning { break }
            snowEffectRunning = true
            createSnowTimer()
            snowEmitter.birthRate = 1
        case 2:
            bubbleTimeRemaining = 2
            if bubbleEffectRunning { break }
            bubbleEffectRunning = true
            createBubbleTimer()
            bubbleEmitter.birthRate = 1
        default:
            break
        }
        
    }
    
    
    

    
    
    // ------- SNOW --------------------------
    var snowTimeRemaining : Float = 0
    var snowEffectRunning = false

    var snowTimer = Timer()
    func createSnowTimer() {
        snowTimer = Timer.scheduledTimer(timeInterval: 0.9, target: self, selector: #selector(runSnowTimer), userInfo: nil, repeats: true)
    }
    @objc func runSnowTimer() {
        snowTimeRemaining -= 1
        if snowTimeRemaining < 0 {
            snowEmitter.birthRate = 0
            snowTimer.invalidate()
            snowEffectRunning = false
        }
    }
    
    var snowEmitter = CAEmitterLayer()
    func createSnowEmitter() {
        snowEmitter.emitterShape = kCAEmitterLayerRectangle
        snowEmitter.position = CGPoint(x: imageView.frame.width/2, y: -50)
        snowEmitter.emitterSize = CGSize(width: imageView.frame.width, height: 10)
        snowEmitter.birthRate = 0
        let cell = CAEmitterCell()
        cell.scale = 0.2
        cell.birthRate = 2
        cell.lifetime = 10
        cell.velocity = 170
        cell.alphaRange = 0.5
        cell.emissionLongitude = CGFloat.pi/2
        cell.emissionRange = CGFloat.pi / 3
        cell.contents = UIImage(named: "effect1.png")!.cgImage
        snowEmitter.emitterCells = [cell]
        imageView.layer.addSublayer(snowEmitter)
    }
    
    // ------- BUBBLES --------------------------
    var bubbleTimeRemaining : Float = 0
    var bubbleEffectRunning = false
    var bubbleTimer = Timer()
    func createBubbleTimer() {
        bubbleTimer = Timer.scheduledTimer(timeInterval: 1.1, target: self, selector: #selector(runBubbleTimer), userInfo: nil, repeats: true)
    }
    @objc func runBubbleTimer() {
        bubbleTimeRemaining -= 1
        if bubbleTimeRemaining < 0 {
            bubbleEmitter.birthRate = 0
            bubbleTimer.invalidate()
            bubbleEffectRunning = false
        }
    }
    var bubbleEmitter = CAEmitterLayer()
    func createBubbleEmitter() {
        bubbleEmitter.emitterShape = kCAEmitterLayerLine
        bubbleEmitter.position = CGPoint(x: imageView.frame.width/2, y: imageView.frame.height+50)
        bubbleEmitter.emitterSize = CGSize(width: imageView.frame.width, height: 10)
        bubbleEmitter.birthRate = 0
        let cell = CAEmitterCell()
        cell.scale = 0.2
        cell.birthRate = 1
        cell.lifetime = 3
        cell.velocity = 100
        cell.alphaRange = 0.5
        cell.emissionLongitude = CGFloat.pi/2*3
        cell.emissionRange = CGFloat.pi / 4
        cell.contents = UIImage(named: "effect2.png")!.cgImage
        bubbleEmitter.emitterCells = [cell]
        imageView.layer.addSublayer(bubbleEmitter)
    }


}


extension DrawingViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func importPhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil )
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let photo = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = photo // TODO: crop to fit
        }
        dismiss(animated: true, completion: nil)
    }
    
    
}
