import Foundation

enum ClusterSide {
    case top, bottom
}

public class Cluster: Identifiable, Hashable {
    
    public var pixels: [Pixel]
    
    public init(_ pixels: Pixel...) {
        self.pixels = pixels
    }
    
    public func isNeighbored(to pixel: Pixel) -> Bool {
        pixels.first(where: {
            $0.x >= pixel.x - 1 &&
                $0.x <= pixel.x + 1 &&
                $0.y >= pixel.y - 1 &&
                $0.y <= pixel.y + 1
        }) != nil
    }
    
    // TODO: Use the center of the pixels
    public func center() -> Pixel? {
        let box = boundingBox()
        
        let width = Double(box.maxX - (box.minX - 1))
        let centerX = Int(width / 2 + Double(box.minX))
        
        let height = Double(box.maxY - (box.minY - 1))
        let centerY = Int(height / 2 + Double(box.minY))
        
        print(centerX, centerY)
        
//        let centerX = (((box.maxX - (box.minX - 1)) + box.minX) - 1)
//        let centerY = (((box.maxY - (box.minY - 1)) + box.minY) - 1)
        
//        let index = index(for: centerY - 1, and: centerX - 1)
        
//        return Pixel(x: centerX, y: centerY, temp: 0)
        
//        return pixels.first(where: {
//            $0.x == centerX && $0.x == centerY
//        })!
        
//        return pixels[index]
        
//        pixels
        return nil
        
//        return pixels.reduce(pixels[0]) { result, pixel in
//            result.temp > pixel.temp ? result : pixel
//        }
    }
    
    public func tempCenter() -> Pixel {
        return pixels.reduce(pixels[0]) { result, pixel in
            result.temp > pixel.temp ? result : pixel
        }
    }
    
    func index(for row: Int, and column: Int, width: Int = 8) -> Int {
        return (row * width) + column
    }
    
    public func boundingBox() -> (minX: Int, minY: Int, maxX: Int, maxY: Int) {
        var minX: Int = Int.max
        var minY: Int = Int.max
        var maxX: Int = Int.min
        var maxY: Int = Int.min
        
        pixels.forEach {
            minX = min(minX, $0.x)
            minY = min(minY, $0.y)
            
            maxX = max(maxX, $0.x)
            maxY = max(maxY, $0.y)
        }
        
        return (minX, minY, maxX, maxY)
    }
    
    public static func == (lhs: Cluster, rhs: Cluster) -> Bool {
        lhs.pixels == rhs.pixels
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(pixels)
    }
    
    func contains(_ pixel: Pixel) -> Bool {
        pixels.contains(pixel)
    }
    
    var size: Int { pixels.count }
    
    var clusterSide: ClusterSide {
        if tempCenter().y > 4 {
            return .bottom
        } else {
            return .top
        }
    }
}

extension Array where Element: Cluster {
    func contains(_ element: Pixel) -> Bool {
        self.first(where: { $0.contains(element)} ) != nil
    }
    
    func largest() -> Cluster? {
        self.reduce(nil) { result, cluster in
            guard let previous = result else {
                return cluster
            }
            if cluster.size > previous.size {
                return cluster
            }
            return previous
        }
    }
}
