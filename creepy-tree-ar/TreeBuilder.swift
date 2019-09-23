//
//  TreeBuilder.swift
//  creepy-tree-ar
//
//  Created by Lachlan Hurst on 23/9/19.
//  Copyright © 2019 Lachlan Hurst. All rights reserved.
//

import SceneKit

class TreeBuilder {
    
    var treeProperties:ProcTree.Properties
    var treeNode:SCNNode?

    init() {
        treeProperties = ProcTree.Properties()
    }
    
    init(properties:ProcTree.Properties) {
        treeProperties = properties
    }

    func buildTreeGeometry() -> SCNGeometry {
        let tree = buildTree()
        let geometry = buildGeometry(tree: tree)
        
        geometry.firstMaterial?.diffuse.contents = UIColor.brown
        geometry.firstMaterial?.ambient.contents = UIColor.white
        //geometry.firstMaterial?.lightingModel = SCNMaterial.LightingModel.lambert

        return geometry
    }
    
    func updateRandomSeed() {
        let newSeed = arc4random_uniform(1000)
        self.treeProperties.mSeed = Int(newSeed)
    }
    
    
    private func buildTwigGeometry(tree:ProcTree.Tree) -> SCNGeometry {
        return buildGeometryForFaces(faces: tree.mTwigFace, verts: tree.mTwigVert)
    }
    
    private func buildGeometry(tree:ProcTree.Tree) -> SCNGeometry {
        return buildGeometryForFaces(faces: tree.mFace, verts: tree.mVert)
    }
    
    private func buildGeometryForFaces(faces:[ivec3], verts:[simd_float3]) -> SCNGeometry {
        let ap1 = simd_make_float3(0,0,0)
        let ap2 = simd_make_float3(1,0,0)
        let ap3 = simd_make_float3(0,1,0)
        
        let norm = MeshFacet.calcNormal(ap1, ap2, ap3)
        print(norm)
        
        var pointsList = [simd_float3](repeating: simd_make_float3(0), count: faces.count*3)
        var normalsList = [simd_float3](repeating: simd_make_float3(0), count: faces.count*3)
        var indexList = [CInt](repeating: 0, count: faces.count*3)
        
        var index:Int = 0
        for face in faces {
            let fv1 = verts[face.x]
            let fv2 = verts[face.y]
            let fv3 = verts[face.z]
            
            //let facet = MeshFacet(point1: fv1, point2: fv2, point3: fv3)
            //let normal:SCNVector3 = facet.normal()
            let normal = MeshFacet.calcNormal(fv1, fv2, fv3)
            indexList[index] = CInt(index)
            pointsList[index] = fv1
            normalsList[index] = normal
            index+=1
            indexList[index] = CInt(index)
            pointsList[index] = fv2
            normalsList[index] = normal
            index+=1
            indexList[index] = CInt(index)
            pointsList[index] = fv3
            normalsList[index] = normal
            index+=1
        }
        
        let vertexData = Data(bytes: pointsList, count: pointsList.count * MemoryLayout<simd_float3>.size)
        let vertexSourceNew = SCNGeometrySource(
            data: vertexData,
            semantic: SCNGeometrySource.Semantic.vertex,
            vectorCount: pointsList.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<simd_float3>.size)
        
        let normalData = Data(bytes: normalsList, count: normalsList.count * MemoryLayout<simd_float3>.size)
        let normalSource = SCNGeometrySource(
            data: normalData,
            semantic: SCNGeometrySource.Semantic.normal,
            vectorCount: normalsList.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<simd_float3>.size)
        
        let indexData  = Data(bytes: indexList, count: MemoryLayout<CInt>.size * indexList.count)
        let indexElement = SCNGeometryElement(
            data: indexData,
            primitiveType: SCNGeometryPrimitiveType.triangles,
            primitiveCount: indexList.count/3,
            bytesPerIndex: MemoryLayout<CInt>.size
        )
        
        let geo = SCNGeometry(sources: [vertexSourceNew,normalSource], elements: [indexElement])
        return geo
    }
    
    
    func buildTree() -> ProcTree.Tree {
        let tree = ProcTree.Tree()
        tree.mProperties = treeProperties
        tree.generate()
        
        return tree
    }
    

}
