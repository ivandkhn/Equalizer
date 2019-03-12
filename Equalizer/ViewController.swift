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
    @IBOutlet weak var FFTOutputView: FFTView!
    var timer = Timer()
    var FFTUpdaterQueue = DispatchQueue(label: "FFTUpdater")
    
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
        fftEngine.windowType = TempiFFTWindowType.hanning
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
                    if let data = self.player?.getFFTData(source: .input, amplifyBy: 10e5) {
                        self.FFTIInputView.data = data.map{TempiFFT.toDB($0)}
                        DispatchQueue.main.async {
                            self.FFTIInputView.setNeedsDisplay(NSRect(
                                    x: 0,
                                    y: 0,
                                    width: self.FFTIInputView.width,
                                    height: self.FFTIInputView.height))
                        }
                    }
                    if let dataOut = self.player?.getFFTData(source: .output, amplifyBy: 10e5) {
                        self.FFTOutputView.data = dataOut.map{TempiFFT.toDB($0)}
                        DispatchQueue.main.async {
                            self.FFTOutputView.setNeedsDisplay(NSRect(
                                x: 0,
                                y: 0,
                                width: self.FFTOutputView.width,
                                height: self.FFTOutputView.height))
                        }
                    }
                } while (true);
            }
/*
             FFTUpdaterQueue.async {
             repeat {
             if let data = self.calculateFFTData(skippingFirst: 20) {
             self.FFTIInputView.data = data
             DispatchQueue.main.async {
             self.FFTIInputView.setNeedsDisplay(NSRect(
             x: 0,
             y: 0,
             width: self.FFTIInputView.width,
             height: self.FFTIInputView.height))
             }
             }
             if let dataOut = self.player?.getFFTOutputData(skippingFirst: 20) {
             self.FFTOutputView.data = dataOut.map{TempiFFT.toDB($0)}
             DispatchQueue.main.async {
             self.FFTOutputView.setNeedsDisplay(NSRect(
             x: 0,
             y: 0,
             width: self.FFTOutputView.width,
             height: self.FFTOutputView.height))
             }
             }
             } while (true);
             }
 */
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
    
    @IBAction func inputFFTSliderAction(_ sender: NSSlider) {
        FFTIInputView.lowDBGainOffset = sender.floatValue
    }
    
    //MARK: -- Helper functions:
    func calculateFFTData(skippingFirst startIndex: Int) -> [Float]? {
        //skippingFirst: FFT resolution is small on low frequencies,
        //so we can drop some first values and don't draw them at all.
        guard let player = player else {return nil}
        if !(player.isPlaying) {return nil}
        guard let rawData = player.getRawData() else {return nil}
        fftEngine.fftForward(rawData)
        fftEngine.calculateLogarithmicBands(minFrequency: 20,
                                            maxFrequency: 20000,
                                            bandsPerOctave: 40)
        guard var data = fftEngine.bandMagnitudes else {return nil}
        for i in data.indices {
            data[i] = TempiFFT.toDB(data[i])
        }
        return Array(data[startIndex...data.count-1])
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
