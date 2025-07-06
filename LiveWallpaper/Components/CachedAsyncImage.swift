import SwiftUI
import CryptoKit

struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let size: CGSize
    let placeholder: () -> Placeholder
    
    @State private var image: NSImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
            } else {
                placeholder()
                    .frame(width: size.width, height: size.height)
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let url = url else { return }
        
        // 1️⃣ Check local disk cache
        if let cachedImage = loadFromDiskCache(for: url) {
            self.image = cachedImage
            print("cached \(url)")
            return
        }
        
        // 2️⃣ Download image if not cached
        print("fetch \(url)")
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let downloadedImage = NSImage(data: data) {
                DispatchQueue.main.async {
                    self.image = downloadedImage
                }
                
                // 3️⃣ Save the image to cache
                saveToDiskCache(imageData: data, for: url)
            }
        }.resume()
    }
    
    // MARK: - Disk Cache Helpers
    private func cacheDirectory() -> URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }
    
    private func cacheFileURL(for url: URL) -> URL? {
        let hashedFilename = fnv1aHash(url.absoluteString) + ".cache"
        return cacheDirectory()?.appendingPathComponent(hashedFilename)
    }
    
    private func loadFromDiskCache(for url: URL) -> NSImage? {
        guard let fileURL = cacheFileURL(for: url),
              FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return NSImage(data: data)
    }
    
    private func saveToDiskCache(imageData: Data, for url: URL) {
        guard let fileURL = cacheFileURL(for: url) else { return }
        try? imageData.write(to: fileURL, options: .atomic)
    }
    
    // MARK: - FNV-1a Hash Function
    private func fnv1aHash(_ input: String) -> String {
        let prime: UInt64 = 1099511628211
        let offsetBasis: UInt64 = 14695981039346656037
        var hash: UInt64 = offsetBasis
        
        for byte in input.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        
        return String(format: "%016llx", hash) // Convert to hex string
    }
}
