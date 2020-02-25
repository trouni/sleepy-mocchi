//
//  MainViewController.swift
//  Sleepy Mochi
//
//  Created by Trouni on 2019/08/23.
//  Copyright © 2019 KESSEO. All rights reserved.
//

import SwiftUI
import WebKit
import AVFoundation

class MainViewController: UIViewController, AVAudioPlayerDelegate {
    var sleepPlayer: SleepPlayer = SleepPlayer()
    let defaults = UserDefaults.standard
    var timer: Timer = Timer()
    var defaultTimer: Int?
    var timerIncrement: Int = 300
    var timerIsRunning: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        reset()
        // Initialize user defaults settings
        UserDefaults.standard.register(defaults: [
            "defaultTimer": 1800
        ])
        resetSleepTimer()
        ratioSlider.value = defaults.float(forKey: "ratioSlider")
        loadHtmlCode()
        refreshUI()
        
        guard let voicePlayer = sleepPlayer.audioPlayer["voice"],
            let ambiancePlayer = sleepPlayer.audioPlayer["ambiance"]
            else { return }
        voicePlayer.delegate = self;
        ambiancePlayer.delegate = self;
        
        minusButton.setImage(UIImage(named: "Images/icons/minus-circle.png"), for: .normal)
        plusButton.setImage(UIImage(named: "Images/icons/plus-circle.png"), for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func refreshUI() {
        updateMochiImage()
        updatePlayButtonLabel()
        updateTimerButtons()
    }
    
    @IBOutlet weak var webView: WKWebView!

    func loadHtmlCode() {
        // Adding webView content
        do {
            guard let filePath = Bundle.main.path(forResource: "html/background", ofType: "html")
                else {
                    // File Error
                    print ("File reading error")
                    return
            }

            let contents =  try String(contentsOfFile: filePath, encoding: .utf8)
            let baseUrl = URL(fileURLWithPath: filePath)
            webView.loadHTMLString(contents as String, baseURL: baseUrl)
        }
        catch {
            print ("File HTML error")
        }
    }
    
    func startTimer() {
        if !timerIsRunning {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(MainViewController.updateTimer)), userInfo: nil, repeats: true)
            timerIsRunning = true
        }
    }
    
    func pauseTimer() {
        if timerIsRunning {
            sleepPlayer.pause()
            resetSleepTimer()
            timer.invalidate()
            timerIsRunning = false
        }
    }
    
    func toggleTimer() {
        timerIsRunning ? pauseTimer() : startTimer()
    }
    
    func resetSleepTimer() {
        defaultTimer = defaults.integer(forKey: "defaultTimer")
        sleepPlayer.seconds = defaultTimer
        timerIsRunning = false
        syncTimerLabel()
    }
    
    func decrementTimer() {
        sleepPlayer.seconds! -= 1
        syncTimerLabel()
    }
    
    @objc func updateTimer() {
        guard let seconds = sleepPlayer.seconds else { return }
        if seconds == sleepPlayer.fadeOutDuration { sleepPlayer.fadeOut() }
        
        if timerIsRunning && seconds > 0 {
            decrementTimer()
        } else {
            resetSleepTimer()
            pauseTimer()
        }
    }
    
    func reset() {
        defaults.removeObject(forKey: "ratioSlider")
        defaults.removeObject(forKey: "defaultTimer")
        defaults.removeObject(forKey: "fadeOutDuration")
    }
    
    func syncTimerLabel() {
        guard let seconds = sleepPlayer.seconds else { return }
        timerLabel.text = formatTime(seconds)
    }
    
    func updatePlayButtonLabel() {
//        if #available(iOS 13.0, *) {
//            let buttonImageName = sleepPlayer.isPlaying() ? "pause.circle.fill" : "play.circle.fill"
//            playButton.setImage(UIImage(systemName: buttonImageName), for: .normal)
//        } else {
//            Fallback on earlier versions
            let buttonImageName = sleepPlayer.isPlaying() ? "Images/icons/pause.png" : "Images/icons/play.png"
            playButton.setImage(UIImage(named: buttonImageName), for: .normal)
//        }
    }
    
    func updateMochiImage() {
        let mochiImageName = sleepPlayer.isPlaying() ? "Images/sleeping_mochi.png" : "Images/mochi.png"
        mochiImage.setImage(UIImage(named: mochiImageName), for: .normal)
    }
    
    func updateTimerButtons() {
        plusButton.isHidden = sleepPlayer.isPlaying()
        minusButton.isHidden = sleepPlayer.isPlaying()
    }
    
    func formatTime(_ timeInSeconds: Int) -> String {
        let minutes: Int = timeInSeconds / 60 % 60
        let seconds: Int = timeInSeconds % 60
        let hours: Int = timeInSeconds / 60 / 60
        
        return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        sleepPlayer.togglePlay()
        toggleTimer()
        refreshUI()
    }

    @IBOutlet weak var ratioSlider: UISlider!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var mochiImage: UIButton!
    
    @IBAction func increaseTimer(_ sender: UIButton) {
        if timerIsRunning {
            sleepPlayer.seconds! += timerIncrement
            syncTimerLabel()
        } else {
            defaultTimer! += timerIncrement
            defaults.set(defaultTimer, forKey: "defaultTimer")
            resetSleepTimer()
        }
    }
    
    @IBAction func decreaseTimer(_ sender: UIButton) {
        if timerIsRunning {
            if sleepPlayer.seconds! > 300 { sleepPlayer.seconds! -= timerIncrement }
            syncTimerLabel()
        } else {
            defaultTimer = max(300, defaultTimer! - 300)
            defaults.set(defaultTimer, forKey: "defaultTimer")
            resetSleepTimer()
        }
    }
    
    @IBAction func ratioSliderMoved(_ sender: UISlider) {
        defaults.set(ratioSlider.value, forKey: "ratioSlider")
        sleepPlayer.setVolume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let tracksViewController = segue.destination as? TracksViewController else { return }
        tracksViewController.sleepPlayer = sleepPlayer
        tracksViewController.trackType = segue.identifier!
    }
    
    @IBAction func mochiTapped(_ sender: UIButton) {
        sleepPlayer.togglePlay()
        toggleTimer()
        refreshUI()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard let voicePlayer = sleepPlayer.audioPlayer["voice"],
        let voiceTracks = sleepPlayer.tracks["voice"],
        let currentVoiceTrack = sleepPlayer.currentTrack["voice"]
        else { return }
        
        if flag && player == voicePlayer {
            let currentTrackIndex = voiceTracks.firstIndex(of: currentVoiceTrack)
            let nextTrackIndex = (currentTrackIndex! + 1) % voiceTracks.count
            sleepPlayer.currentTrack["voice"] = voiceTracks[nextTrackIndex]
            sleepPlayer.setTrack("voice", play: true)
            guard let voicePlayer = sleepPlayer.audioPlayer["voice"] else { return }
            voicePlayer.delegate = self;
        }
    }
}
