//
//  File.swift
//  
//
//  Created by Christian Menschel on 24.06.22.
//

import Foundation
@testable import InstanaAgent

extension InstanaConfiguration: Equatable {
    public static func ==(lhs: InstanaConfiguration, rhs: InstanaConfiguration) -> Bool {
        String(dumping: lhs) == String(dumping: rhs)
    }
}

extension String {
    /**
     Creates a string from the `dump` output of the
     given value.
     */
    init<T>(dumping x: T) {
        self.init()
        dump(x, to: &self)
    }
}
