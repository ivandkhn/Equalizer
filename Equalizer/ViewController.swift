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
    @IBOutlet weak var progressBarPlayingStatus: NSProgressIndicator!
    
    // MARK: -- Model elements:
    var player: PlaybackEngine?
    var selectedFile: URL? {
        willSet {
            toConsole("file selected: \(newValue?.absoluteString ?? "nil")")
        }
    }
    var slidersCount = 8
    
    // MARK: -- Actions:
    @IBAction func EQsliderMovedAction(_ sender: NSSlider) {
        // NB: this func is not called when buttonResetAllAction is called
        let bandNumber = sender.tag - 100
        let newValue = sender.doubleValue
        
        toConsole("received band #\(bandNumber) change to \(newValue)")
        player?.modifyParameter(ofBand: bandNumber, to: newValue)
    }
    
    //e0p1 = effect #0, parameter #1
    @IBAction func effectSliderMovedAction(_ sender: NSSlider) {
        guard let identifier = sender.identifier?.rawValue else {
            toConsole("invalid identifier")
            return
        }
        let effectNumberIndexPosition = identifier.index(
            identifier.startIndex, offsetBy: 1
        )
        let parameterIndexPosition = identifier.index(
            identifier.startIndex, offsetBy: 3
        )
        let effectNumber = identifier[effectNumberIndexPosition]
        let parameterNumber = identifier[parameterIndexPosition]
        let newValue = sender.doubleValue
        
        toConsole("received e\(effectNumber) p\(parameterNumber) -> \(newValue)")
    }
    
    @IBAction func toggleEffectAction(_ sender: NSButton) {
        guard let identifier = sender.identifier?.rawValue else {
            toConsole("invalid identifier")
            return
        }
        let effectNumberIndexPosition = identifier.index(
            identifier.startIndex, offsetBy: 1
        )
        let effectNumber = identifier[effectNumberIndexPosition]
        let newValue = sender.doubleValue
        
        toConsole("received e\(effectNumber) toggled to \(newValue)")
    }
    
    
    @IBAction func openFileButtonAction(_ sender: NSButton) {
        if selectedFile == nil {
            selectedFile = selectFile()
        }
    }
    
    @IBAction func playButtonAction(_ sender: NSButton) {
        if let selectedFilename = selectedFile {
            if let loadedPlayer = player {
                loadedPlayer.isPlaying = true
            } else {
                player = PlaybackEngine(filename: selectedFilename)
                player?.initBeforePlaying()
                player?.isPlaying = true
            }
        } else {
            _ = showAlert(withText: "Unable to start playing: no file opened")
        }
    }
    
    @IBAction func buttonResetAllAction(_ sender: NSButton) {
        for i in 0..<slidersCount {
            if let slider = self.view.viewWithTag(i + 100) as? NSSlider {
                slider.integerValue = 0
            }
        }
        //TODO: recalculate filters as well, not only gui change.
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
    func showAlert(withText text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = text
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .critical
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    func selectFile() -> URL? {
        let openDialog = NSOpenPanel();
        if (openDialog.runModal() == NSApplication.ModalResponse.OK) {
            return openDialog.url!
        } else {
            // We'll handle it in another buttons.
            return nil
        }
    }
    
    //MARK: -- Overriden functions:
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
