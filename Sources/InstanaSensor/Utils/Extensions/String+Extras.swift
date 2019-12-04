//
//  File.swift
//  
//
//  Created by Christian Menschel on 04.12.19.
//

import Foundation

extension String {
    func truncated(at length: Int, trailing: String = "…") -> String {
        if count <= length {
            return self
        }
        let truncated = prefix(length)
        return truncated + trailing
    }
}
