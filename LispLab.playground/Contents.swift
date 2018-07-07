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

struct Token: CustomStringConvertible {
    var type: String
    var name: String

    var description: String { return "\(type):\(name)"}
}

class Reader {

    let token_guards = CharacterSet(charactersIn: "(){}[] \t\n")

    var scanner: StringScanner

    init (_ s: String) {
        scanner = StringScanner(s)
    }

    func read() throws -> Any? {
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
            case "(": let ch = try scanner.scanChar(); return ch
            case ")": let ch = try scanner.scanChar(); return ch
            case "[": let ch = try scanner.scanChar(); return ch
            case "]": let ch = try scanner.scanChar(); return ch
            case "{": let ch = try scanner.scanChar(); return ch
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

var str = " (<= [1 2.4] foo, { a: 1, b: \"str\"})\n()"

let rdr = Reader(str)

//try? rdr.read()

while let token = try? rdr.read() {
    guard let token = token else { break }
    print (token)
}

//let sa = Array(str)
//sa.count
//print (String(sa))
try? rdr.read()

