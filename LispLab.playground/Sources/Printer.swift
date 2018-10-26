import Foundation

extension Metadata: Printable {
    public func print(with printer: Printer) {
        printer.pr ("(meta")
        printer.pr(value)
        printer.pr (")")
    }
}


public protocol Printable {
    func print(with: Printer)
}

//extension Reader.Token: Printable {
//    public func print(with printer: Printer) {
//        printer._pr(self.description)
//    }
//}

open class Printer {

    var spacer = "  "
    var indent_level: Int = 0

    public init() {
    }

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

    public func pr(_ any: Any?, indent: Int = 0) {
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
        } else if let printable = any as? Printable {
            printable.print(with: self)
        }
            // TODO: add formatter support
        else {
            _pr(any)
        }
    }
}

