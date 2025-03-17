//
//  Utilities.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/9.
//
import Foundation

public struct IdentifiedCollection<Element: Identifiable & Hashable>:
    RandomAccessCollection
{
    private var elements: [Element]
    private var elementsByID: [Element.ID: Int]  // store index for O(1) lookups

    public init(_ elements: [Element] = []) {
        self.elements = elements
        self.elementsByID = Dictionary(
            uniqueKeysWithValues: elements.enumerated().map {
                (index, element) in
                (element.id, index)
            }
        )
    }

    // MARK: - RandomAccessCollection

    public var startIndex: Int { elements.startIndex }
    public var endIndex: Int { elements.endIndex }

    public func index(after i: Int) -> Int {
        elements.index(after: i)
    }

    public subscript(position: Int) -> Element {
        elements[position]
    }

    // MARK: - Custom lookups

    public subscript(id id: Element.ID) -> Element? {
        guard let idx = elementsByID[id] else { return nil }
        return elements[idx]
    }

    // Example mutation
    public mutating func append(_ element: Element) {
        elements.append(element)
        elementsByID[element.id] = elements.endIndex - 1
    }
    
    /// Removes the element with the given ID, if it exists.
    /// Returns the removed element or nil if not found.
    ///
    /// **Note:** Removing from the middle of the array is O(n),
    /// because we have to shift elements and update their indices.
    @discardableResult
    public mutating func remove(id: Element.ID) -> Element? {
        guard let index = elementsByID[id] else {
            return nil
        }
        
        // Remove the element from the array
        let removedElement = elements.remove(at: index)
        
        // Remove the ID from our dictionary
        elementsByID[id] = nil
        
        // Update indices for all elements after the removed index
        for i in index..<elements.count {
            elementsByID[elements[i].id] = i
        }
        
        return removedElement
    }
    
    /// Removes and returns the element at the specified index.
    ///
    /// **Note:** Removing from the middle is O(n) because of shifting elements
    /// and updating dictionary entries for subsequent items.
    @discardableResult
    public mutating func remove(at index: Int) -> Element {
        precondition(index >= startIndex && index < endIndex, "Index out of range.")
        
        let removedElement = elements.remove(at: index)
        elementsByID[removedElement.id] = nil
        
        // Update dictionary entries for all subsequent elements
        for i in index..<elements.count {
            elementsByID[elements[i].id] = i
        }
        
        return removedElement
    }
}

public extension URLRequest {
    var debugDescription: String {
        var description = "URL: \(url?.absoluteString ?? "No URL")\n"
        description += "HTTP Method: \(httpMethod ?? "No HTTP Method")\n"
        description += "Headers: \(allHTTPHeaderFields ?? [:])\n"
        if let bodyData = httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            description += "HTTP Body: \(bodyString)\n"
        } else {
            description += "No HTTP Body\n"
        }
        return description
    }
}

public extension Date.ISO8601FormatStyle {
    static let iso8601withFractionalSeconds: Self = .init(includingFractionalSeconds: true)
}

public extension ParseStrategy where Self == Date.ISO8601FormatStyle {
    static var iso8601withFractionalSeconds: Date.ISO8601FormatStyle { .iso8601withFractionalSeconds }
}

public extension FormatStyle where Self == Date.ISO8601FormatStyle {
    static var iso8601withFractionalSeconds: Date.ISO8601FormatStyle { .iso8601withFractionalSeconds }
}

public extension Date {

    init(iso8601withFractionalSeconds parseInput: ParseStrategy.ParseInput) throws {
        try self.init(parseInput, strategy: .iso8601withFractionalSeconds)
    }

    var iso8601withFractionalSeconds: String {
        formatted(.iso8601withFractionalSeconds)
    }
}

public extension String {
    func iso8601withFractionalSeconds() throws -> Date {
        try .init(iso8601withFractionalSeconds: self)
    }
}

public extension JSONDecoder.DateDecodingStrategy {
    static let iso8601withFractionalSeconds = custom {
        try .init(iso8601withFractionalSeconds: $0.singleValueContainer().decode(String.self))
    }
}

public extension JSONEncoder.DateEncodingStrategy {
    static let iso8601withFractionalSeconds = custom {
        var container = $1.singleValueContainer()
        try container.encode($0.iso8601withFractionalSeconds)
    }
}
