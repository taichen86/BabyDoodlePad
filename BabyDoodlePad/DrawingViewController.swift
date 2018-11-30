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
    @IBOutlet weak var brushButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    var lastPoint = CGPoint(x: 0, y: 0)
    var currentColor = Palette.colors[0].cgColor
    var currentColorIndex : Int = 1
    var penColorIndex : Int = 1
    var penIsRainbow = false
    
    var drawMode = DrawMode.standard
    var currentLeftOption : Int = 1 // stickers , effects
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        IAP.instance.iapDelegate = self
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white,
                                                                   NSAttributedStringKey.font : UIFont(name: "Chalkboard SE", size: 26)]
        createNewSheet()
        Audio.playAudioFile("bgtrack")
        prepareEmitters()
        setSaveButtonImage()
    }
    
    func prepareEmitters() {
        createSnowEmitter()
        createBubbleEmitter()
        createStarsEmitter()
        createConfettiEmitter()
    }
    
    func createNewSheet() {
        starsEmitter.birthRate = 0
        bubbleEmitter.birthRate = 0
        snowEmitter.birthRate = 0
        confettiEmitter.birthRate = 0
        let rect = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        Palette.defaultColor.setFill()
        UIRectFill(rect)
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func setSaveButtonImage() {
        if UserDefaults.standard.bool(forKey: "upgrade") == false {
            saveButton.setImage(UIImage(named: "save-bw.png"), for: .normal)
        }else{
            saveButton.setImage(UIImage(named: "save-yellow.png"), for: .normal)
        }
    }
    
    // MARK: In App Purchase
    func checkPremiumAccess() {
        if UserDefaults.standard.bool(forKey: "upgrade") == false {
            showParentalGate()
        }else{
            saveImage()
        }
    }
    
    func showParentalGate() {
        performSegue(withIdentifier: "goToParentalGate", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare \(segue)")
        if segue.identifier == "goToParentalGate" {
            if let vc = segue.destination as? ParentalGateViewController {
                vc.parentVC = self
                vc.answer = [Int(arc4random_uniform(9))+1, Int(arc4random_uniform(9))+1]
            }
        }
    }

    
    func closeParentalGate(success: Bool) {
        print("close parental gate")
        dismiss(animated: true, completion: nil)
        if success {
            let alert = UIAlertController(title: "unlock", message: "upgrade to save artwork?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "later", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "OK!", style: .default, handler: { (action) in
                print("purchase")
                IAP.instance.purchase()
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func restorePressed(_ sender: UIBarButtonItem) {
        IAP.instance.restorePurchases()
    }
    

    // MARK: left panel buttons
    @IBAction func newOptionPressed(_ sender: UIButton) {
        imageView.image = nil
        createNewSheet()
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
        closeStickerPanel()
        closeEffectPanel()
        checkPremiumAccess()
    }
    
    func saveImage() {
        print("save image...")
        if let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
            let picture = Picture(context: context)
            picture.name = "doodle"
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
        penWidth = 20
        drawMode = .standard
        currentColor = Palette.defaultColor.cgColor
    }
    
    @IBAction func brushOptionsPressed(_ sender: UIButton) {
        closeStickerPanel()
        closeEffectPanel()
        penWidth = 10
        if !penIsRainbow{
            drawMode = .standard
            currentColor = Palette.colors[penColorIndex-1].cgColor
        }else{
            drawMode = .rainbow
        }
    }
    

    @IBAction func rainbowPressed(_ sender: UIButton) {
        closeStickerPanel()
        closeEffectPanel()
        drawMode = .rainbow
        penWidth = 10
        effectType = 10
        brushButton.setImage(UIImage(named: "pen\(sender.tag).png"), for: .normal)
        penIsRainbow = true
    }

    @IBAction func colorPressed(_ sender: UIButton) {
        closeStickerPanel()
        closeEffectPanel()
        currentColorIndex = sender.tag
        penColorIndex = sender.tag
        currentColor = Palette.colors[currentColorIndex-1].cgColor
        drawMode = .standard
        penWidth = 10
        brushButton.setImage(UIImage(named: "pen\(sender.tag).png"), for: .normal)
        penIsRainbow = false
    }
    
    // MARK: touch events
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let beginPoint = touches.first?.location(in: imageView) else { return }
        closeStickerPanel()
        closeEffectPanel()
        
        lastPoint = beginPoint
        leftOptionsStackWidth.constant = 0
        
        switch drawMode {
        case .sticker:
            animateSticker(p1: lastPoint, "sticker\(currentLeftOption).png")
            placeSticker(p1: lastPoint, "sticker\(currentLeftOption).png")
            doCustomEffect(point: lastPoint)
        case .rainbow:
            colorChangedAt = beginPoint
            Audio.playSFX("chime")
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
    var penWidth : CGFloat = 10
    func drawLine(p1: CGPoint, p2: CGPoint) {
        UIGraphicsBeginImageContext(imageView.frame.size)
        imageView.image?.draw(in: CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height))
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.move(to: p1)
        context.addLine(to: p2)
        context.setLineWidth(penWidth)
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
    
    func doCustomEffect(point: CGPoint) {
        switch currentLeftOption {
        case 4: // heart
            createStarBurstEmitter(point: CGPoint(x: point.x+22, y: point.y-22))
        default:
            break
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
            snowEmitter.birthRate = 2
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
            cell.birthRate = 3
            cell.lifetime = 3
            cell.velocity = 100
            cell.velocityRange = 30
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
            cell.scale = 0.3
            cell.birthRate = 1
            cell.lifetime = 1.1
            cell.lifetimeRange = 1.0
            cell.velocity = 160
            cell.velocityRange = 50
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
            print(photo.size)
            if (photo.size.height > photo.size.width) && (view.frame.width > view.frame.height) {
                drawPortraitPhotoInLandscapeMode(photo: photo)
            }else if (photo.size.width > photo.size.height) && (view.frame.height > view.frame.width) {
                drawLandscapePhotoInPortraitMode(photo: photo)
            }else{
                drawPhotoInSameOrientation(photo: photo)
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    func drawPortraitPhotoInLandscapeMode(photo: UIImage) {
        print("drawPortraitPhotoInLandscapeMode")
        let canvasSize = CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height)
        UIGraphicsBeginImageContext(canvasSize)
  //      UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
 //       imageView.image?.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let height = canvasSize.height
        print(height)
        let ratio = photo.size.height/photo.size.width
        print(ratio)
        let width = height/ratio
        print(width)
        photo.draw(in: CGRect(origin: CGPoint(x: (canvasSize.width - width) / 2, y: 0), size: CGSize(width: width, height: height)))
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func drawLandscapePhotoInPortraitMode(photo: UIImage) {
        print("drawLandscapePhotoInPortraitMode")
        let canvasSize = CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height)
        UIGraphicsBeginImageContext(canvasSize)
        let width = canvasSize.width
        let ratio = photo.size.width/photo.size.height
        let height = width/ratio
        photo.draw(in: CGRect(origin: CGPoint(x: 0, y: (canvasSize.height - height)/2), size: CGSize(width: width, height: height)))
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func drawPhotoInSameOrientation(photo: UIImage) {
        print("drawPhotoInSameOrientation")
        let canvasSize = CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height)
        UIGraphicsBeginImageContext(canvasSize)
        var size = photo.size
        let ratio = photo.size.width/photo.size.height // landscape
        if view.frame.size.width > view.frame.size.height { // landscape
            size.height = canvasSize.height
            size.width = size.height*ratio
            print("landscape sizse \(size)")
        }else{ // portrait
            size.width = canvasSize.width
            size.height = size.width/ratio
        }
        let origin = CGPoint(x: (canvasSize.width-size.width)/2, y: (canvasSize.height - size.height)/2)
        print("origin \(origin)")
        photo.draw(in: CGRect(origin: origin, size: CGSize(width: size.width, height: size.height)))
        
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
}

extension DrawingViewController : IAPDelegate {
    func purchaseSuccess() {
        print("purchase success, update save button")
        setSaveButtonImage()
    }
    func restoreSuccess() {
        print("restore success, update save button")
        let alert = UIAlertController(title: "success", message: "your purchase has been successfully restored", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
        setSaveButtonImage()
    }
}


