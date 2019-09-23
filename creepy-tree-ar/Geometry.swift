//
//  Geometry.swift
//  Tree4Me
//
//  Created by Lachlan Hurst on 22/08/2015.
//  Copyright (c) 2019 Lachlan Hurst. All rights reserved.
//
import Foundation
import SceneKit

struct ivec3 {
    var x:Int
    var y:Int
    var z:Int
}

class MeshFacet {
    var pt1:simd_float3
    var pt2:simd_float3
    var pt3:simd_float3
    
    init (point1:simd_float3 , point2:simd_float3 , point3:simd_float3 ) {
        pt1 = point1
        pt2 = point2
        pt3 = point3
    }
    
    func normal() -> simd_float3 {
        return MeshFacet.calcNormal(pt1, pt2, pt3)
    }
    
    class func calcNormal(_ pt1:simd_float3 , _ pt2:simd_float3 , _ pt3:simd_float3 ) -> simd_float3  {
        let v12 = pt2 - pt1
        let v13 = pt3 - pt1
        var norm = simd_cross(v12,v13)
        norm = simd_normalize(norm)

        return norm
    }
}
