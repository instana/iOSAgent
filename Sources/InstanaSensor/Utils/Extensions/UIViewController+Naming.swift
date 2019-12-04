//
//  File.swift
//  
//
//  Created by Christian Menschel on 05.12.19.
//

import UIKit

// TODO: Test this
extension UIViewController {
    var hiercharchyName: String {
        let t = type(of: self)
        var name = String(describing: t)
        if let title = (title ?? restorationIdentifier ?? nibName) {
            name += " - (" + title + ")"
        }
        return name
    }
}
