/*
proctree.js Copyright (c) 2012, Paul Brunt
c++ port Copyright (c) 2015, Jari Komppa
Swift port Copyright (c) 2015, Lachlan Hurst
 
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
* Neither the name of proctree.js nor the
names of its contributors may be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL PAUL BRUNT BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation
import UIKit
import SceneKit

class ProcTree {
    
    struct fvec2 {
        var u:Float
        var v:Float
    }
    
    static func length(_ a:simd_float3) -> Float
    {
        return sqrtf(a.x * a.x + a.y * a.y + a.z * a.z);
    }
    
    static func normalize(_ a:simd_float3) -> simd_float3
    {
        var l = length(a)
        if (l != 0)
        {
            l = 1.0 / l
            return simd_make_float3(a.x * l, a.y * l, a.z * l)
        }
        return a;
    }
    
    static func cross(a:simd_float3, b:simd_float3) -> simd_float3
    {
        let c = simd_make_float3(a.y * b.z - a.z * b.y,
                      a.z * b.x - a.x * b.z,
                      a.x * b.y - a.y * b.x)
        return c;
    }
    
    static func dot(a:simd_float3, b:simd_float3) -> Float
    {
        return a.x * b.x + a.y * b.y + a.z * b.z
    }
    
    static func sub(a:simd_float3, b:simd_float3) -> simd_float3
    {
        return simd_make_float3(a.x - b.x, a.y - b.y, a.z - b.z)
    }
    
    static func add(a:simd_float3, b:simd_float3) -> simd_float3
    {
        return simd_make_float3(a.x + b.x, a.y + b.y, a.z + b.z)
    }
    
    static func scaleVec(a:simd_float3, b:Float) -> simd_float3
    {
        return simd_make_float3(a.x * b, a.y * b, a.z * b)
    }
    
    static func scaleInDirection(aVector:simd_float3, aDirection:simd_float3, aScale:Float) -> simd_float3
    {
        let currentMag = dot(a:aVector, b:aDirection)
        let change = scaleVec(a:aDirection, b:currentMag * aScale - currentMag);
        return add(a:aVector, b:change);
    }
    
    static func vecAxisAngle(aVec:simd_float3, aAxis:simd_float3, aAngle:Float) -> simd_float3
    {
        //v cos(T) + (axis x v) * sin(T) + axis*(axis . v)(1-cos(T)
        let cosr = cos(aAngle)
        let sinr = sin(aAngle);
        return add(
            a:add(
                a:scaleVec(a:aVec, b:cosr),
                b: scaleVec(a:cross(a:aAxis, b:aVec), b: sinr)
            ),
            b: scaleVec(a:aAxis, b: dot(a:aAxis, b:aVec) * (1 - cosr))
        );
    }

    static func mirrorBranch(aVec:simd_float3, aNorm:simd_float3, aProperties:Properties) -> simd_float3
    {
        let v = cross(a:aNorm, b:cross(a:aVec, b:aNorm));
        let s = aProperties.mBranchFactor * dot(a:v, b:aVec);
        let res = simd_make_float3(aVec.x - v.x * s, aVec.y - v.y * s, aVec.z - v.z * s)
        return res;
    }
    
    class Properties {
        var mClumpMax:Float
        var mClumpMin:Float
        var mLengthFalloffFactor:Float
        var mLengthFalloffPower:Float
        var mBranchFactor:Float
        var mRadiusFalloffRate:Float
        var mClimbRate:Float
        var mTrunkKink:Float
        var mMaxRadius:Float
        var mTreeSteps:Int
        var mTaperRate:Float
        var mTwistRate:Float
        var mSegments:Int
        var mLevels:Int
        var mSweepAmount:Float
        var mInitialBranchLength:Float
        var mTrunkLength:Float
        var mDropAmount:Float
        var mGrowAmount:Float
        var mVMultiplier:Float
        var mTwigScale:Float
        var mSeed:Int
        var mRseed:Int?
        
        init() {
            mSeed = 262
            mSegments = 6
            mLevels = 5
            mVMultiplier = 0.36
            mTwigScale = 0.39
            mInitialBranchLength = 0.49
            mLengthFalloffFactor = 0.85
            mLengthFalloffPower = 0.99
            mClumpMax = 0.454
            mClumpMin = 0.404
            mBranchFactor = 2.45
            mDropAmount = -0.1
            mGrowAmount = 0.235
            mSweepAmount = 0.01
            mMaxRadius = 0.139
            mClimbRate = 0.371
            mTrunkKink = 0.093
            mTreeSteps = 5
            mTaperRate = 0.947
            mRadiusFalloffRate = 0.73
            mTwistRate = 3.02
            mTrunkLength = 2.4
        }
        
        init(
            aClumpMax:Float,
            aClumpMin:Float,
            aLengthFalloffFactor:Float,
            aLengthFalloffPower:Float,
            aBranchFactor:Float,
            aRadiusFalloffRate:Float,
            aClimbRate:Float,
            aTrunkKink:Float,
            aMaxRadius:Float,
            aTreeSteps:Int,
            aTaperRate:Float,
            aTwistRate:Float,
            aSegments:Int,
            aLevels:Int,
            aSweepAmount:Float,
            aInitialBranchLength:Float,
            aTrunkLength:Float,
            aDropAmount:Float,
            aGrowAmount:Float,
            aVMultiplier:Float,
            aTwigScale:Float,
            aSeed:Int
            )
        {
            mSeed = aSeed
            mSegments = aSegments
            mLevels = aLevels
            mVMultiplier = aVMultiplier
            mTwigScale = aTwigScale
            mInitialBranchLength = aInitialBranchLength
            mLengthFalloffFactor = aLengthFalloffFactor
            mLengthFalloffPower = aLengthFalloffPower
            mClumpMax = aClumpMax
            mClumpMin = aClumpMin
            mBranchFactor = aBranchFactor
            mDropAmount = aDropAmount
            mGrowAmount = aGrowAmount
            mSweepAmount = aSweepAmount
            mMaxRadius = aMaxRadius
            mClimbRate = aClimbRate
            mTrunkKink = aTrunkKink
            mTreeSteps = aTreeSteps
            mTaperRate = aTaperRate
            mRadiusFalloffRate = aRadiusFalloffRate
            mTwistRate = aTwistRate
            mTrunkLength = aTrunkLength
        }
        
        func setDropAmount(value:Float) {
            mDropAmount = value
        }
        
        func setClimbRate(value:Float) {
            mClimbRate = value
        }
        
        func setMaxRadius(value:Float) {
            mMaxRadius = value
        }
        
        func setInitialBranchLength(value:Float) {
            mInitialBranchLength = value
        }
        
        func setBranchFactor(value:Float) {
            mBranchFactor = value
        }
        
        func setTrunkLength(value:Float) {
            mTrunkLength = value
        }
        
        func setTrunkKink(value:Float) {
            mTrunkKink = value
        }
        
        func setSweepAmount(value:Float) {
            mSweepAmount = value
        }
        
        func setLevels(value:Float) {
            mLevels = Int(floor(value))
        }
        
        func setLengthFalloffPower(value:Float) {
            mLengthFalloffPower = value
        }
        
        func setLengthFalloffFactor(value:Float) {
            mLengthFalloffFactor = value
        }
        
        func setTwistRate(value:Float) {
            mTwistRate = value
        }
        
        func setClumpMax(value:Float) {
            mClumpMax = value
        }
        
        func setClumpMin(value:Float) {
            mClumpMin = value
        }
        
        func random(_ aFixed:Float?) -> Float {
            var fix:Float
            
            if let aFixed = aFixed {
                fix = aFixed
            } else {
                fix = Float(mRseed!)
                mRseed!+=1
            }
            return abs(cos(fix + fix * fix))
        }
    }
    
    class Branch {
        var mChild0:Branch?
        var mChild1:Branch?
        weak var mParent:Branch?
        var mHead:simd_float3
        var mTangent:simd_float3
        var mLength:Float
        var mTrunktype:Int
        var mRing0:[Int]?
        var mRing1:[Int]?
        var mRing2:[Int]?
        var mRootRing:[Int]
        var mRadius:Float
        var mEnd:Int

        init() {
            mRootRing = []
            mRing0 = nil
            mRing1 = nil
            mRing2 = nil
            mChild0 = nil
            mChild1 = nil
            mParent = nil
            mLength = 1
            mTrunktype = 0
            mRadius = 0
            mHead = simd_make_float3(0)
            mTangent = simd_make_float3(0)
            mEnd = 0
        }
        
        init (aHead:simd_float3, aParent:Branch?) {
            mRootRing = []
            mRing0 = nil
            mRing1 = nil
            mRing2 = nil
            mChild0 = nil
            mChild1 = nil
            mLength = 1;
            mTrunktype = 0;
            mRadius = 0;
            mHead = aHead;
            mTangent = simd_make_float3(0)
            mParent = aParent;
            mEnd = 0;
        }

        func split(aLevel:Int, aSteps:Int, aProperties:inout Properties, aL1:Int = 1, aL2:Int = 1) {
            let rLevel = aProperties.mLevels - aLevel
            var po:simd_float3
            
            if let parent = mParent {
                po = parent.mHead
            } else {
                po = simd_make_float3(0)
                mTrunktype = 1
            }
            
            let so = mHead
            let subres = ProcTree.sub(a:so, b: po)
            let dir = ProcTree.normalize(subres)
            
            var a = simd_make_float3(dir.z, dir.x, dir.y)
            let normal = ProcTree.cross(a:dir, b: a)
            let tangent = ProcTree.cross(a:dir, b: normal)
            let val1 = Float(rLevel) * 10.0 + Float(aL1) * 5.0
            let val2 = Float(aL2) + Float(aProperties.mSeed)
            let r = aProperties.random(val1 + val2)
            //float r2 = aProperties.random(rLevel * 10 + aL1 * 5.0f + aL2 + 1 + aProperties.seed); // never used
            
            
            var adj = ProcTree.add(a: ProcTree.scaleVec(a: normal, b: r), b: ProcTree.scaleVec(a: tangent, b: 1 - r));
            if (r > 0.5) {
                adj = ProcTree.scaleVec(a: adj, b: -1);
            }
            
            let clump = (aProperties.mClumpMax - aProperties.mClumpMin) * r + aProperties.mClumpMin
            var newdir = ProcTree.normalize(ProcTree.add(a: ProcTree.scaleVec(a: adj, b: 1 - clump), b: ProcTree.scaleVec(a: dir, b: clump)))
            
            
            var newdir2 = ProcTree.mirrorBranch(aVec: newdir, aNorm: dir, aProperties: aProperties)
            if (r > 0.5)
            {
                let tmp = newdir
                newdir = newdir2
                newdir2 = tmp
            }
            
            if (aSteps > 0)
            {
                let angle = Float(aSteps) / Float(aProperties.mTreeSteps) * 2 * .pi * Float(aProperties.mTwistRate)
                a = simd_make_float3(sin(angle), r, cos(angle))
                newdir2 = ProcTree.normalize(a)
            }
            
            let growAmount = Float(aLevel * aLevel) / Float(aProperties.mLevels * aProperties.mLevels) * Float(aProperties.mGrowAmount)
            let dropAmount = Float(rLevel) * Float(aProperties.mDropAmount)
            let sweepAmount = Float(rLevel) * Float(aProperties.mSweepAmount)
            a = simd_make_float3(sweepAmount, dropAmount + growAmount, 0)
            newdir = ProcTree.normalize(ProcTree.add(a: newdir, b: a));
            newdir2 = ProcTree.normalize(ProcTree.add(a: newdir2, b: a));
            
            let head0 = ProcTree.add(a: so, b: ProcTree.scaleVec(a: newdir, b: mLength));
            let head1 = ProcTree.add(a: so, b: ProcTree.scaleVec(a: newdir2, b: mLength));
            mChild0 = Branch(aHead: head0, aParent: self);
            mChild1 = Branch(aHead: head1, aParent: self);
            mChild0!.mLength = pow(mLength, aProperties.mLengthFalloffPower) * aProperties.mLengthFalloffFactor;
            mChild1!.mLength = pow(mLength, aProperties.mLengthFalloffPower) * aProperties.mLengthFalloffFactor;
            
            if (aLevel > 0)
            {
                if (aSteps > 0)
                {
                    a = simd_make_float3((r - 0.5) * 2 * aProperties.mTrunkKink,
                              aProperties.mClimbRate,
                              (r - 0.5) * 2 * aProperties.mTrunkKink)

                    mChild0!.mHead = ProcTree.add(a:mHead, b: a);
                    mChild0!.mTrunktype = 1;
                    mChild0!.mLength = mLength * aProperties.mTaperRate;
                    mChild0!.split(aLevel: aLevel, aSteps: aSteps - 1, aProperties: &aProperties, aL1: aL1 + 1, aL2: aL2);
                }
                else
                {
                    mChild0!.split(aLevel: aLevel - 1, aSteps: 0, aProperties: &aProperties, aL1: aL1 + 1, aL2: aL2);
                }
                mChild1!.split(aLevel: aLevel - 1, aSteps: 0, aProperties: &aProperties, aL1: aL1, aL2: aL2 + 1);
            }
        }
    }
    
    class Tree {
        var mRoot:Branch?
        
        var mProperties:Properties?
        
        var mVert:[simd_float3]
        var mNormal:[simd_float3]
        var mUV:[fvec2]
        var mTwigVert:[simd_float3]
        var mTwigNormal:[simd_float3]
        var mTwigUV:[fvec2]
        var mFace:[ivec3]
        var mTwigFace:[ivec3]
        
        init() {
            mRoot = nil
            mVert = []
            mNormal = []
            mUV = []
            mTwigVert = []
            mTwigFace = []
            mTwigNormal = []
            mTwigUV = []
            mFace = []
        }
        
        func generate() {
            mProperties!.mRseed = mProperties!.mSeed;
            let starthead = simd_make_float3(0, mProperties!.mTrunkLength, 0)
            mRoot = Branch(aHead: starthead, aParent: nil)
            mRoot!.mLength = mProperties!.mInitialBranchLength
            mRoot!.split(aLevel: mProperties!.mLevels, aSteps: mProperties!.mTreeSteps, aProperties: &mProperties!)
            
            createForks(branch: nil, radius: nil)
            doFaces(branch: nil)
            //createTwigs(nil)
            
            /*calcVertSizes(0);
            allocVertBuffers();
            ;
            ;
            calcFaceSizes(0);
            allocFaceBuffers();
            ;
            calcNormals();
            fixUVs();*/

            mRoot = nil
        }
        
        func doFaces(branch:Branch?) {
            var aBranch:Branch
            if let branch = branch {
                aBranch = branch
            } else {
                aBranch = mRoot!
            }
            
            let segments = mProperties!.mSegments
            
            if (aBranch.mParent == nil)
            {
                let tangent = ProcTree.normalize(ProcTree.cross(a: ProcTree.sub(a: aBranch.mChild0!.mHead, b: aBranch.mHead), b: ProcTree.sub(a: aBranch.mChild1!.mHead, b: aBranch.mHead)))
                let normal = ProcTree.normalize(aBranch.mHead)
                let left = simd_make_float3(-1, 0, 0)
                let dotProd = ProcTree.dot(a: tangent, b: left)
                var angle = acos(dotProd)
                if (ProcTree.dot(a: ProcTree.cross(a: left, b: tangent), b: normal) > 0)
                {
                    angle = 2 * .pi - angle
                }
                let segOffset = Int(floor(0.5 + (angle / .pi / 2 * Float(segments))))
                for i in 0..<segments {
                    let v1 = aBranch.mRing0![i]
                    let v2 = aBranch.mRootRing[(i + segOffset + 1) % segments]
                    let v3 = aBranch.mRootRing[(i + segOffset) % segments]
                    let v4 = aBranch.mRing0![(i + 1) % segments]
                    
                    var a:ivec3
                    a = ivec3(x: v1, y: v4, z: v3)
                    mFace.append(a)
                    a = ivec3(x: v4, y: v2, z: v3)
                    mFace.append(a)
                    
                    /*mUV[(i + segOffset) % segments] = fvec2(u: Float(i) / Float(segments), v: 0)
                    
                    var len = ProcTree.length(ProcTree.sub(mVert[aBranch.mRing0![i]], b:mVert[aBranch.mRootRing[(i + segOffset) % segments]])) * mProperties!.mVMultiplier;
                    mUV[aBranch.mRing0![i]] = fvec2(u: Float(i) / Float(segments), v: len)
                    mUV[aBranch.mRing2![i]] = fvec2(u: Float(i) / Float(segments), v: len)*/
                }
            }
            
            if let _ = aBranch.mChild0!.mRing0 //(aBranch.mChild0.mRing0 != 0)
            {
                var segOffset0 = -1
                var segOffset1 = -1
                var match0:Float = 0
                var match1:Float = 0
                
                var v1 = ProcTree.normalize(ProcTree.sub(a: mVert[aBranch.mRing1![0]], b:aBranch.mHead))
                var v2 = ProcTree.normalize(ProcTree.sub(a: mVert[aBranch.mRing2![0]], b:aBranch.mHead))
                
                v1 = ProcTree.scaleInDirection(aVector: v1, aDirection: ProcTree.normalize(ProcTree.sub(a: aBranch.mChild0!.mHead, b: aBranch.mHead)), aScale: 0)
                v2 = ProcTree.scaleInDirection(aVector: v2, aDirection: ProcTree.normalize(ProcTree.sub(a: aBranch.mChild1!.mHead, b: aBranch.mHead)), aScale: 0)
                
                for i in 0..<segments {
                    var d = ProcTree.normalize(ProcTree.sub(a: mVert[aBranch.mChild0!.mRing0![i]], b: aBranch.mChild0!.mHead))
                    var l = ProcTree.dot(a: d, b: v1)
                    if (segOffset0 == -1 || l > match0)
                    {
                        match0 = l
                        segOffset0 = segments - i
                    }
                    d = ProcTree.normalize(ProcTree.sub(a: mVert[aBranch.mChild1!.mRing0![i]], b: aBranch.mChild1!.mHead))
                    l = ProcTree.dot(a: d, b: v2);
                    if (segOffset1 == -1 || l > match1)
                    {
                        match1 = l
                        segOffset1 = segments - i
                    }
                }
                
                //let UVScale = mProperties!.mMaxRadius / aBranch.mRadius
                
                for i in 0..<segments {
                    var v1 = aBranch.mChild0!.mRing0![i]
                    var v2 = aBranch.mRing1![(i + segOffset0 + 1) % segments]
                    var v3 = aBranch.mRing1![(i + segOffset0) % segments]
                    var v4 = aBranch.mChild0!.mRing0![(i + 1) % segments]
                    var a:ivec3
                    a = ivec3(x: v1, y: v4, z: v3)
                    mFace.append(a)
                    a = ivec3(x: v4, y: v2, z: v3)
                    mFace.append(a)
                    
                    v1 = aBranch.mChild1!.mRing0![i];
                    v2 = aBranch.mRing2![(i + segOffset1 + 1) % segments];
                    v3 = aBranch.mRing2![(i + segOffset1) % segments];
                    v4 = aBranch.mChild1!.mRing0![(i + 1) % segments];
                    
                    a = ivec3(x: v1, y: v2, z: v3)
                    mFace.append(a);
                    a = ivec3(x: v1, y: v4, z: v2)
                    mFace.append(a);
                    
                    /*var len1 = ProcTree.length(ProcTree.sub(mVert[aBranch.mChild0!.mRing0![i]], b:mVert[aBranch.mRing1![(i + segOffset0) % segments]])) * UVScale
                    var uv1 = mUV[aBranch.mRing1![(i + segOffset0 - 1) % segments]]
                    
                    mUV[aBranch.mChild0!.mRing0![i]] = fvec2(u: uv1.u, v: uv1.v + len1 * mProperties!.mVMultiplier)
                    mUV[aBranch.mChild0!.mRing2![i]] = fvec2(u: uv1.u, v: uv1.v + len1 * mProperties!.mVMultiplier)
                    
                    var len2 = ProcTree.length(ProcTree.sub(mVert[aBranch.mChild1!.mRing0![i]], b:mVert[aBranch.mRing2![(i + segOffset1) % segments]])) * UVScale
                    var uv2 = mUV[aBranch.mRing2![(i + segOffset1 - 1) % segments]]
                    
                    mUV[aBranch.mChild1!.mRing0![i]] = fvec2(u: uv2.u, v: uv2.v + len2 * mProperties!.mVMultiplier)
                    mUV[aBranch.mChild1!.mRing2![i]] = fvec2(u: uv2.u, v: uv2.v + len2 * mProperties!.mVMultiplier)*/
                }
                
                doFaces(branch: aBranch.mChild0);
                doFaces(branch: aBranch.mChild1);
            }
            else
            {
                for i in 0..<segments {
                    var a:ivec3
                    a = ivec3(x: aBranch.mChild0!.mEnd, y: aBranch.mRing1![(i + 1) % segments], z: aBranch.mRing1![i])
                    mFace.append(a)
                    a = ivec3(x: aBranch.mChild1!.mEnd, y: aBranch.mRing2![(i + 1) % segments], z: aBranch.mRing2![i])
                    mFace.append(a)
                    
                    /*var len = ProcTree.length(ProcTree.sub(mVert[aBranch.mChild0!.mEnd], b:mVert[aBranch.mRing1![i]]))
                    mUV[aBranch.mChild0!.mEnd] = fvec2(u: Float(i) / Float(segments) - 1, v: len * mProperties!.mVMultiplier)
                    len = ProcTree.length(ProcTree.sub(mVert[aBranch.mChild1!.mEnd], b:mVert[aBranch.mRing2![i]]))
                    mUV[aBranch.mChild1!.mEnd] = fvec2(u: Float(i) / Float(segments), v: len * mProperties!.mVMultiplier)*/
                }
            }

            
        }
        
        
        func createForks(branch:Branch?, radius:Float?) {
            
            var aBranch:Branch
            if let branch = branch {
                aBranch = branch
            } else {
                aBranch = mRoot!
            }
            var aRadius:Float
            if let radius = radius {
                aRadius = radius
            } else {
                aRadius = mProperties!.mMaxRadius
            }
            
            aBranch.mRadius = aRadius;
            
            if aRadius > aBranch.mLength {
                aRadius = aBranch.mLength
            }
            
            let segments = mProperties!.mSegments;
            
            let segmentAngle = .pi * 2 / Float(segments)
            
            if (aBranch.mParent == nil)
            {
                aBranch.mRootRing = [Int](repeating:0, count:segments)
                //create the root of the tree
                //branch.root = [];
                let axis = simd_make_float3(0, 1, 0)

                for i in 0..<segments {
                    let left = simd_make_float3(-1, 0, 0)
                    let vec = ProcTree.vecAxisAngle(aVec: left, aAxis: axis, aAngle: -segmentAngle * Float(i))
                    aBranch.mRootRing[i] = mVert.count
                    mVert.append(ProcTree.scaleVec(a: vec, b: aRadius / mProperties!.mRadiusFalloffRate))
                }
            }
            
            //cross the branches to get the left
            //add the branches to get the up
            if let _ = aBranch.mChild0
            {
                var axis:simd_float3
                if let parent = aBranch.mParent {
                    axis = ProcTree.normalize(ProcTree.sub(a: aBranch.mHead, b: parent.mHead))
                }
                else
                {
                    axis = ProcTree.normalize(aBranch.mHead)
                }
                
                let axis1 = ProcTree.normalize(ProcTree.sub(a: aBranch.mHead, b:aBranch.mChild0!.mHead))
                let axis2 = ProcTree.normalize(ProcTree.sub(a: aBranch.mHead, b:aBranch.mChild1!.mHead))
                let tangent = ProcTree.normalize(ProcTree.cross(a: axis1, b: axis2))
                aBranch.mTangent = tangent
                
                let axis3 = ProcTree.normalize(ProcTree.cross(a: tangent, b: ProcTree.normalize(ProcTree.add(a: ProcTree.scaleVec(a: axis1, b: -1), b: ProcTree.scaleVec(a: axis2, b: -1)))))
                let dir = simd_make_float3(axis2.x, 0, axis2.z)
                let centerloc = ProcTree.add(a: aBranch.mHead, b: ProcTree.scaleVec(a: dir, b: -mProperties!.mMaxRadius / 2));
                
                aBranch.mRing0 = [Int](repeating:0, count:segments)
                aBranch.mRing1 = [Int](repeating:0, count:segments)
                aBranch.mRing2 = [Int](repeating:0, count:segments)
                
                var ring0count:Int = 0
                var ring1count:Int = 0
                var ring2count:Int = 0
                
                var scale = mProperties!.mRadiusFalloffRate;
                
                if (aBranch.mChild0!.mTrunktype == 1 || aBranch.mTrunktype == 1)
                {
                    scale = 1.0 / mProperties!.mTaperRate;
                }
                
                //main segment ring
                let linch0 = mVert.count
                aBranch.mRing0![ring0count] = linch0;
                ring0count+=1
                aBranch.mRing2![ring2count] = linch0;
                ring2count+=1
                mVert.append(ProcTree.add(a: centerloc, b: ProcTree.scaleVec(a: tangent, b: aRadius * scale)))
                
                var start = mVert.count - 1
                let d1 = ProcTree.vecAxisAngle(aVec: tangent, aAxis: axis2, aAngle: 1.57)
                let d2 = ProcTree.normalize(ProcTree.cross(a: tangent, b: axis))
                let s = 1 / ProcTree.dot(a: d1, b: d2)

                for i in 1..<(segments/2) {  // for (var i = 1; i < segments / 2; i++) {
                    var vec = ProcTree.vecAxisAngle(aVec: tangent, aAxis: axis2, aAngle: segmentAngle * Float(i))
                    aBranch.mRing0![ring0count] = start + i
                    ring0count+=1
                    aBranch.mRing2![ring2count] = start + i
                    ring2count+=1
                    vec = ProcTree.scaleInDirection(aVector: vec, aDirection: d2, aScale: s)
                    mVert.append(ProcTree.add(a: centerloc, b: ProcTree.scaleVec(a: vec, b: aRadius * scale)))
                }
                
                let linch1 = mVert.count
                aBranch.mRing0![ring0count] = linch1
                ring0count+=1
                aBranch.mRing1![ring1count] = linch1
                ring1count+=1
                mVert.append(ProcTree.add(a: centerloc, b: ProcTree.scaleVec(a: tangent, b: -aRadius * scale)))

                for i in (segments / 2 + 1) ..< segments {
                    let vec = ProcTree.vecAxisAngle(aVec: tangent, aAxis: axis1, aAngle: segmentAngle * Float(i))
                    aBranch.mRing0![ring0count] = mVert.count
                    ring0count+=1
                    aBranch.mRing1![ring1count] = mVert.count
                    ring1count+=1
                    mVert.append(ProcTree.add(a: centerloc, b: ProcTree.scaleVec(a: vec, b: aRadius * scale)))
                }
                
                aBranch.mRing1![ring1count] = linch0
                ring1count+=1
                aBranch.mRing2![ring2count] = linch1
                ring2count+=1
                start = mVert.count - 1;
                for i in 1 ..< (segments / 2) {
                    let vec = ProcTree.vecAxisAngle(aVec: tangent, aAxis: axis3, aAngle: segmentAngle * Float(i))
                    aBranch.mRing1![ring1count] = start + i
                    ring1count+=1
                    aBranch.mRing2![ring2count] = start + (segments / 2 - i)
                    ring2count+=1
                    let v = ProcTree.scaleVec(a: vec, b: aRadius * scale)
                    mVert.append(ProcTree.add(a: centerloc, b: v))
                }
                
                //child radius is related to the brans direction and the length of the branch
                //float length0 = length(sub(aBranch->mHead, aBranch->mChild0->mHead)); // never used
                //float length1 = length(sub(aBranch->mHead, aBranch->mChild1->mHead)); // never used
                
                var radius0 = 1 * aRadius * mProperties!.mRadiusFalloffRate;
                let radius1 = 1 * aRadius * mProperties!.mRadiusFalloffRate;
                if (aBranch.mChild0!.mTrunktype == 1)
                {
                    radius0 = aRadius * mProperties!.mTaperRate;
                }
                createForks(branch: aBranch.mChild0, radius: radius0);
                createForks(branch: aBranch.mChild1, radius: radius1);
            }
            else
            {
                //add points for the ends of braches
                aBranch.mEnd = mVert.count;
                //branch.head=add(branch.head,scaleVec([this.properties.xBias,this.properties.yBias,this.properties.zBias],branch.length*3));
                mVert.append(aBranch.mHead)
            }
            
            
        }
        
        func createTwigs(branch:Branch?) {
            let aBranch:Branch
            if let branch = branch {
                aBranch = branch
            } else {
                aBranch = mRoot!
            }
            
            if aBranch.mChild0 == nil {
                let tangent = ProcTree.normalize(ProcTree.cross(a: ProcTree.sub(a: aBranch.mParent!.mChild0!.mHead, b: aBranch.mParent!.mHead), b: ProcTree.sub(a: aBranch.mParent!.mChild1!.mHead, b: aBranch.mParent!.mHead)));
                let binormal = ProcTree.normalize(ProcTree.sub(a: aBranch.mHead, b: aBranch.mParent!.mHead));
                //fvec3 normal = cross(tangent, binormal); //never used
                
                let vert1 = mTwigVert.count
                mTwigVert.append(ProcTree.add(a: ProcTree.add(a: aBranch.mHead, b: ProcTree.scaleVec(a: tangent, b: mProperties!.mTwigScale)), b: ProcTree.scaleVec(a: binormal, b: mProperties!.mTwigScale * 2 - aBranch.mLength)));
                let vert2 = mTwigVert.count;
                mTwigVert.append(ProcTree.add(a: ProcTree.add(a: aBranch.mHead, b: ProcTree.scaleVec(a: tangent, b: -mProperties!.mTwigScale)), b: ProcTree.scaleVec(a: binormal, b: mProperties!.mTwigScale * 2 - aBranch.mLength)));
                let vert3 = mTwigVert.count;
                mTwigVert.append(ProcTree.add(a: ProcTree.add(a: aBranch.mHead, b: ProcTree.scaleVec(a: tangent, b: -mProperties!.mTwigScale)), b: ProcTree.scaleVec(a: binormal, b: -aBranch.mLength)));
                let vert4 = mTwigVert.count;
                mTwigVert.append(ProcTree.add(a: ProcTree.add(a: aBranch.mHead, b: ProcTree.scaleVec(a: tangent, b: mProperties!.mTwigScale)), b: ProcTree.scaleVec(a: binormal, b: -aBranch.mLength)));
                
                let vert8 = mTwigVert.count;
                mTwigVert.append(ProcTree.add(a: ProcTree.add(a: aBranch.mHead, b: ProcTree.scaleVec(a: tangent, b: mProperties!.mTwigScale)), b: ProcTree.scaleVec(a: binormal, b: mProperties!.mTwigScale * 2 - aBranch.mLength)));
                let vert7 = mTwigVert.count;
                mTwigVert.append(ProcTree.add(a: ProcTree.add(a: aBranch.mHead, b: ProcTree.scaleVec(a: tangent, b: -mProperties!.mTwigScale)), b: ProcTree.scaleVec(a: binormal, b: mProperties!.mTwigScale * 2 - aBranch.mLength)));
                let vert6 = mTwigVert.count;
                mTwigVert.append(ProcTree.add(a: ProcTree.add(a: aBranch.mHead, b: ProcTree.scaleVec(a: tangent, b: -mProperties!.mTwigScale)), b: ProcTree.scaleVec(a: binormal, b: -aBranch.mLength)));
                let vert5 = mTwigVert.count;
                mTwigVert.append(ProcTree.add(a: ProcTree.add(a: aBranch.mHead, b: ProcTree.scaleVec(a: tangent, b: mProperties!.mTwigScale)), b: ProcTree.scaleVec(a: binormal, b: -aBranch.mLength)));
                
                mTwigFace.append(ivec3(x: vert1, y: vert2, z: vert3))
                mTwigFace.append(ivec3(x: vert4, y: vert1, z: vert3))
                mTwigFace.append(ivec3(x: vert6, y: vert7, z: vert8))
                mTwigFace.append(ivec3(x: vert6, y: vert8, z: vert5))
                
                /*
                var normal = normalize(cross(sub(mTwigVert[vert1], mTwigVert[vert3]), sub(mTwigVert[vert2], mTwigVert[vert3])));
                var normal2 = normalize(cross(sub(mTwigVert[vert7], mTwigVert[vert6]), sub(mTwigVert[vert8], mTwigVert[vert6])));
                
                mTwigNormal[vert1] = (normal);
                mTwigNormal[vert2] = (normal);
                mTwigNormal[vert3] = (normal);
                mTwigNormal[vert4] = (normal);
                
                mTwigNormal[vert8] = (normal2);
                mTwigNormal[vert7] = (normal2);
                mTwigNormal[vert6] = (normal2);
                mTwigNormal[vert5] = (normal2);
                
                mTwigUV[vert1] = { 0, 0 };
                mTwigUV[vert2] = { 1, 0 };
                mTwigUV[vert3] = { 1, 1 };
                mTwigUV[vert4] = { 0, 1 };
                
                mTwigUV[vert8] = { 0, 0 };
                mTwigUV[vert7] = { 1, 0 };
                mTwigUV[vert6] = { 1, 1 };
                mTwigUV[vert5] = { 0, 1 };*/
            }
            else
            {
                createTwigs(branch: aBranch.mChild0);
                createTwigs(branch: aBranch.mChild1);
            }
            
        }
        
        
    }
    
    
    
    
}
