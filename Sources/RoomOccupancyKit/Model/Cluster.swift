//
//  Cluster.swift
//  ThermalViewer
//
//  Created by Emory Dunn on 5/20/21.
//


import Foundation

public class Cluster {
    
    /// The side of the frame the Cluster is on.
    public enum ClusterSide: String, Equatable {
        case top, bottom
    }
    
    public struct Rect {
        let minX: Int
        let minY: Int
        
        let maxX: Int
        let maxY: Int
        
        let width: Int
        let height: Int
        
        init(minX: Int, minY: Int, maxX: Int, maxY: Int) {
            self.minX = minX
            self.minY = minY
            
            self.maxX = maxX
            self.maxY = maxY
            
            self.width = maxX - minX + 1
            self.height = maxY - minY + 1
        }
    }
    
    /// The Pixels that make up this cluster
    public let pixels: [Pixel]
    
    /// The size of the Cluster
    public var size: Int { pixels.count }
    
    /// Which side of the dividing line the Cluster is on
    public lazy var clusterSide: ClusterSide = {
        if center.y > 4 {
            return .bottom
        } else {
            return .top
        }
    }()
    
    /// Create a new Cluster
    /// - Parameter pixels: Pixels in the Cluster
    public init(_ pixels: Pixel...) {
        self.pixels = pixels
    }
    
    /// Create a new Cluster
    /// - Parameter pixels: Pixels in the Cluster
    public init(from pixels: [Pixel]) {
        
        // Determine which pixel to use as the center of the cluster
        let hottestPixel = pixels.reduce(into: Pixel(x: 0, y: 0, temp: 0)) { currentHottest, pixel in
            currentHottest = pixel.temp > currentHottest.temp ? pixel : currentHottest
        }
        
        // Create a set for the pixels
        var newPixels: Set<Pixel> = [hottestPixel]

        var keepSearching: Bool = true
        while keepSearching {
            
            let oldCount = newPixels.count

            newPixels.forEach { pixel in
                // Locate the neighbor pixels
                let newNeighbors = pixels.filter {

                    ($0.x == pixel.x - 1 && $0.y == pixel.y) || // Left
                        ($0.x == pixel.x + 1 && $0.y == pixel.y) || // Right
                        ($0.x == pixel.x && $0.y - 1 == pixel.y) || // Bottom
                        ($0.x == pixel.x && $0.y + 1 == pixel.y) // Top
                        
                }
                
                newPixels.formUnion(newNeighbors)
            }

            keepSearching = newPixels.count != oldCount
        }
        
        self.pixels = newPixels.sorted()

    }
    
    public convenience init(from payload: SensorPayload, deltaThreshold: Float) {
        // Determine the threshold for filtering the data
        let threshold = payload.mean + deltaThreshold
        
        // Filter out pixels below the threshold
        let pixels = payload.pixels.filter { $0.temp >= threshold }
        
        // Create the cluster
        self.init(from: pixels)
    }
    
    /// Determine whether a Pixel neighbors the Cluster.
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
    /// with the highest temperature is used.
    ///
    /// - Returns: The Pixel in the center
    public lazy var center: Pixel = {
        guard size > 0 else {
            return temperatureCenter
        }
        
        let box = boundingBox
        
        let width = Double(box.maxX - box.minX)
        let tempX = Double(box.minX) + width / 2
        
        let height = Double(box.maxY - box.minY)
        let tempY = Double(box.minY) + height / 2
        
        let centerX = Int(tempX.rounded())
        let centerY = Int(tempY.rounded())
        
        // Return the geometric center
        // If the geometric center can't be found, most likely due to
        // an irregular cluster, fallback to the temp center
        guard let center = pixels.first(where: {
            $0.x == centerX && $0.y == centerY
        }) else {
            return temperatureCenter
        }
        
        return center

    }()
    
    /// The Pixel with the highest temperature, often at the center of the Cluster.
    /// - Returns: The Pixel in the center
    lazy var temperatureCenter: Pixel = {
        return pixels.reduce(pixels[0]) { result, pixel in
            result.temp > pixel.temp ? result : pixel
        }
    }()
    
    /// Calculate the bounding box of the cluster
    /// - Returns: The four points making up the corners.
    public lazy var boundingBox: Rect = {
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
        
        return Rect(minX: minX, minY: minY, maxX: maxX, maxY: maxY)
    }()
    
    
    /// Convenience function to determine whether a Pixel is in the Cluster.
    /// - Parameter pixel: The element to find in the sequence.
    /// - Returns: true if the element was found in the sequence; otherwise, false.
    public func contains(_ pixel: Pixel) -> Bool {
        pixels.contains(pixel)
    }
    
    /// Print a textual representation of a grid of pixels.
    ///
    /// ```
    /// Bottom Cluster at Pixel (4, 5)
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
    public func generateGrid(columns: Int = 8, rows: Int = 8) -> String {
        let grid = (1...columns).map { y in
            (1...rows).map { x in
                let bb = boundingBox
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
        
        return grid.joined(separator: "\n")
    }

    
    /// Print a textual representation of a grid of pixels.
    ///
    /// ```
    /// Bottom Cluster at Pixel (4, 5)
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
        print(self)
        print(generateGrid(columns: columns, rows: rows))
        print()
    }
}

extension Cluster: CustomStringConvertible, Hashable, Equatable, Identifiable {
    
    public var id: Pixel { center }
    
    public var description: String {
        "\(clusterSide.rawValue.capitalized) Cluster at \(center) size \(size)"
    }
    
    public static func == (lhs: Cluster, rhs: Cluster) -> Bool {
        lhs.pixels == rhs.pixels
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(pixels)
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
