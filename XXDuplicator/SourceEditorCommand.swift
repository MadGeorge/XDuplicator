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

        case "\(bundle).Break":
            performBreak(on: invocation)

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
        
        // no selection, just cursor on the line
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

    func performBreak(on invocation: XCSourceEditorCommandInvocation) {
        guard let selection = invocation.buffer.selections.firstObject as? XCSourceTextRange else {
            return
        }

        let start = selection.start

        guard let line = invocation.buffer.lines.object(at: start.line) as? String else { return }

        let indent = Array(
            repeating: (invocation.buffer.usesTabsForIndentation ? .tab : .space),
            count: invocation.buffer.indentationWidth
        ).joined(separator: .empty)

        guard let openBracketIndex = line.firstIndex(of: .openBracket) else { return }
        guard let closeBracketIndex = line.lastIndex(of: .closeBracket) else { return }

        let funcBody = String(line[line.index(after: openBracketIndex)..<closeBracketIndex])

        let baseIndent = lineIndent(line)

        var output = String(line[...openBracketIndex])
        output += .newLine
        output += extractParameters(funcBody, indent: baseIndent + indent).joined(separator: .newLine)
        output += .newLine
        output += baseIndent + String(line[closeBracketIndex...])

        invocation.buffer.lines.removeObject(at: start.line)
        invocation.buffer.lines.insert(output, at: start.line)
    }

    private func lineIndent(_ input: String) -> String {
        var indent = String.empty

        for element in input {
            if (element == .tab || element == .space) {
                indent.append(element)
                continue
            }

            break
        }

        return indent
    }

    private func extractParameters(_ input: String, indent: String) -> [String] {
        var numOfBrackets = Int.zero
        var numOfCurlBrackets = Int.zero
        var numOfSquareBrackets = Int.zero

        let inputIndices = input.indices

        var params = [String]()
        var currentParam = String.empty

        for index in inputIndices {
            let char = input[index]

            if char == "(" { numOfBrackets += .one }
            if char == ")" { numOfBrackets -= .one }

            if char == "{" { numOfCurlBrackets += .one }
            if char == "}" { numOfCurlBrackets -= .one }

            if char == "[" { numOfSquareBrackets += .one }
            if char == "]" { numOfSquareBrackets -= .one }

            let numOfAllBrackets = numOfBrackets + numOfBrackets + numOfSquareBrackets

            currentParam.append(char)

            if numOfAllBrackets == .zero && (char == .comma || index == inputIndices.last) {
                params.append(
                    indent + currentParam.trimmingCharacters(in: .whitespaces)
                )
                currentParam = .empty
            }
        }

        return params
    }
}
