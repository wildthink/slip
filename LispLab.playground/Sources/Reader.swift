import Foundation

public struct Metadata: Hashable, CustomStringConvertible {
    public let value: AnyHashable
    public var description: String { return "(meta \(value))"}
}

open class Reader {

    let token_guards = CharacterSet(charactersIn: ",(){}[] \t\n")
    let symbol_starts = CharacterSet.letters

    var scanner: StringScanner

    public init (_ s: String) {
        scanner = StringScanner(s)
    }

    open func read() throws -> AnyHashable? {

        guard !scanner.isAtEnd else { return nil }

        try scanner.skipWhitespace()
        let c = try scanner.peekChar()
        switch  c {

        case "a"..."z", "A"..."Z":
            if let token = try scanner.scan(upTo: token_guards) {
                return token.hasSuffix(":") ? Token.keyword(token) : Token.symbol(token)
            }
        case ":":
            try scanner.scanChar()
            if symbol_starts.contains(try scanner.peekChar()) {
                if let token = try scanner.scan(upTo: token_guards) {
                    return Token.keyword(token)
                }
            } else {
                //                return Token(symbol: ":")
                return Token.symbol(":")
            }

        case "^":
            try scanner.scanChar()
            if let token = try read() {
                return Metadata(value: token)
            }

        case "0"..."9":
            let num = try scanner.scanFloat()
            let pc = try scanner.peekChar()
            if CharacterSet.letters.contains(pc), let unit_token = (try? read())! {
                let list: List<AnyHashable> = [num, unit_token]
                return list
            } else if pc == "_" {
                try? scanner.scanChar()
                if let unit_token = (try? read())! {
                    let list: List<AnyHashable> = [num, unit_token]
                    return list
                } else {
                    return num
                }
            }
            return num

        case "-":
            try scanner.scanChar()
            if CharacterSet.decimalDigits.contains(try scanner.peekChar()) {
                return -(try scanner.scanFloat())
            } else {
                return Token.symbol("-")
            }
        case ",": try scanner.scanChar(); return try read() // commas are like whitespace
        case "\"":
            try scanner.scanChar()
            if let token = try scanner.scan(upTo: "\"") {
                try scanner.scanChar()
                return Token.string(token)
            }
        // Compound data structures read() recursively
        case "(":
            try scanner.scanChar();
            var list = List<AnyHashable>()
            while let nob = try read() {
                if let s = nob as? String, s == ")" { break }
                list.append(nob)
            }
            return list // ch

        case ")": try scanner.scanChar(); return ")"

        case "[":
            try scanner.scanChar();
            var list = [AnyHashable]()
            while let nob = try read() {
                if let s = nob as? String, s == "]" { break }
                list.append(nob)
            }
            return list // ch

        case "]": try scanner.scanChar(); return "]"

        case "{":
            try scanner.scanChar();
            var map = [AnyHashable:AnyHashable]()
            while true {
                let ch = try scanner.peekChar()
                if ch == "}" { try scanner.scanChar(); return map }
                if let k = try read(), let v = try read() {
                    //                    guard v != "}" else { return } // throw
                    map[k] = v
                }
            }
            return map // ch

        case "}": let ch = try scanner.scanChar(); return ch

        default:
            if let token = try scanner.scan(upTo: token_guards) {
                return Token.symbol(token)
            } else {
                let ch = try scanner.scanChar()
                return ch
            }
        }
        return nil
    }
}

extension Reader {
    public enum Token: CustomStringConvertible, Hashable {
        case symbol(String)
        case string(String)
        case keyword(String)

        public var description: String {
            switch self {
            case .symbol(let v): return v
            case .string(let v): return v
            case .keyword(let v): return v
            }
        }

        public var hashValue: Int  {
            switch self {
            case .symbol(let v): return v.hashValue
            case .string(let v): return v.hashValue
            case .keyword(let v): return v.hashValue
            }
        }
    }
}

extension StringScanner {

    public func peekChar(_ offset: Int = 0) throws -> UnicodeScalar {
        guard self.position != self.string.endIndex else {
            throw StringScannerError.eof
        }
        return self.string[self.position]
    }

    public func isNext(char: UnicodeScalar) throws -> Bool {
        guard self.position != self.string.endIndex else {
            throw StringScannerError.eof
        }
        return char == self.string[self.position]
    }

    public func skipWhitespace() throws {
        var ch = try peekChar()
        while CharacterSet.whitespacesAndNewlines.contains(ch) {
            try scanChar()
            ch = try peekChar()
        }
    }
}
