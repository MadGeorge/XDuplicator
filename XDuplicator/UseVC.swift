import Cocoa
import AVKit

class UseVC: NSViewController {
    @IBOutlet weak var playerView: AVPlayerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let player = AVPlayer(url: URL(string: "https://firebasestorage.googleapis.com/v0/b/videosplitterhosting.appspot.com/o/video%2Fxduplicator-screencast.mp4?alt=media")!)
        playerView?.player = player
        playerView?.controlsStyle = .default
        playerView?.showsFullScreenToggleButton = true

        NotificationCenter.default.addObserver(
            self, selector: #selector(didEndVideo),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        
        playerView?.player?.pause()
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @objc func didEndVideo() {
        playerView?.player?.seek(to: .zero)
        playerView?.player?.play()
    }
}

