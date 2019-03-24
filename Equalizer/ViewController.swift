//
//  ViewController.swift
//  Equalizer
//
//  Created by Иван Дахненко on 26.12.2018.
//  Copyright © 2018 Ivan Dakhnenko. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    // MARK: -- UI-dependent elemelts
    @IBOutlet weak var FFTIInputView: FFTView!
    @IBOutlet weak var FFTOutputView: FFTView!
    var FFTUpdaterQueue = DispatchQueue(label: "FFTUpdater")
    var FFTDBCorrection: Float = 80
    
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
        player?.initializeAllNodes()
    }
    
    @IBAction func playButtonAction(_ sender: NSButton) {
        if selectedFile != nil {
            if let loadedPlayer = player {
                loadedPlayer.isPlaying = true
            } else {
                player?.isPlaying = true
            }
            FFTUpdaterQueue.async {
                repeat {
                    guard
                        let dataIn = self.player?.getFFTData(
                            source: .input,
                            amplifyBy: 1
                        ),
                        let dataOut = self.player?.getFFTData(
                            source: .output,
                            amplifyBy: 1
                        )
                    else {continue}
                    
                    self.FFTIInputView.modifyFFTResults(
                        newData: dataIn.map{
                            self.toDB($0) + self.FFTDBCorrection
                            
                    })
                    self.FFTOutputView.modifyFFTResults(
                        newData: dataOut.map{
                            self.toDB($0) + self.FFTDBCorrection
                            
                    })
                    
                    DispatchQueue.main.async {
                        self.FFTIInputView.setNeedsDisplay(NSRect(
                            x: 0,
                            y: 0,
                            width: self.FFTIInputView.width,
                            height: self.FFTIInputView.height))
                        self.FFTOutputView.setNeedsDisplay(NSRect(
                            x: 0,
                            y: 0,
                            width: self.FFTOutputView.width,
                            height: self.FFTOutputView.height))
                    }
                } while (true);
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
            player?.modifyParameter(ofBand: i, to: 0)
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
    
    @IBAction func FFTDBCorrectionSliderAction(_ sender: NSSlider) {
        FFTDBCorrection = sender.floatValue
        toConsole("newValue = \(FFTDBCorrection)")
    }
    
    @IBAction func FFTAverageTimeSliderAction(_ sender: NSSlider) {
        FFTIInputView.bufferLength = sender.integerValue
        FFTOutputView.bufferLength = sender.integerValue
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
    
    func toDB(_ inMagnitude: Float) -> Float {
        let magnitude = max(inMagnitude, 0.000000000001)
        return 10 * log10f(magnitude)
    }
    
    //MARK: -- Overriden functions:
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
