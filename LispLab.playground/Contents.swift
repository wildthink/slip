import Cocoa

// https://github.com/malcommac/SwiftScanner#peekUpUntilInCharset
// http://www.buildyourownlisp.com/contents
// https://github.com/ajpocus/mal/blob/master/process/guide.md


//extension Optional: Equatable where Wrapped == Equatable {}

typealias SlipFunction = (_ op: Symbol, _ list: ArraySlice<Any>) throws -> Any?


open class Environment {

    var parent: Environment?
    var values: [AnyHashable: Any] = [:]
    var functions: [String: SlipFunction] = [:]

    func evaluate(_ str: String) throws -> Any? {
        let reader = Reader(str)
        let e = try reader.read()
        return try evaluate(e)
    }

    func evaluate(_ any: Any?) throws -> Any? {
        guard let any = any else { return nil }

        let base = any

        switch base {
        case let map as [AnyHashable:Any]:
            var emap = [AnyHashable:Any]()
            for (k, v) in map {
                emap[k] = try evaluate(v as? AnyHashable)
            }
            return emap

        case let list as Sexpr<Any>:
            guard !list.isEmpty else { return list }
            var elist = [Any]()
            for v in list { elist.append(try evaluate(v)!) }
            guard let op = elist.first as? Symbol else {
                return nil
            }
            return try apply (op: op, list: elist.suffix(from: 1))

        case let array as [Any]:
            var earray = [Any]()
            for v in array { earray.append(try evaluate(v)!) }
            return earray

        case let token as Reader.Token:
            switch token {
            case .string(let s): return s
            case .symbol(let s):
                if let v = values[s] { return v }
                return Symbol(s)
            case .keyword(let s):
                return s
            }
        default:
            return any
        }
    }

    func apply (op: Symbol, list: ArraySlice<Any>) throws -> Any? {

        switch op.name {
        case "+":
            var sum: Float = 0
            for n in list {
                guard let n = n as? Float else {
                    throw "Bad argument to \(op.name)"
                }
                sum += n
            }
            return sum
        case "*":
            var result: Float = 1
            for n in list {
                guard let n = n as? Float else {
                    throw "Bad argument to \(op.name)"
                }
                result *= n
            }
            return result
        default:
            if let f = functions[op.name] {
                return try f(op, list)
            }
            return try parent?.apply(op: op, list: list)
        }
    }

    func setf(_ name: String, to function: @escaping SlipFunction) {
        functions[name] = function
    }

}

var str = """
    (<= [1 -2.4] - foo,
^{doc: "doxs" ndx: 23} Bar { a: 1 :b "str"}
    )
"""

let rdr = Reader(str)
let printer = Printer()

//try? rdr.read()

while let token = try rdr.read() {
//    guard let token = token else { break }
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

print("===============")

let env = Environment()
env.setf("cat") { (sym, list) -> Any? in
    var str = ""
    for item in list {
        str += "\(item)"
    }
    return str
}

let r3 = Reader("(+ 1 2 3 4.5)")
let s3 = try! r3.read()!
//Swift.print(s3)

if let sum = try env.evaluate(s3) {
    Swift.print (sum)
}

if let result = try? env.evaluate("(+)")! {
    Swift.print("sum", result)
}

if let result = try? env.evaluate("(* 3 4 8.9)")! {
    Swift.print("product", result)
}

if let result = try? env.evaluate("(cat 3 4 8.9)")! {
    Swift.print("cat", result)
}

//printer.pr (
