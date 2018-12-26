//import Cocoa
import SlipLib

// https://github.com/malcommac/SwiftScanner#peekUpUntilInCharset
// http://www.buildyourownlisp.com/contents
// https://github.com/ajpocus/mal/blob/master/process/guide.md


//extension Optional: Equatable where Wrapped == Equatable {}


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
        if let sv = item as? CustomStringConvertible {
            str += sv.description
        } else {
            str += "\(item)"
        }
    }
    return str
}

let r3 = Reader("(+ 1 2 3 4.5)")
let s3 = try! r3.read()!
//Swift.print(s3)

if let result = try env.read("23") {
    Swift.print(type(of: result), result)
}

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

extension Dictionary where Key == Reader.Token {
    subscript (_ key: String) -> Value? {
        let t = Reader.Token.keyword(key)
        return self[t]
    }
}

//extension Dictionary where Key == AnyHashable {
//    subscript (_ key: String) -> Value? {
//        return self[key]
//    }
//}

do {
    let map = try env.read("{a: 1 :b 2} " ) as! [Reader.Token:Any]
        // as! NSDictionary
    Swift.print ("token?", map.first!.key is NSString)
//    let f = map.first!.key
//    let b = map.keys.contains("b")
    Swift.print ("a value?", map, map["a"])
    Swift.print ("b value?", map, map["b"])
//    Swift.print (map.keys, f, type(of: f))
}
catch let e {
    Swift.print (e)
}

let t1 = Reader.Token.keyword("a")
let t2 = Reader.Token.symbol("a")

let hk = AnyHashable("a")

Swift.print ("a".hashValue, t1.hashValue, t2.hashValue, t1.hashValue == t2.hashValue)

let dict:[AnyHashable:Any] = ["a": 1, "b": 2]
Swift.print (dict[hk])

Swift.print ("EOF", #line)

//printer.pr (
