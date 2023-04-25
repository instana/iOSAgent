import Foundation
#if SWIFT_PACKAGE
    import ImageTracker
#endif

struct DynamicLibraryInfo {
    let imageInMemory: Bool
    let address: UInt
    let architecture: String?
    let size: UInt
    let path: String?

    var symbolName: String?
    let symbolAddress: UInt

    init?(imageInMemory: Bool, address: UInt, architecture: String?, size: UInt, path: String?) {
        self.imageInMemory = imageInMemory
        self.address = address
        self.architecture = architecture
        self.size = size

        if imageInMemory {
            let ptr = UnsafeRawPointer(bitPattern: address)
            var infoObj = Dl_info()

            guard dladdr(ptr, &infoObj) != 0 else {
                return nil
            }
            self.path = infoObj.dli_fname.map(String.init(cString:))
            symbolName = infoObj.dli_sname.map(String.init(cString:))
            symbolAddress = infoObj.dli_saddr.map { UInt(bitPattern: $0) } ?? 0

        } else {
            self.path = path
            symbolName = nil
            symbolAddress = 0 // placeholder
        }
    }

    var symbolInfo: SymbolInfo? {
        if imageInMemory {
            return SymbolInfo(symbol: symbolName ?? "", offset: Int(address) - Int(symbolAddress))
        }
        // Symbol name and offset are not available if image is not in memory at this moment
        return nil
    }
}
