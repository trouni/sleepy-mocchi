//
//  SettingsViewController.swift
//  Sleepy Mochi
//
//  Created by Trouni on 2019/08/26.
//  Copyright © 2019 KESSEO. All rights reserved.
//

import UIKit
import AVFoundation

class TracksViewController: UITableViewController, AVAudioPlayerDelegate {
    let defaults = UserDefaults.standard
    var sleepPlayer: SleepPlayer?
    var trackType: String?
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard let sleepPlayer = sleepPlayer,
            let trackType = trackType,
            let tracks = sleepPlayer.tracks[trackType]
            else { return 0 }
        
        return tracks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell_track", for: indexPath)
    
        guard let sleepPlayer = sleepPlayer,
            let trackType = trackType,
            let tracks = sleepPlayer.tracks[trackType]
            else { return cell }

        if indexPath.row < tracks.count {
            let track = fileToTrackName(tracks[indexPath.row])
            cell.textLabel?.text = track
            
            let accessory: UITableViewCell.AccessoryType = ( tracks[indexPath.row] == sleepPlayer.currentTrack[trackType]) ? .checkmark : .none
            cell.accessoryType = accessory
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard let sleepPlayer = sleepPlayer,
            let trackType = trackType,
            let tracks = sleepPlayer.tracks[trackType],
            let audioPlayer = sleepPlayer.audioPlayer[trackType]
            else { return }
        tableView.deselectRow(at: indexPath, animated: true)
    
        if indexPath.row < tracks.count
        {
            sleepPlayer.currentTrack[trackType] = tracks[indexPath.row]
            defaults.set(sleepPlayer.currentTrack[trackType], forKey: "\(trackType)Track")
            sleepPlayer.setTrack(trackType, play: audioPlayer.isPlaying)

            tableView.reloadData()
            
//            guard let voicePlayer = sleepPlayer.audioPlayer["voice"] else { return }
//            voicePlayer.delegate = self
        }
    }
    
    func fileToTrackName(_ fileName: String) -> String {
        return fileName.split(separator: ".")[0].replacingOccurrences(of: "_", with: " ")
    }
}
