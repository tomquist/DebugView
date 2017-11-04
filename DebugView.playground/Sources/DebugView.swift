import Foundation
import AppKit

extension Sequence {
    public var debug: SequenceDebugView<Self> {
        return SequenceDebugView(self)
    }
}

/// Stores a single transformation step made on a debug view
/// by storing the previous values and edges to the current state
public struct DebugViewTransformation {
    let name: String
    let sourceValues: AnySequence<Any>
    let edges: [Edge]
    let sourceType: Any.Type
    public init<S: Sequence>(name: String = #function, param: String? = nil, typeHint: String = String(describing: S.Element.self), sourceValues: S, edges: [Edge]) {
        let param = param.map { "(\($0))"} ?? ""
        self.name = "\(name)\(param)"
        self.sourceValues = AnySequence(sourceValues.lazy.map { $0 as Any })
        self.sourceType = S.self
        self.edges = edges
    }

    /// Describes an edge from the sourceValue to the current value
    public struct Edge {
        public let sourcePosition: Int?
        public let targetPosition: Int
    }
    
}

/// Debug view which wraps a value and stores transformation edges
public protocol DebugViewProtocol {
    associatedtype Element
    associatedtype Wrapped
    associatedtype SequenceType: Sequence where SequenceType.Element == Element
    var sequence: SequenceType { get }
    var transformations: [DebugViewTransformation] { get }
    
}

public struct ValueDebugView<T>: DebugViewProtocol {
    
    public typealias Element = T
    public typealias Wrapped = T
    public typealias SequenceType = CollectionOfOne<T>
    
    public let value: T
    
    public var sequence: CollectionOfOne<T> {
        return CollectionOfOne(value)
    }
    public let transformations: [DebugViewTransformation]
    
    public init(_ value: T, transformations: [DebugViewTransformation] = []) {
        self.value = value
        self.transformations = transformations
    }
    
}

public struct SequenceDebugView<S: Sequence>: DebugViewProtocol {
    
    public typealias Element = S.Element
    public typealias Wrapped = S
    public typealias SequenceType = S
    
    public let sequence: S
    public let transformations: [DebugViewTransformation]
    
    public init(_ sequence: S, transformations: [DebugViewTransformation] = []) {
        self.sequence = sequence
        self.transformations = transformations
    }
    
    private func createDebugView<T>(named name: String = #function, param: String? = nil, typeHint: String? = nil, from pairs: [(Int, T)]) -> SequenceDebugView<[T]> {
        let typeHint = typeHint ?? (S.Element.self == T.self ? "\(S.Element.self)" : "\(S.Element.self) -> \(T.self)")
        let result = pairs.map { $0.1 }
        let edges = zip(pairs.map { $0.0 }, 0...).map { DebugViewTransformation.Edge(sourcePosition: $0.0, targetPosition: $0.1) }
        let debugEntry = DebugViewTransformation(name: name, param: param, typeHint: typeHint, sourceValues: sequence, edges: edges)
        return SequenceDebugView<[T]>(result, transformations: transformations + [debugEntry])
    }
    
}

extension SequenceDebugView {
    
    public func map<T>(_ transform: (S.Element) throws -> T) rethrows -> SequenceDebugView<[T]> {
        let pairs = try sequence.enumerated().map { try ($0.offset, transform($0.element)) }
        return createDebugView(from: pairs)
    }
    
    public func filter(_ isIncluded: (S.Element) throws -> Bool) rethrows -> SequenceDebugView<[S.Element]> {
        let pairs = try sequence.enumerated().filter { try isIncluded($0.element) }
        return createDebugView(from: pairs)
    }
    
    public func sorted(by isOrderedBefore: (S.Element, S.Element) throws -> Bool) rethrows -> SequenceDebugView<[S.Element]> {
        let pairs = try sequence.enumerated().sorted { try isOrderedBefore($0.element, $1.element) }
        return createDebugView(from: pairs)
    }
    
    public func flatMap<T>(_ transform: (S.Element) throws -> T?) rethrows -> SequenceDebugView<[T]> {
        let pairs = try sequence.enumerated().flatMap { item in try transform(item.element).map { (item.offset, $0) } }
        return createDebugView(from: pairs)
    }
    
    public func first(where predicate: (S.Element) -> Bool) -> ValueDebugView<S.Element?> {
        let pair = sequence.enumerated().first(where: { predicate($0.element) })
        let entry = DebugViewTransformation(sourceValues: sequence, edges: [DebugViewTransformation.Edge(sourcePosition: pair?.offset, targetPosition: 0)])
        return ValueDebugView(pair?.element, transformations: transformations + [entry])
    }
    
    public func dropFirst(_ n: Int = 1) -> SequenceDebugView<[S.Element]> {
        let pairs = sequence.enumerated().dropFirst(n)
        return createDebugView(param: n == 1 ? "" : String(n), from: Array(pairs))
    }
    
    public func drop(while predicate: (S.Element) -> Bool) -> SequenceDebugView<[S.Element]> {
        let pairs = sequence.enumerated().drop(while: { predicate($0.element) })
        return createDebugView(from: Array(pairs))
    }
    
