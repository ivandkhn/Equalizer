//
//  ViewController.swift
//  Equalizer
//
//  Created by Иван Дахненко on 26.12.2018.
//  Copyright © 2018 Ivan Dakhnenko. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    // MARK: -- UI-dependent elements:
    @IBOutlet weak var progressBarPlayingStatus: NSProgressIndicator!
    @IBOutlet weak var FFTIInputView: FFTView!
    var timer = Timer()
    
    // MARK: -- Model elements:
    var player: PlaybackEngine?
    var selectedFile: URL? {
        willSet {
            toConsole("file selected: \(newValue?.absoluteString ?? "nil")")
        }
    }
    var slidersCount = 8
    var fftEngine = TempiFFT(withSize: 1024, sampleRate: 44100)
    
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
        let effectNumber = Int(String(identifier[effectNumberIndexPosition]))!
        let parameterNumber = Int(String(identifier[parameterIndexPosition]))!
        let newValue = sender.doubleValue
        
        toConsole("received e\(effectNumber) p\(parameterNumber) -> \(newValue)")
        player?.modifyParameter(
            ofEffect: effectNumber,
            ofParameter: parameterNumber,
            to: newValue
        )
    }
    
    @IBAction func toggleEffectAction(_ sender: NSButton) {
        guard let identifier = sender.identifier?.rawValue else {
            toConsole("invalid identifier")
            return
        }
        let effectNumberIndexPosition = identifier.index(
            identifier.startIndex, offsetBy: 1
        )
        let effectNumber = Int(String(identifier[effectNumberIndexPosition]))!
        let newValue = sender.doubleValue
        
        toConsole("received e\(effectNumber) toggled to \(newValue)")
        player?.modifyParameter(
            ofEffect: effectNumber,
            ofParameter: 1,
            to: newValue
        )
    }
    
    @IBAction func openFileButtonAction(_ sender: NSButton) {
        selectedFile = selectFile()
        guard let selectedFilename = selectedFile else {return}
        player = PlaybackEngine(filename: selectedFilename)
        player?.initBeforePlaying()
    }
    
    @IBAction func playButtonAction(_ sender: NSButton) {
        if selectedFile != nil {
            if let loadedPlayer = player {
                loadedPlayer.isPlaying = true
            } else {
                player?.isPlaying = true
            }
            fftEngine.windowType = TempiFFTWindowType.hanning
            scheduleFFTViewUpdateTimer()
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
    
    @IBAction func inputFFTSliderAction(_ sender: NSSlider) {
        FFTIInputView.lowDBGainOffset = sender.floatValue
    }
    
    //MARK: -- Helper functions:
    func scheduleFFTViewUpdateTimer(){
        timer = Timer.scheduledTimer(timeInterval: 0.1,
                                     target: self,
                                     selector: #selector(self.updateFFTView),
                                     userInfo: nil,
                                     repeats: true)
    }
       
    @objc func updateFFTView(){
        guard let player = player else {return}
        if !(player.isPlaying) {return}
        guard let rawData = player.getRawData() else {return}
        fftEngine.fftForward(rawData)
        fftEngine.calculateLogarithmicBands(minFrequency: 20,
                                            maxFrequency: 20000,
                                            bandsPerOctave: 40)
        guard var data = fftEngine.bandMagnitudes else {return}
        for i in data.indices {
            data[i] = TempiFFT.toDB(data[i])
        }
        FFTIInputView.data = data
        FFTIInputView.setNeedsDisplay(NSRect(x: 0, y: 0,
                                             width: 400, height: 240))
    }
    
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
