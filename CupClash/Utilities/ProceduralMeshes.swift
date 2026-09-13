import RealityKit
import simd

enum ProceduralMeshes {
    static func cylinder(height: Float, radius: Float, segments: Int = 16) -> MeshResource {
        frustum(bottomRadius: radius, topRadius: radius, height: height, segments: segments)
            ?? MeshResource.generateBox(width: radius * 2, height: height, depth: radius * 2)
    }

    static func frustum(bottomRadius: Float, topRadius: Float, height: Float, segments: Int = 16) -> MeshResource? {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        let half = height / 2

        for i in 0...segments {
            let theta = Float(i) / Float(segments) * (.pi * 2)
            let cosine = cos(theta)
            let sine = sin(theta)
            positions.append(SIMD3(cosine * bottomRadius, -half, sine * bottomRadius))
            positions.append(SIMD3(cosine * topRadius, half, sine * topRadius))
            let radial = simd_normalize(SIMD3(cosine, 0, sine))
            let rise = bottomRadius - topRadius
            let slant = simd_normalize(SIMD3(radial.x * height, rise, radial.z * height))
            normals.append(slant)
            normals.append(slant)
        }

        for i in 0..<segments {
            let a = UInt32(i * 2)
            let b = a + 1
            let c = a + 2
            let d = a + 3
            indices.append(contentsOf: [a, c, b, b, c, d])
        }

        var descriptor = MeshDescriptor(name: "procFrustum")
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.primitives = .triangles(indices)
        return try? MeshResource.generate(from: [descriptor])
    }
}
