//
//  LenientDouble.swift
//  SaltScanCore
//
//  Open Food Facts serialises some numeric fields as strings ("28", "0,5").
//  Decoding them strictly made whole products fail to decode.
//

import Foundation

public struct LenientDouble: Codable, Sendable, Equatable {
    public let value: Double?

    public init(_ value: Double?) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
        } else if let number = try? container.decode(Double.self) {
            value = number
        } else if let text = try? container.decode(String.self) {
            let normalised = text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
            value = Double(normalised)
        } else {
            value = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
