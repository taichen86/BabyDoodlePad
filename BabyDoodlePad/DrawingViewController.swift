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
        createStarsEmitter()
        createConfettiEmitter()
        
    }


    // MARK: left panel buttons
    @IBAction func newOptionPressed(_ sender: UIButton) {
        imageView.image = nil
        closeStickerPanel()
        closeEffectPanel()
    }
    
    @IBAction func stickerOptionPressed(_ sender: UIButton) {
        closeEffectPanel()
        drawMode = .sticker
        toggleLeftOptionsStack()
    }
    
    @IBAction func effectsOptionPressed(_ sender: UIButton) {
        closeStickerPanel()
        drawMode = .particles
        toggleEffectsStack()
    }
    
    func closeStickerPanel() {
        UIView.animate(withDuration: 0.06) {
            self.leftOptionsStackWidth.constant =  0
            self.view.layoutIfNeeded()
        }
    }
    
    func closeEffectPanel() {
        UIView.animate(withDuration: 0.06) {
            self.effectsStackWidth.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func toggleLeftOptionsStack() {
        UIView.animate(withDuration: 0.06) {
            self.leftOptionsStackWidth.constant = (self.leftOptionsStackWidth.constant == CGFloat(0)) ? 120 : 0
            self.view.layoutIfNeeded()
        }

    }
    
    func toggleEffectsStack() {
        UIView.animate(withDuration: 0.06) {
            self.effectsStackWidth.constant = (self.effectsStackWidth.constant == CGFloat(0)) ? 120 : 0
            self.view.layoutIfNeeded()
        }
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
        closeStickerPanel()
        closeEffectPanel()
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
    
    @IBAction func eraserPressed(_ sender: UIButton) {
        closeStickerPanel()
        closeEffectPanel()
        drawMode = .standard
        currentColorIndex = 0
        currentColor = UIColor.white.cgColor
    }
    
    @IBAction func brushOptionsPressed(_ sender: UIButton) {
        closeStickerPanel()
        closeEffectPanel()
        drawMode = .standard
    }

    @IBAction func colorPressed(_ sender: UIButton) {
        closeStickerPanel()
        closeEffectPanel()
        currentColorIndex = sender.tag
        currentColor = Palette.colors[currentColorIndex-1].cgColor
        drawMode = .standard
    }
    
    @IBAction func rainbowPressed(_ sender: UIButton) {
        closeStickerPanel()
        closeEffectPanel()
        drawMode = .rainbow
        currentColor = UIColor.white.cgColor
        effectType = 10
    }
 
    
    // MARK: touch events
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let beginPoint = touches.first?.location(in: imageView) else { return }
        closeStickerPanel()
        closeEffectPanel()
        
        lastPoint = beginPoint
        leftOptionsStackWidth.constant = 0
  //      brushStackWidth.constant = 0
        
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
            let dist = distanceBetween(p1: colorChangedAt, p2: movedPoint)
            if  dist > 50 {
                createStarBurstEmitter(point: movedPoint)
                currentColorIndex += 1
                currentColor = Palette.colors[currentColorIndex % 5].cgColor
                colorChangedAt = movedPoint
            }

            drawLine(p1: lastPoint, p2: movedPoint)
        default:
            break
            
        }
        
        lastPoint = movedPoint
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let endPoint = touches.first?.location(in: imageView) else { return }
        // rainbow pen show animation
        if drawMode == .rainbow {
            createStarBurstEmitter(point: endPoint)
        }
        
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
   //     UIGraphicsBeginImageContextWithOptions(imageView.frame.size, false, 0.0)
        imageView.image?.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let image = UIImage(named: stickerName)!
        image.draw(in: CGRect(origin: CGPoint(x: p1.x-image.size.width/2, y: p1.y-image.size.height/2), size: image.size))
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func animateSticker(p1: CGPoint , _ stickerName: String) {
        let image = UIImage(named: stickerName)!
        let imageView = UIImageView(image: image)
        let startSize = CGSize(width: image.size.width*1.6, height: image.size.height*1.6)
        let endSize : CGSize = image.size
        imageView.frame = CGRect(origin: CGPoint(x: p1.x-startSize.width/2, y: p1.y-startSize.height/2), size: startSize)
        self.imageView.addSubview(imageView)

        UIView.animate(withDuration: 0.13, animations: {
            imageView.frame.size = endSize
            imageView.frame.origin.x += (startSize.width-endSize.width)/2
            imageView.frame.origin.y += (startSize.height-endSize.height)/2
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
        case 3:
            starsTimeRemaining = 2
            if starsEffectRunning { break }
            starsEffectRunning = true
            createStarsTimer()
            starsEmitter.birthRate = 2
        case 4:
            confettiTimeRemaining = 2
            if confettiEffectRunning { break }
            confettiEffectRunning = true
            createConfettiTimer()
            confettiEmitter.birthRate = 3
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
        snowEmitter.emitterShape = kCAEmitterLayerLine
        starsEmitter.position = CGPoint(x: imageView.frame.width, y: -20)
        snowEmitter.birthRate = 0
        snowEmitter.beginTime = CACurrentMediaTime()
        let cell = CAEmitterCell()
        cell.scale = 0.2
        cell.scaleRange = 0.5
        cell.birthRate = 3
        cell.lifetime = 10
        cell.velocity = 120
        cell.alphaSpeed = -1.0/cell.lifetime
        cell.emissionLongitude = CGFloat.pi/1.3
        cell.emissionRange = CGFloat.pi/3
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
        bubbleEmitter.position = CGPoint(x: imageView.frame.width, y: imageView.frame.height+40)
        bubbleEmitter.emitterSize = CGSize(width: imageView.frame.width, height: 1)
        bubbleEmitter.birthRate = 0
        bubbleEmitter.beginTime = CACurrentMediaTime()
        var cells = [CAEmitterCell]()
        for index in 1...4 {
            let cell = CAEmitterCell()
            cell.scale = 1.0
            cell.birthRate = 2
            cell.lifetime = 3
            cell.velocity = 100
            cell.alphaSpeed = -1.0/cell.lifetime
            cell.emissionRange = CGFloat.pi/4
            cell.contents = UIImage(named: "bubble\(index).png")!.cgImage
            cells.append(cell)
        }
        bubbleEmitter.emitterCells = cells
        imageView.layer.addSublayer(bubbleEmitter)
    }
    
    // ------- STARS --------------------------
    var starsTimeRemaining : Float = 0
    var starsEffectRunning = false
    var starsTimer = Timer()
    func createStarsTimer() {
        starsTimer = Timer.scheduledTimer(timeInterval: 1.1, target: self, selector: #selector(runStarsTimer), userInfo: nil, repeats: true)
    }
    @objc func runStarsTimer() {
        starsTimeRemaining -= 1
        if starsTimeRemaining < 0 {
            starsEmitter.birthRate = 0
            starsTimer.invalidate()
            starsEffectRunning = false
        }
    }
    var starsEmitter = CAEmitterLayer()
    func createStarsEmitter() {
        starsEmitter.emitterShape = kCAEmitterLayerLine
        starsEmitter.position = CGPoint(x: imageView.frame.width, y: -2)
        starsEmitter.emitterSize = CGSize(width: imageView.frame.width*2, height: 1)
        starsEmitter.birthRate = 0
        starsEmitter.beginTime = CACurrentMediaTime()
        var cells = [CAEmitterCell]()
        for index in 1...5 {
            let cell = CAEmitterCell()
            cell.scale = 0.2
            cell.birthRate = 1
            cell.lifetime = 7
            cell.alphaSpeed = -1.0/cell.lifetime
            cell.velocity = 40
            cell.alphaRange = 0.5
            cell.emissionLongitude = CGFloat.pi
            cell.emissionRange = CGFloat.pi/4
            cell.contents = UIImage(named: "star\(index).png")!.cgImage
            cells.append(cell)
        }

        starsEmitter.emitterCells = cells
        imageView.layer.addSublayer(starsEmitter)
    }

    // ------- CONFETTI --------------------------
    var confettiTimeRemaining : Float = 0
    var confettiEffectRunning = false
    var confettiTimer = Timer()
    func createConfettiTimer() {
        confettiTimer = Timer.scheduledTimer(timeInterval: 1.1, target: self, selector: #selector(runConfettiTimer), userInfo: nil, repeats: true)
    }
    @objc func runConfettiTimer() {
        confettiTimeRemaining -= 1
        if confettiTimeRemaining < 0 {
            confettiEmitter.birthRate = 0
            confettiTimer.invalidate()
            confettiEffectRunning = false
        }
    }
    var confettiEmitter = CAEmitterLayer()
    func createConfettiEmitter() {
        confettiEmitter.emitterShape = kCAEmitterLayerLine
        confettiEmitter.position = CGPoint(x: imageView.frame.width, y: -10)
        confettiEmitter.emitterSize = CGSize(width: imageView.frame.width*2, height: 1)
        confettiEmitter.birthRate = 0
        confettiEmitter.beginTime = CACurrentMediaTime()
        var cells = [CAEmitterCell]()
        for index in 1...5 {
            let cell = CAEmitterCell()
            cell.scale = 0.3
            cell.birthRate = 4
            cell.lifetime = 3
            cell.velocity = 180
            cell.scaleRange = 0.2
            cell.emissionLongitude = CGFloat.pi
            cell.emissionRange = CGFloat.pi/4
            cell.contents = UIImage(named: "confetti\(index).png")!.cgImage
            cells.append(cell)
        }
        
        confettiEmitter.emitterCells = cells
        imageView.layer.addSublayer(confettiEmitter)
    }
    
    // ------- PEN STARS --------------------------
    func createStarBurstEmitter(point: CGPoint) {
        let starBurstEmitter = CAEmitterLayer()
        starBurstEmitter.position = point
        starBurstEmitter.birthRate = 6
        starBurstEmitter.beginTime = CACurrentMediaTime()
            let cell = CAEmitterCell()
            cell.scale = 0.5
            cell.birthRate = 1
            cell.lifetime = 0.6
            cell.lifetimeRange = 1.0
            cell.velocity = 260
            cell.velocityRange = 100
            cell.emissionLongitude = CGFloat.pi
            cell.emissionRange = CGFloat.pi
            cell.contents = UIImage(named: "effect3.png")!.cgImage
        
        starBurstEmitter.emitterCells = [cell]
        imageView.layer.addSublayer(starBurstEmitter)
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.63) {
            starBurstEmitter.removeFromSuperlayer()
        }
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
