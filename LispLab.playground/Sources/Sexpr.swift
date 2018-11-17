import Foundation

public struct Sexpr<Element> {
    public typealias ListType = [Element]

    public private(set) var array = ListType()

    public init(array: ListType) {
        self.array = array
    }

    public mutating func append(_ item: Element) {
        array.append(item)
    }
}

extension Sexpr: Equatable where Element: Equatable {
    public static func ==(lhs: Sexpr<Element>, rhs: Sexpr<Element>) -> Bool {
        return lhs.array.elementsEqual(rhs.array)
    }
}

extension Sexpr: Hashable where Element: Hashable {
    public var hashValue: Int {
        return array.hashValue
    }
}

extension Sexpr: Collection {

    public typealias Index = ListType.Index

    public var startIndex: Index { return array.startIndex }
    public var endIndex: Index { return array.endIndex }

    public subscript(index: Index) -> Element {
        get { return array[index] }
        set { array[index] = newValue }
    }

    public func index(after i: Index) -> Index {
        return array.index(after: i)
    }
}

extension Sexpr: ExpressibleByArrayLiteral {

    public typealias ArrayLiteralElement = Element

    public init(arrayLiteral elements: ArrayLiteralElement...) {
        array = elements
    }
}
