import Foundation

public struct Metadata: CustomStringConvertible {
    public let value: Any
    public var description: String { return "(meta \(value))"}
}

public struct Symbol: CustomStringConvertible, Equatable, Hashable {
    public let name: String

    public init(_ value: String) {
        self.name = value
    }

    public init(stringLiteral value: String) {
        self.name = value
    }

    public var description: String { return name }
    public var hashValue: Int { return name.hashValue }

    public static func == (lhs: Symbol, rhs: Symbol) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}


extension String: Error {}

open class Reader {

    let token_guards = CharacterSet(charactersIn: ",(){}[] \t\n")
    let symbol_starts = CharacterSet.letters

    var scanner: StringScanner

    public init (_ s: String) {
        scanner = StringScanner(s)
    }

    public func scanNumber() throws -> Any {
        let num = try scanner.scanFloat()
//        var num = try scanner.scanInt()
//        let c = try scanner.peekChar()
//        if c == "." {
//            let _ = try scanner.scanChar()
//            if CharacterSet.decimalDigits.contains (try scanner.peekChar()) {
//                let p = try scanner.scanInt()
//                var d = Double(num)
//                d = d + (1.0 / Double(p))
//                return d
//            }
//        }
        return num
    }

    open func read() throws -> Any? {

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
//            let num = try scanNumber()
            let pc = try scanner.peekChar()
            if CharacterSet.letters.contains(pc), let unit_token = (try? read())! {
                let list: Sexpr<Any> = [num, unit_token]
                return list
            } else if pc == "_" {
                let _ = try? scanner.scanChar()
                if let unit_token = (try? read())! {
                    let list: Sexpr<Any> = [num, unit_token]
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
            var list = Sexpr<Any>()
            while let nob = try read() {
                if let s = nob as? String, s == ")" { break }
                list.append(nob)
            }
            return list // ch

        case ")": try scanner.scanChar(); return ")"

        case "[":
            try scanner.scanChar();
            var list = [Any]()
            while let nob = try read() {
                if let s = nob as? String, s == "]" { break }
                list.append(nob)
            }
            return list // ch

        case "]": try scanner.scanChar(); return "]"

        case "{":
            try scanner.scanChar();
            var map = [AnyHashable:Any]()
            while true {
                let ch = try scanner.peekChar()
                if ch == "}" { try scanner.scanChar(); return map }
                if let k = try read() as? AnyHashable, let v = try read() {
                    map[k] = v
                } else {
                    throw "ERROR in map at \(scanner.position)"
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
