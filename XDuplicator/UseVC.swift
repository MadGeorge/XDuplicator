import Cocoa
import AVKit

class UseVC: NSViewController {
    @IBOutlet weak var playerView: AVPlayerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = Bundle.main.url(forResource: "demo", withExtension: "mp4") {
            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            playerView?.player = player
            
            NotificationCenter.default.addObserver(
                self, selector: #selector(didEndVideo),
                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                object: nil
            )
        }
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        playerView?.player?.play()
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