    public func prefix(while predicate: (S.Element) -> Bool) -> SequenceDebugView<[S.Element]> {
        let pairs = sequence.enumerated().prefix(while: { predicate($0.element) })
        return createDebugView(from: Array(pairs))
    }
    
    public func dropLast(_ n: Int = 1) -> SequenceDebugView<[S.Element]> {
        let pairs = sequence.enumerated().dropLast(n)
        return createDebugView(param: n == 1 ? "" : String(n), from: Array(pairs))
    }
    
    public func flatMap<S1: Sequence>(_ transform: (S.Element) throws -> S1) rethrows -> SequenceDebugView<[S1.Element]> {
        let pairs = try sequence.enumerated().flatMap { offset, element -> AnySequence<(Int, S1.Element)> in
            let result = try transform(element)
            return AnySequence(zip((0...).lazy.map { _ in offset }, result))
        }
        return createDebugView(from: pairs)
    }
    
    public func reversed() -> SequenceDebugView<[S.Element]> {
        let pairs = sequence.enumerated().reversed()
        return createDebugView(from: Array(pairs))
    }
    
    public func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, S.Element) throws -> Result) rethrows -> ValueDebugView<Result> {
        let result = try sequence.reduce(initialResult, nextPartialResult)
        let edges = sequence.enumerated().map { DebugViewTransformation.Edge(sourcePosition: $0.offset, targetPosition: 0) }
        let entry = DebugViewTransformation(sourceValues: sequence, edges: edges)
        return ValueDebugView(result, transformations: transformations + [entry])
    }
    
}

extension SequenceDebugView where S.Element: Hashable {
    public func unique() -> SequenceDebugView<[S.Element]> {
        var seen: [S.Element: Int] = [:]
        var edges: [DebugViewTransformation.Edge] = []
        var result: [S.Element] = []
        for (pos, item) in sequence.enumerated() {
            let targetPos = seen[item]
            edges.append(DebugViewTransformation.Edge(sourcePosition: pos, targetPosition: targetPos ?? result.count))
            if targetPos == nil {
                seen[item] = result.count
                result.append(item)
            }
        }
        let debugEntry = DebugViewTransformation(sourceValues: sequence, edges: edges)
        return SequenceDebugView<[S.Element]>(result, transformations: transformations + [debugEntry])
    }
}

extension Sequence where Element: Hashable {
    public func unique() -> [Element] {
        var seen: [Element: Bool] = [:]
        return filter { seen.updateValue(true, forKey: $0) == nil }
    }
}

extension SequenceDebugView where S.Element: Comparable {
    public func sorted() -> SequenceDebugView<[S.Element]> {
        return sorted(by: <)
    }
}

extension SequenceDebugView where S: Collection {
    public var first: ValueDebugView<S.Element?> {
        let value = sequence.first
        let entry = DebugViewTransformation(sourceValues: sequence, edges: [DebugViewTransformation.Edge(sourcePosition: value.map { _ in 0 }, targetPosition: 0)])
        return ValueDebugView(value, transformations: transformations + [entry])
    }
}

extension DebugViewProtocol {
    public func asGraphviz() -> String {
        let operationNodes = zip(0..., transformations).map { nodePos, entry -> String in
            "op\(nodePos) [label=\"\(entry.name.htmlEscaped)\"];"
        }
        let allSequences: [AnySequence<Any>] = transformations.map { $0.sourceValues } + [AnySequence(sequence.lazy.map { $0 as Any })]
        let allElementTypes = transformations.map { $0.sourceType } + [Wrapped.self]
        let legendNodes = allElementTypes.enumerated().map { type -> String in
            return "legend\(type.offset) [label=\"\(String(describing: type.element).htmlEscaped)\"];"
        }
        let legendLinks = (0..<transformations.count).map { "legend\($0) -> op\($0)"}.joined(separator: " -> ") + " -> legend\(transformations.count)"
        let nodes = allSequences.enumerated().map { sequence -> String in
            let labels = zip(0..., sequence.element).map { offset, item -> String in
                return "<f\(offset)> \(String(describing: item).htmlEscaped)"
            }.joined(separator: "|")
            return "node\(sequence.offset)[label=\"\(labels)\"];"
        }
        let ranks = (0...transformations.count).map { "{ rank=same; node\($0) legend\($0) }" }
        let links = transformations.enumerated().flatMap { nodePos, entry -> [String] in
            return entry.edges.map { edge -> String in
                let attributes = edge.sourcePosition != nil ? "" : "[penwidth=0.0,arrowhead=none]"
                return "\"node\(nodePos)\":f\(edge.sourcePosition ?? 0) -> \"node\(nodePos + 1)\":f\(edge.targetPosition)\(attributes);"
            }
        }
        return """
        digraph g {
            rankdir=LR;
            splines=false;
            node [shape=record,height=.1];
            \((nodes + links).joined(separator: "\n    "))
            node [shape=none]
            edge [penwidth=0.0,arrowhead=none]
            \(ranks.joined(separator: "\n    "))
            \(legendNodes.joined(separator: "\n    "))
            node [shape=rarrow]
            \(operationNodes.joined(separator: "\n    "))
            \(legendLinks)
        }
        """
    }
    
    public func render() -> NSImage? {
        return asGraphviz().dotImage
    }
}
