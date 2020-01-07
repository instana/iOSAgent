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
