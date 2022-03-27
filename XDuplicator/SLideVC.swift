import Cocoa

class SLideVC: NSViewController {
    @IBOutlet weak var btnStepOne: NSButton!
    @IBOutlet weak var btnStepTwo: NSButton!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    var activeSlide = Int.zero
    var timer: Timer?

    var slides: [String] {
        ["img_preferences", "img_extensions"]
    }

    var slideDuration: TimeInterval {
        2
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        progressIndicator.usesThreadedAnimation = false
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        startAutoSlide()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()

        timer?.invalidate()
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    func changeSlide(_ index: Int) {
        activeSlide = index
        let slideName = (index == 0) ? slides[0] : slides[1]
        imgView.image = .init(named: slideName)
    }

    var progressTime = TimeInterval.zero

    func startAutoSlide() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            self.progressTime += 0.01

            // from 0 to 100
            let percent = min(self.progressTime / (self.slideDuration / 100), 100)
            self.progressIndicator.doubleValue = percent

            if percent >= 100 {
                self.progressTime = .zero
                let btn = (self.activeSlide == .zero)
                    ? self.btnStepTwo
                    : self.btnStepOne
                self.stepBtnAction(btn!)
            }
        }
    }

    @IBAction func stepBtnAction(_ sender: NSButton) {
        progressTime = .zero

        btnStepOne.state = .off
        btnStepTwo.state = .off

        sender.state = .on

        changeSlide(sender.tag)
    }
}
