//
//  Cluster.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/20/21.
//


import Foundation

public class Cluster: Identifiable, Hashable {
    
    /// The side of the frame the Cluster is on.
    public enum ClusterSide: String, Equatable {
        case top, bottom
    }
    
    /// The Pixels that make up this cluster
    public var pixels: [Pixel] {
        didSet {
            centerCache = nil
        }
    }
    
    /// The previously calculated center
    fileprivate var centerCache: Pixel?
    
    
    /// The center of the Cluster
    public var center: Pixel {
        centerCache ?? calculateCenter()
    }
    
    
    /// The size of the Cluster
    public var size: Int { pixels.count }
    
    /// Which side of the dividing line the Cluster is on
    public var clusterSide: ClusterSide {
        if center.y > 4 {
            return .bottom
        } else {
            return .top
        }
    }
    
    /// Create a new Cluster
    /// - Parameter pixels: Pixels in the Cluster
    public init(_ pixels: Pixel...) {
        self.pixels = pixels
    }
    
    /// Determine whehter a Pixel neighbors the Cluster.
    /// - Parameter pixel: The Pixel to test
    /// - Returns: A boolean indicating whether the Pixel is a neighbor
    public func isNeighbored(to pixel: Pixel) -> Bool {
        pixels.first(where: {
            $0.x >= pixel.x - 1 &&
                $0.x <= pixel.x + 1 &&
                $0.y >= pixel.y - 1 &&
                $0.y <= pixel.y + 1
        }) != nil
    }
    
    /// Calculate the center of the Cluster.
    ///
    /// If the Pixel at the center of the Cluster is not actually in the Cluster,
    /// which can happen with irregularly shaped Clusters, the Pixel
    /// with the highest termpature is used.
    ///
    /// - Returns: The Pixel in the center
    func calculateCenter() -> Pixel {
        guard size > 0 else {
            return temperatureCenter()
        }
        
        let box = boundingBox()
        
        let width = Double(box.maxX - box.minX)
        let tempX = Double(box.minX) + width / 2
        
        let height = Double(box.maxY - box.minY)
        let tempY = Double(box.minY) + height / 2
        
        let centerX = Int(tempX.rounded())
        let centerY = Int(tempY.rounded())
        
        // Return the geometric center
        // If the geometric center can't be found, most likely due to
        // an iregular cluster, fallback to the temp center
        guard let center = pixels.first(where: {
            $0.x == centerX && $0.y == centerY
        }) else {
            return temperatureCenter()
        }
        
        return center

    }
    
    /// The Pixel with the highest termpature, often aat the center of the Cluster.
    /// - Returns: The Pixel in the center
    func temperatureCenter() -> Pixel {
        return pixels.reduce(pixels[0]) { result, pixel in
            result.temp > pixel.temp ? result : pixel
        }
    }
    
    /// Calculate the bounding box of the cluster
    /// - Returns: The four points making up the corners.
    func boundingBox() -> (minX: Int, minY: Int, maxX: Int, maxY: Int) {
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
    
    /// Convenience function to determine whether a Pixel is in the Cluster.
    /// - Parameter pixel: The element to find in the sequence.
    /// - Returns: true if the element was found in the sequence; otherwise, false.
    public func contains(_ pixel: Pixel) -> Bool {
        pixels.contains(pixel)
    }

    
    /// Print a textual representation of a grid of pixels.
    ///
    /// ```
    /// Bottom Cluser at Pixel (4, 5)
    /// ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░
    /// ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░
    /// ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░
    /// ░░ ┏  ▓▓ ▓▓ ▓▓  ┓ ░░ ░░
    /// ░░ ░░ ▓▓ ▓▓ ▓▓ ▓▓ ░░ ░░
    /// ░░ ░░ ▓▓ ╲╱ ▓▓ ░░ ░░ ░░
    /// ░░ ┗  ░░ ▓▓ ▓▓  ┛ ░░ ░░
    /// ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░
    /// ```
    ///
    /// - Parameters:
    ///   - columns: Number of columns
    ///   - rows: Number of rows
    public func printGrid(columns: Int = 8, rows: Int = 8) {
        let grid = (1...columns).map { y in
            (1...rows).map { x in
                let bb = boundingBox()
                if center.x == x && center.y == y {
                    switch clusterSide {
                    case .bottom:
                        return "╲╱"
                    case .top:
                        return "╱╲"
                    }
                    
                } else if bb.minX == x && bb.minY == y {
                    return "┏ "
                } else if bb.maxX == x && bb.minY == y {
                    return " ┓"
                } else if bb.maxX == x && bb.maxY == y {
                    return " ┛"
                } else if bb.minX == x && bb.maxY == y {
                    return "┗ "
                } else if pixels.contains(where: { $0.x == x && $0.y == y }) {
                    return "▓▓"
                }
                
                
                return "░░"
                
            }.joined(separator: " ")
        }
        
        print(self)
        print(grid.joined(separator: "\n"))
        print()
    }
}

extension Cluster: CustomStringConvertible {
    public var description: String {
        "\(clusterSide.rawValue.capitalized) Cluser at \(center) size \(size)"
    }
}

public extension Array where Element: Cluster {
    func contains(_ element: Pixel) -> Bool {
        self.first(where: { $0.contains(element)} ) != nil
    }
    
    func largest() -> Cluster? {
        self.sorted { $0.size > $1.size }
            .first
    }
    
    func largest(minSize: Int) -> Cluster? {
        self.filter { $0.size >= minSize }
            .sorted { $0.size > $1.size }
            .first
    }

}
