import Cocoa

// https://github.com/malcommac/SwiftScanner#peekUpUntilInCharset

extension StringScanner {

    public func peekChar(_ offset: Int = 0) throws -> UnicodeScalar {
        guard self.position != self.string.endIndex else {
            throw StringScannerError.eof
        }
        return self.string[self.position]
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
    var name: String

    var description: String { return "\(type): '\(name)'"}
}


class Reader {

    let token_guards = CharacterSet(charactersIn: "(){}[] \t\n")

    var scanner: StringScanner

    init (_ s: String) {
        scanner = StringScanner(s)
    }

    func read() throws -> AnyHashable? {
        guard !scanner.isAtEnd else { return nil }
//        while !scanner.isAtEnd {
            try scanner.skipWhitespace()
            let c = try scanner.peekChar()
            switch  c {

            case "a"..."z", "A"..."Z":
                if let token = try scanner.scan(upTo: token_guards) {
//                    print ("symbol:", token)
                    return Token(type: "word", name: token)
                }
            case "0"..."9":
                let num = try scanner.scanFloat()
//                print (num)
                return num

            case "\"":
                try scanner.scanChar()
                if let token = try scanner.scan(upTo: "\"") {
                    try scanner.scanChar()
//                    print ("string:", token)
                    return Token(type: "string", name: token)
                }
                // Compound data structures read() recursively
            case "(":
                try scanner.scanChar();
                var list = [AnyHashable]()
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
//                    try read()
//                    try read()
                    if let k = try read(), let v = try read() {
//                        Swift.print ("map", k, v)
                        map[k] = v
                    }
                }
                return map // ch

            case "}": let ch = try scanner.scanChar(); return ch

            default:
//                print (ch)
                if let token = try scanner.scan(upTo: token_guards) {
//                    print ("Token:", token)
                    return Token(type: "special", name: token)
                } else {
                    let ch = try scanner.scanChar()
                    return ch
                }
            }
//        }
        return nil
    }
}

class Printer {

//    var level: Int = 0
//    var indent: Int = 2
    var spacer = "  "

    func _pr (_ key: Any, _ value: Any) {
        Swift.print (key, ":", value)
    }

    func _pr (_ any: Any, repeat count: Int = 0) {
        if count > 0 {
            for _ in 0...count {
                Swift.print (any, terminator: "")
            }
        } else {
            Swift.print (any)
        }
    }

    func pr(_ any: Any?, indent: Int = 0) {
        guard let any = any else { _pr("nil"); return }

        _pr (spacer, repeat: indent)

        if let map = any as? [AnyHashable:AnyHashable] {
            _pr ("{")
            for (k, v) in map {
                _pr (spacer, repeat: indent + 1)
                _pr(k, v)
            }
            _pr (spacer, repeat: indent)
            _pr ("}")
        }
        else if let list = any as? [AnyHashable] {
            _pr ("(")
            for v in list { pr(v, indent: indent + 1) }
            _pr (spacer, repeat: indent)
            _pr (")")
        }
        else {
            _pr(any)
        }
    }
}


var str = " (<= [1 2.4] foo, { a: 1 b: \"str\"})\n"

let rdr = Reader(str)
let printer = Printer()

//try? rdr.read()

while let token = try? rdr.read() {
    guard let token = token else { break }
    printer.pr(token)
//    Swift.print (type(of: token), token)
}

//let sa = Array(str)
//sa.count
//print (String(sa))
try? rdr.read()


