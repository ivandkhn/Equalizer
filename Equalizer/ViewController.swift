//
//  ViewController.swift
//  Equalizer
//
//  Created by Иван Дахненко on 26.12.2018.
//  Copyright © 2018 Ivan Dakhnenko. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    // MARK: -- UI elements:
    @IBOutlet weak var testButton: NSButton!
    
    
    // MARK: -- Model elements:
    var player: AudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func testButtonPressed(_ sender: NSButton) {
        //displayAlert(text: "button pressed")
        
        if let loadedPlayer = player {
            // loadedPlayer.logAmplitudes(first: 10)
            
            if (loadedPlayer.isPlaying) {
                loadedPlayer.isPlaying = false
            } else {
                loadedPlayer.initBeforePlaying()
                loadedPlayer.isPlaying = true
            }
        } else {
            player = AudioPlayer()
        }
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func displayAlert(text: String) {
        let alert = NSAlert.init()
        alert.messageText = "Alert"
        alert.informativeText = text
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

