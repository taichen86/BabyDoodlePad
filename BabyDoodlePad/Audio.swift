//
//  Audio.swift
//  BabyDoodlePad
//
//  Created by tai chen on 27/11/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import Foundation
import AVFoundation

class Audio {
    
    static var player : AVAudioPlayer?
    
    static func playAudioFile(_ filename: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else { return }
        print("play audio .. \(filename)")
        
        player = try? AVAudioPlayer(contentsOf: url)
        player?.numberOfLoops = -1
        player?.play()
        
    }
    
    
}
