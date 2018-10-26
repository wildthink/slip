import Cocoa

// https://github.com/malcommac/SwiftScanner#peekUpUntilInCharset
// http://www.buildyourownlisp.com/contents
// https://github.com/ajpocus/mal/blob/master/process/guide.md


//extension Optional: Equatable where Wrapped == Equatable {}


open class Environment {

    var parent: Environment?
    var values: [AnyHashable: AnyHashable] = [:]

    func evaluate(_ any: AnyHashable?) -> AnyHashable? {
        guard let any = any else { return nil }

        if let map = any as? [AnyHashable:AnyHashable] {
            var emap = [AnyHashable:AnyHashable]()
            for (k, v) in map {
                emap[k] = evaluate(v)
            }
            return emap
        }
        else if let list = any as? List<AnyHashable?> {
            var elist = List<AnyHashable?>()
            for v in list { elist.append(evaluate(v)) }
            return elist
        }
        else if let array = any as? [AnyHashable?] {
            var earray = [AnyHashable?]()
            for v in array { earray.append(evaluate(v)!) }
            return earray
        }
        else if let token = any as? Reader.Token {
            switch token {
            case .string(let s): return s
            case .symbol(let s):
                if let v = values[s] { return v }
                return s
            default:
                return any
            }
        }
        else {
            return any
        }
    }
}

var str = """
    (<= [1 -2.4] - foo,
    ^{doc: "doxs"} Bar { a: 1 :b "str"}
    )
"""

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

let x: AnyHashable = 23
let y: AnyHashable = "asdfd"

x == y

print("===============")

let r2 = Reader("123.8_m/s")

while let token = try? r2.read() {
    guard let token = token else { break }
    printer.pr(token)
}


