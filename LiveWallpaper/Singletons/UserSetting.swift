//
//  UserSetting.swift
//  LiveWallpaper
//


import Foundation


extension VideoAttrs {
    var unpacked: (Double, Double, Double) {
        (brightness, saturation, warmth)
    }
}

struct VideoAttrs: Codable, Equatable, Hashable {
    let brightness: Double
    let saturation: Double
    let warmth: Double
    
    static let `default` = VideoAttrs(brightness: 0.2, saturation: 0.5, warmth: 0.0)
}

struct Video: Codable, Equatable, Hashable {
    let id:String
    let url:String
    let type:VideoType
    let thumbnail:String
    var attrs: VideoAttrs?
    
    enum CodingKeys: String, CodingKey {
        case id, url, type, thumbnail, attrs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode all properties normally except bindLocalhost
        id = try container.decode(String.self, forKey: .id)
        url = try container.decode(String.self, forKey: .url)
        type = try container.decode(VideoType.self, forKey: .type)
        thumbnail = try container.decode(String.self, forKey: .thumbnail)
        
        attrs = try container.decodeIfPresent(VideoAttrs.self, forKey: .attrs)
    }
    
    init(
        id: String,
        url: String,
        type: VideoType,
        thumbnail: String,
        attrs: VideoAttrs? = nil
    ) {
        self.id = id
        self.url = url
        self.type = type
        self.thumbnail = thumbnail
        self.attrs = attrs
    }
}

enum VideoType: String, Codable {
    case pixabay
    case local
    case youtube
}


struct Sound: Codable {
    var name:String
    var isEnabled: Bool
    var volume: Float
}

class UserSetting: ObservableObject {
    static let shared = UserSetting()
    
    @Published var video:Video = Video(id: "", url: "", type: .pixabay, thumbnail: "")
    @Published var recent:[Video] = []
    
    @Published var mixerEnabled = false {
        didSet {
            defaults.set(mixerEnabled, forKey: "mixerEnabled")
            AudioMixer.shared.process(mixerEnabled: mixerEnabled, sounds: sounds)
        }
    }
    
    @Published var sounds:[Sound] = [] {
        didSet {
            print("sounds did set")
            if let encoded = try? JSONEncoder().encode(sounds) {
                defaults.set(encoded, forKey: "sounds")
            }
            AudioMixer.shared.process(mixerEnabled: mixerEnabled, sounds: sounds)
        }
    }
    
    @Published var launchAtLogin = false {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
        }
    }
    
    @Published var doNotShowWindow = false {
        didSet {
            defaults.set(doNotShowWindow, forKey: "doNotShowWindow")
        }
    }
    
    @Published var powerSaver = false {
        didSet {
            defaults.set(powerSaver, forKey: "powerSaver")
        }
    }
    
    static let adaptiveModeChangedNotification = Notification.Name("UserSetting.adaptiveModeChanged")

    @Published var adaptiveMode: Bool = false {
        didSet {
            defaults.set(adaptiveMode, forKey: "adaptiveMode")
            NotificationCenter.default.post(name: Self.adaptiveModeChangedNotification, object: nil)
        }
    }
    
    var attemptId = ""
    
    private let defaults = UserDefaults.standard
    
    init(){
        self.video = getVideo()
        self.recent = getRecent()
        self.mixerEnabled = getMixerEnabled()
        self.sounds = getSounds()
        self.launchAtLogin = getlaunchAtLogin()
        self.doNotShowWindow = getdoNotShowWindow()
        self.powerSaver = getPowerSaver()
        
        self.adaptiveMode = defaults.bool(forKey: "adaptiveMode")
        
        migrate()
    }

    func migrate(){
        //some migration for dark mode
        DispatchQueue.global(qos: .background).async {
            Task {
                for index in self.recent.indices {
                    if self.recent[index].attrs == nil {
                        let attrs = await analyzeVideoCharacteristics(url: URL(fileURLWithPath: self.recent[index].url))
                        
                        DispatchQueue.main.async {
                            self.recent[index].attrs = attrs
                        }
                    }
                }
                
                if let encoded = try? JSONEncoder().encode(self.recent) {
                    self.defaults.set(encoded, forKey: "recent")
                }
            }
        }
    }
    
    func setVideo(_ video: Video) {
        if let encoded = try? JSONEncoder().encode(video) {
            defaults.set(encoded, forKey: "video")
            self.video = video
        }
        
        var recent = getRecent()
        if !recent.contains(video) {
            recent.append(video)
            if let encoded = try? JSONEncoder().encode(recent) {
                defaults.set(encoded, forKey: "recent")
                self.recent = recent
            }
        }
    }
    
    func deleteVideo(_ video: Video){
        recent.removeAll {$0.id == video.id}
        if let encoded = try? JSONEncoder().encode(recent) {
            defaults.set(encoded, forKey: "recent")
            self.recent = recent
        }
        
        do {
            try FileManager.default.removeItem(atPath: video.url)
            try FileManager.default.removeItem(atPath: video.thumbnail)
        } catch {}
        
    }
    
    func resetVideoAndRecent(){
        video = Video(id: "", url: "", type: .pixabay, thumbnail: "")
        recent = []
        if let encoded = try? JSONEncoder().encode(video) {
            defaults.set(encoded, forKey: "video")
        }
        if let encoded = try? JSONEncoder().encode(recent) {
            defaults.set(encoded, forKey: "recent")
        }
    }
    
    func getVideo() -> Video {
        if let savedData = defaults.data(forKey: "video"),
           let video = try? JSONDecoder().decode(Video.self, from: savedData) {
            return video
        }
        return Video(id: "", url: "", type: .pixabay, thumbnail: "")
    }
    
    func getRecent() -> [Video] {
        if let savedData = defaults.data(forKey: "recent"),
           let videos = try? JSONDecoder().decode([Video].self, from: savedData) {
            return videos
        }
        return []
    }
    
    func getMixerEnabled() -> Bool {
        return defaults.bool(forKey: "mixerEnabled")
    }
    
    func getlaunchAtLogin() -> Bool {
        return defaults.bool(forKey: "launchAtLogin")
    }
    
    func getdoNotShowWindow() -> Bool {
        return defaults.bool(forKey: "doNotShowWindow")
    }
    
    func getPowerSaver() -> Bool {
        return defaults.bool(forKey: "powerSaver")
    }
    
    func getSounds() -> [Sound] {
        if let savedData = defaults.data(forKey: "sounds"),
           let sounds = try? JSONDecoder().decode([Sound].self, from: savedData) {
            return sounds
        }
        
        let mp3s = [
            "rain","thunder","fire", "beach", "seagull",
            "wind", "bird", "creek", "cricket", "snow",
            "firework", "foghorn","fan", "owls", "palm",
            "playground", "coffee", "restaurant",
             "train",  "wolves", "bowl", "chimes",
        ]
        
        for mp3 in mp3s {
            sounds.append(Sound(name: mp3, isEnabled: false, volume: 0.5))
        }
        return sounds
    }
    
    

}
