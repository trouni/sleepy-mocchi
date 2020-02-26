//
//  SleepPlayer.swift
//  Sleepy Mochi
//
//  Created by Trouni on 2019/08/26.
//  Copyright © 2019 KESSEO. All rights reserved.
//

import Foundation
import AVFoundation

class SleepPlayer {
    let defaults = UserDefaults.standard
    var audioPlayer: [String: AVAudioPlayer] = [
        "voice": AVAudioPlayer(),
        "ambiance": AVAudioPlayer()
    ]
    var currentTrack: [String: String] = [
        "voice": "",
        "ambiance": ""
    ]
    var tracks: [String: [String]] = [
        "voice": [],
        "ambiance": []
    ]
    var seconds: Int?
    var fadeOutDuration: Int?
    
    public init() {
//        reset()
        // Initialize user defaults settings
        UserDefaults.standard.register(defaults: [
            "voiceTrack" : "[Le_Petit_Prince]_Chapitre_01.mp3",
            "ambianceTrack": "[Music]_Healing_Sleep.mp3",
            "ratioSlider": 0.5,
            "fadeOutDuration": 10
        ])
        
        currentTrack = [
            "voice": defaults.object(forKey: "voiceTrack") as! String,
            "ambiance": defaults.object(forKey: "ambianceTrack") as! String
        ]
        
        fadeOutDuration = defaults.integer(forKey: "fadeOutDuration")
        initPlayer(track: currentTrack["voice"]!, trackType: "voice")
        initPlayer(track: currentTrack["ambiance"]!, trackType: "ambiance", loops: -1)
//        setTrack("voice", play: false)
//        setTrack("ambiance", play: false)
        
//        let ratioSlider = defaults.float(forKey: "ratioSlider")
        setVolume()
        
        syncTracks()
    }
    
    func initPlayer(track: String, trackType: String, loops: Int = 0, play: Bool = false) {
        let fileName = String(track.split(separator: ".")[0])
        let fileExtension = String(track.split(separator: ".")[1])
        let filePath = "Audio/\(trackType.capitalized)/\(fileName)"
        guard let url = Bundle.main.url(forResource: filePath, withExtension: fileExtension) else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            if fileExtension == "mp3" {
                audioPlayer[trackType] = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            } else if fileExtension == "m4a" {
                audioPlayer[trackType] = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.m4a.rawValue)
            }

            /* iOS 10 and earlier require the following line:
            voicePlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let audioPlayer = audioPlayer[trackType] else { return }
            audioPlayer.numberOfLoops = loops
            
            if play { audioPlayer.play() }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func setTrack(_ trackType: String, play: Bool) {
        guard let currentTrack = currentTrack[trackType] else { return }
//        let loops = trackType == "ambiance" ? -1 : 0
        let loops = -1 // Until the "next track" feature for voice can be fixed
        initPlayer(track: currentTrack, trackType: trackType, loops: loops, play: play)
        setVolume(0)
    }
    
    func play() {
        guard let voicePlayer = audioPlayer["voice"],
        let ambiancePlayer = audioPlayer["ambiance"]
        else { return }
        
        setVolume()
        voicePlayer.play()
        ambiancePlayer.play()
    }
    
    func pause() {
        guard let voicePlayer = audioPlayer["voice"],
        let ambiancePlayer = audioPlayer["ambiance"]
        else { return }
        
        voicePlayer.pause()
        ambiancePlayer.pause()
    }
    
    func fadeOut() {
        guard let voicePlayer = audioPlayer["voice"],
            let ambiancePlayer = audioPlayer["ambiance"],
            let fadeOutDuration = fadeOutDuration
            else { return }
        
        ambiancePlayer.setVolume(0, fadeDuration: Double(fadeOutDuration))
        voicePlayer.setVolume(0, fadeDuration: Double(fadeOutDuration))
    }
    
    func isPlaying() -> Bool {
        guard let voicePlayer = audioPlayer["voice"],
        let ambiancePlayer = audioPlayer["ambiance"]
        else { return false }
        
        let (voicePlaying, ambiancePlaying) = (voicePlayer.isPlaying, ambiancePlayer.isPlaying)
        
        return voicePlaying || ambiancePlaying
    }
    
    func togglePlay() {
        isPlaying() ? pause() : play()
    }
    
    func setVolume(_ fadeDuration: Double = 0.5) {
        guard let voicePlayer = audioPlayer["voice"],
            let ambiancePlayer = audioPlayer["ambiance"]
            else { return }
        
        let ratioSlider = defaults.float(forKey: "ratioSlider")
        let voiceVolume = min(ratioSlider * 2, 1)
        let ambianceVolume = min(2 - 2 * ratioSlider, 1)
        ambiancePlayer.setVolume(ambianceVolume, fadeDuration: fadeDuration)
        voicePlayer.setVolume(voiceVolume, fadeDuration: fadeDuration)
    }
    
    private func syncTracks() {
        let fileManager = FileManager.default
        let path = Bundle.main.resourcePath!

        do {
            tracks["voice"] = try fileManager.contentsOfDirectory(atPath: "\(path)/Audio/Voice").sorted(by: { $0 < $1 })
            tracks["ambiance"] = try fileManager.contentsOfDirectory(atPath: "\(path)/Audio/Ambiance").sorted(by: { $0 < $1 })
        } catch {
            print("Failed to read directory")
        }
    }
    
    func reset() {
        defaults.removeObject(forKey: "voiceTrack")
        defaults.removeObject(forKey: "ambianceTrack")
    }
}
