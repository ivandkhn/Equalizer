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
    @IBOutlet weak var sliderBand1: NSSlider!
    @IBOutlet weak var sliderBand2: NSSlider!
    @IBOutlet weak var sliderBand3: NSSlider!
    @IBOutlet weak var sliderBand4: NSSlider!
    @IBOutlet weak var sliderBand5: NSSlider!
    @IBOutlet weak var sliderBand6: NSSlider!
    @IBOutlet weak var sliderBand7: NSSlider!
    @IBOutlet weak var sliderBand8: NSSlider!
    @IBOutlet weak var progressBarPlayingStatus: NSProgressIndicator!
    
    var slidersAll: [NSSlider]? = nil {
        didSet {
            if let initilized = slidersAll {
                toConsole("created \(initilized.count) UI bands")
            }
        }
    }
    
    // MARK: -- Model elements:
    var player: PlaybackEngine?
    var selectedFile: URL? = nil
    
    // MARK: -- Actions:
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
        for item in slidersAll! {
            item.integerValue = 0
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
        
        slidersAll = [
            sliderBand1, sliderBand2, sliderBand3, sliderBand4,
            sliderBand5, sliderBand6, sliderBand7, sliderBand8
        ]
        //TODO: take bands labels from [initialBands]
        
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}
