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
    @IBOutlet weak var errorLabel: NSTextField!
    
    // MARK: -- Model elements:
    var player: AudioPlayer?
    var selectedFile: URL? = nil
    
    // MARK: -- Actions:
    @IBAction func openFileButtonAction(_ sender: NSButton) {
        if selectedFile == nil {
            selectedFile = selectFile()
        }
    }
    
    @IBAction func playButtonAction(_ sender: NSButton) {
        if let selectedFilename = selectedFile {
            errorLabel.stringValue = ""
            if let loadedPlayer = player {
                loadedPlayer.isPlaying = true
            } else {
                player = AudioPlayer(filename: selectedFilename)
                player?.initBeforePlaying()
                player?.isPlaying = true
            }
        } else {
            errorLabel.stringValue = "Open a file first"
        }
    }
    
    @IBAction func pauseButtonAction(_ sender: NSButton) {
        guard let loadedPlayer = player else {return}
        loadedPlayer.isPaused = !loadedPlayer.isPaused
    }
    
    @IBAction func stopButtonAction(_ sender: NSButton) {
        guard let loadedPlayer = player else {return}
        loadedPlayer.isPlaying = false
    }
    
    //MARK: -- Helper functions:
    
    func selectFile() -> URL? {
        let openDialog = NSOpenPanel();
        if (openDialog.runModal() == NSApplication.ModalResponse.OK) {
            return openDialog.url!
        } else {
            // We'll handle it in another buttons.
            return nil
        }
    }
    
    func displayAlert(text: String) {
        let alert = NSAlert.init()
        alert.messageText = "Alert"
        alert.informativeText = text
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    //MARK: -- Overriden functions:
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        errorLabel.stringValue = ""
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
}
