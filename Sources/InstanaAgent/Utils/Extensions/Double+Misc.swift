import Foundation

extension Double {
    static func == (lhs: Double, rhs: Double) -> Bool {
        return abs(lhs - rhs) < 0.000001
    }

    static func != (lhs: Double, rhs: Double) -> Bool {
        return !(lhs == rhs)
    }
}
