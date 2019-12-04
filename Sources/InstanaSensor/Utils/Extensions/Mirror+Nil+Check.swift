//
//  File.swift
//  
//
//  Created by Christian Menschel on 29.11.19.
//

import Foundation

extension Mirror {
    typealias NonNilChild = (label: String, value: Any)
    var nonNilChildren: AnyCollection<NonNilChild> {
        return AnyCollection(children.compactMap { (label, value) -> NonNilChild? in
            guard let label = label else { return nil }
            let mirror = Mirror(reflecting: value)
            if mirror.displayStyle == .optional {
                guard let first = mirror.children.first?.value else {
                    return nil
                }
                return (label, first)
            } else {
                return (label, value)
            }
        })
    }

    static func isNotNil<T: Any>(value: T) -> Bool {
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            return mirror.children.first != nil
        } else {
            return true
        }
    }
}
