import Foundation

public typealias SlipFunction = (_ op: Symbol, _ list: ArraySlice<Any>) throws -> Any?


open class Environment {

    var parent: Environment?
    var values: [AnyHashable: Any] = [:]
    var functions: [String: SlipFunction] = [:]

    public init() {
    }

    open func read(_ str: String) throws -> Any? {
        let reader = Reader(str)
        return try reader.read()
    }

    open func evaluate(_ str: String) throws -> Any? {
        let reader = Reader(str)
        let e = try reader.read()
        return try evaluate(e)
    }

    open func evaluate(_ any: Any?) throws -> Any? {
        guard let base = any else { return nil }

//        Swift.print(#function, base)

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

    open func apply (op: Symbol, list: ArraySlice<Any>) throws -> Any? {

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

    open func setf(_ name: String, to function: @escaping SlipFunction) {
        functions[name] = function
    }

}
