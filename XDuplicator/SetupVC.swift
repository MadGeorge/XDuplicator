import Cocoa

class SetupVC: SLideVC {
    override var slides: [String] {
        ["img_keys", "img_conflicts"]
    }
    
    override var slideDuration: TimeInterval {
        10
    }
}

