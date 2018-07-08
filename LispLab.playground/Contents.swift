import Cocoa

// https://github.com/malcommac/SwiftScanner#peekUpUntilInCharset
// http://www.buildyourownlisp.com/contents
// https://github.com/ajpocus/mal/blob/master/process/guide.md

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

struct Token: CustomStringConvertible, Hashable {

    var type: String
    var value: String

    var description: String { return "(\(type): '\(value)')"}
}

extension Token {
    init(string: String) {
        self.type = "string"
        self.value = string
    }
    init(symbol: String) {
        self.type = "symbol"
        self.value = symbol
    }
    init(keyword: String) {
        self.type = "keyword"
        self.value = keyword
    }
}


class Reader {

    let token_guards = CharacterSet(charactersIn: ",(){}[] \t\n")

    var scanner: StringScanner

    init (_ s: String) {
        scanner = StringScanner(s)
    }

    func read() throws -> AnyHashable? {

        guard !scanner.isAtEnd else { return nil }

        try scanner.skipWhitespace()
        let c = try scanner.peekChar()
        switch  c {

        case "a"..."z", "A"..."Z":
            if let token = try scanner.scan(upTo: token_guards) {
                return Token(symbol: token)
            }
        case "0"..."9":
            let num = try scanner.scanFloat()
            return num

        case "-":
            try scanner.scanChar()
            if CharacterSet.decimalDigits.contains(try scanner.peekChar()) {
                return -(try scanner.scanFloat())
            } else {
                return Token(symbol: "-")
            }
        case ",": try scanner.scanChar(); return try read() // commas are like whitespace
        case "\"":
            try scanner.scanChar()
            if let token = try scanner.scan(upTo: "\"") {
                try scanner.scanChar()
                return Token(string: token)
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
                    map[k] = v
                }
            }
            return map // ch

        case "}": let ch = try scanner.scanChar(); return ch

        default:
            if let token = try scanner.scan(upTo: token_guards) {
                return Token(type: "special", value: token)
            } else {
                let ch = try scanner.scanChar()
                return ch
            }
        }
        return nil
    }
}

class Printer {

    var spacer = "  "

    func _pr (_ key: Any, _ value: Any, indent: Int = 0) {
        _indent(indent)
        Swift.print (key, ":", value)
    }

    func _indent (_ count: Int = 0) {
        if count > 0 {
            for _ in 0...count {
                Swift.print (spacer, terminator: "")
            }
        }
    }

    func _pr (_ any: Any, indent: Int = 0) {
        _indent(indent)
        Swift.print (any)
    }

    func pr(_ any: Any?, indent: Int = 0) {
        guard let any = any else { _pr("nil"); return }

        _indent(indent)

        if let map = any as? [AnyHashable:AnyHashable] {
            _pr ("{")
            for (k, v) in map {
                _pr(k, v, indent: indent + 1)
            }
            _pr ("}", indent: indent)
        }
        else if let list = any as? List<AnyHashable> {
            _pr ("(")
            for v in list { pr(v, indent: indent + 1) }
            _pr (")", indent: indent)
        }
        else if let array = any as? [AnyHashable] {
            _pr ("[")
            for v in array { pr(v, indent: indent + 1) }
            _pr ("]", indent: indent)
        }
            // TODO: add formatter support
        else {
            _pr(any)
        }
    }
}


var str = " (<= [1 -2.4] - foo, { a: 1 b: \"str\"})\n"

let rdr = Reader(str)
let printer = Printer()

//try? rdr.read()

while let token = try? rdr.read() {
    guard let token = token else { break }
    printer.pr(token)
}

//let sa = Array(str)
//sa.count
//print (String(sa))
try? rdr.read()

