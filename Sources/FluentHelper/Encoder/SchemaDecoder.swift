//
//  File.swift
//  
//
//  Created by Данил Войдилов on 13.01.2022.
//

import Foundation
import VDCodable

public final class SchemaDecoder: DecodingUnboxer {
	
	public typealias Input = JSON
	public var codingPath: [CodingKey] = []
	public var input: JSON
	private var isArray = false
	private var isKeyed = false
	var scheme = ModelSchema()
	public var dateStrategy: VDJSONDecoder.DateDecodingStrategy
	
	public init(input: JSON, dateStrategy: VDJSONDecoder.DateDecodingStrategy) {
		self.input = input
		self.dateStrategy = dateStrategy
	}
	
	public init(input: JSON, path: [CodingKey], other unboxer: SchemaDecoder) {
		self.input = input
		self.codingPath = path
		self.dateStrategy = unboxer.dateStrategy
		if unboxer.isKeyed, let key = path.last?.stringValue {
			unboxer.scheme.set(scheme: scheme, key: key)
		} else if unboxer.isArray {
			unboxer.scheme.items = scheme
		} else {
			unboxer.scheme = scheme
		}
	}
	
	public func decodeArray() throws -> [JSON] {
		isArray = true
		scheme.set(type: .array)
		var result = input.array ?? []
		if result.isEmpty {
			result = [.null]
		}
		return result
	}
	
	public func decodeDictionary() throws -> [String: JSON] {
		isKeyed = true
		scheme.type = "object"
		var dictionary = input.object ?? [:]
		dictionary[""] = .null
		return dictionary
	}
	
	public func decode(_ type: Bool.Type) throws -> Bool {
		try _decode({ $0.bool ?? false }, type: .boolean)
	}
	
	public func decode(_ type: String.Type) throws -> String {
		try _decode({ $0.string ?? "" }, type: .string)
	}
	
	public func decode(_ type: Double.Type) throws -> Double {
		try _decode({ $0.double ?? 0 }, type: .double)
	}
	
	public func decode(_ type: Int.Type) throws -> Int {
		try _decode({ $0.int ?? 0 }, type: MemoryLayout<Int>.size == MemoryLayout<Int32>.size ? .int32 : .int64)
	}
	
	public func decode(_ type: Int32.Type) throws -> Int32 {
		try _decode({ Int32($0.int ?? 0) }, type: .int32)
	}
	
	public func decode(_ type: Int64.Type) throws -> Int64 {
		try _decode({ Int64($0.int ?? 0) }, type: .int64)
	}
	
	private func _decode<T>(_ get: (JSON) throws -> T, type: APIDataType) throws -> T {
		let result = try get(input)
		scheme.set(type: type)
		return result
	}
	
	public func decode<T: Decodable>(_ type: T.Type) throws -> T {
		if type == Decimal.self {
			return try Decimal(decode(Double.self)) as! T
		}
		if type == UUID.self {
			return try decode(UUID.self) as! T
		}
		if type == Date.self {
			return try decode(Date.self) as! T
		}
		do {
			let decoder = VDDecoder(unboxer: self)
			defer {
				if isKeyed {
					if scheme.properties?[""] == nil {
						scheme.format = String(describing: T.self)
					} else {
						scheme.additionalProperties = scheme.properties?.first(where: { !$0.key.isEmpty })?.value ?? scheme.properties?[""]
						scheme.properties = nil
					}
				}
			}
			let result = try T.init(from: decoder)
			return result
		} catch {
			let result = try VDJSONDecoder(dateDecodingStrategy: dateStrategy).decode(T.self, json: input)
			return result
		}
	}
	
	public func decode(_ type: UUID.Type) throws -> UUID {
		try _decode({ UUID(uuidString: $0.string ?? "") ?? UUID() }, type: .uuid)
	}
	
	public func decode(_ type: Date.Type) throws -> Date {
		let decoder = VDJSONDecoder(dateDecodingStrategy: dateStrategy)
		return try _decode({ (try? decoder.decode(Date.self, json: $0)) ?? Date() }, type: .date)
	}
	
	public func decodeNil() -> Bool { false }
	public func contains(key: String) -> Bool { true }
	public func decodeNilOnFailure(key: CodingKey) -> Bool { true }
	public func decodeFor(unknown key: CodingKey) throws -> JSON? { .null }
}
