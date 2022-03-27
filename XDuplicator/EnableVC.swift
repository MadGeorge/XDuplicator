import Foundation
import Cocoa

class EnableVC: SLideVC {
    override var slides: [String] {
        ["img_preferences", "img_extensions"]
    }
    
    override var slideDuration: TimeInterval {
        4
    }
    
    @IBAction func settingsBtnAction(_ sender: NSButton) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preferences.extensions") else { return }
        NSWorkspace.shared.open(url)
    }
}
