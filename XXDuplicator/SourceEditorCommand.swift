import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        let bundle = Bundle.main.bundleIdentifier ?? .empty
        
        switch invocation.commandIdentifier {
        case "\(bundle).Duplicate":
            performDuplicate(on: invocation)
        case "\(bundle).Delete":
            performDelete(on: invocation)
        default:
            break
        }
        
        completionHandler(nil)
    }
    
    func performDelete(on invocation: XCSourceEditorCommandInvocation) {
        guard let selection = invocation.buffer.selections.firstObject as? XCSourceTextRange else {
            return
        }
        
        let start = selection.start
        let end = selection.end

        let maxLines = invocation.buffer.lines.count.minusOne
        let startIndex = min(start.line, maxLines)
        let endIndex = max(.zero, min(end.line, maxLines)).clampInclusive(min: startIndex)

        invocation.buffer.lines.removeObjects(at: IndexSet(integersIn: startIndex...endIndex))

        invocation.buffer.selections.removeAllObjects()
        invocation.buffer.selections.add(
            XCSourceTextRange(
                start: .init(line: start.line, column: start.column),
                end: .init(line: start.line, column: start.column)
            )
        )
    }
    
    func performDuplicate(on invocation: XCSourceEditorCommandInvocation) {
        guard let selection = invocation.buffer.selections.firstObject as? XCSourceTextRange else {
            return
        }
        
        let start = selection.start
        let end = selection.end
        
        // no selection, just cursore on the line
        if start.line == end.line && start.column == end.column {
            if let line = invocation.buffer.lines.object(at: start.line) as? String {
                let nextLine = start.line.plusOne
                invocation.buffer.lines.insert(line, at: nextLine)
                
                // move selection
                invocation.buffer.selections.removeAllObjects()
                invocation.buffer.selections.add(
                    XCSourceTextRange(
                        start: .init(line: nextLine, column: start.column),
                        end: .init(line: nextLine, column: start.column)
                    )
                )
            }
            return
        }
        
        // duplicate selection on single line
        if start.line == end.line {
            if var line = invocation.buffer.lines.object(at: start.line) as? String {
                let sStart = line.index(line.startIndex, offsetBy: start.column)
                let sEnd = line.index(line.startIndex, offsetBy: end.column)
                let selection = line[sStart..<sEnd]
                line.insert(contentsOf: selection, at: sEnd)
                invocation.buffer.lines.replaceObject(at: start.line, with: line)
            }
            
            // move selection
            let lenght = end.column - start.column
            invocation.buffer.selections.removeAllObjects()
            invocation.buffer.selections.add(
                XCSourceTextRange(
                    start: .init(line: end.line, column: end.column),
                    end: .init(line: end.line, column: end.column + lenght)
                )
            )
            return
        }
        
        let lineDiff = end.line - start.line
        
        if lineDiff > .zero {
            let lines = invocation.buffer.lines.objects(at: IndexSet(integersIn: start.line...end.line))
            if
                let firstLine = lines[.zero] as? String,
                let lastLine = lines[lineDiff] as? String
            {
                let firstLineSuffix = firstLine[firstLine.index(firstLine.startIndex, offsetBy: start.column)...]

                let lastLinePrefix = lastLine[lastLine.startIndex..<lastLine.index(lastLine.startIndex, offsetBy: end.column)]
                let lastLineSuffix = lastLine[lastLine.index(lastLine.startIndex, offsetBy: end.column)...]

                let linesBetween = invocation.buffer.lines.objects(at: IndexSet(integersIn: (start.line.plusOne)..<end.line))
                
                let appending = String(lastLinePrefix) + String(firstLineSuffix) + String(lastLineSuffix)
                invocation.buffer.lines.replaceObject(at: end.line, with: appending.trimmingCharacters(in: .newlines))
                
                var index = start.line.plusOne
                for line in linesBetween {
                    invocation.buffer.lines.insert(line, at: index)
                    index = index.plusOne
                }
                
                invocation.buffer.lines.insert(lastLinePrefix.trimmingCharacters(in: .newlines), at: index)
                
                invocation.buffer.selections.removeAllObjects()
                invocation.buffer.selections.add(
                    XCSourceTextRange(
                        start: .init(line: end.line, column: start.column),
                        end: .init(line: end.line + lineDiff, column: end.column)
                    )
                )
            }
        }
    }
}

extension Int {
    func clampInclusive(min: Int) -> Self {
        self < min ? min : self
    }

    var plusOne: Self { self + 1 }

    var minusOne: Self { self - 1 }
}

extension String {
    static var empty: String { "" }
}
