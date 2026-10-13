//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation

@objc
public enum MaskingStrategy: Int {
    case mask_all = 0
    case mask_input_fields // mask input text and label
    case mask_sensitive
    case mask_none      // for debug only
}
