import Foundation

extension String {
    static var tab: Self { "\u{0009}" }
    static var space: Self { " " }
    static var openBracket: Self { "(" }
    static var closeBracket: Self { ")" }
    static var comma: Self { "," }
    static var newLine: Self { "\n" }
    static var empty: Self { "" }
}

extension Character {
    static var tab: Self { "\u{0009}" }
    static var space: Self { " " }
    static var openBracket: Self { "(" }
    static var closeBracket: Self { ")" }
    static var comma: Self { "," }
    static var newLine: Self { "\n" }
}

extension Int {
    static var one: Self { 1 }

    func clampInclusive(min: Int) -> Self {
        self < min ? min : self
    }

    var plusOne: Self { self + 1 }

    var minusOne: Self { self - 1 }
}
