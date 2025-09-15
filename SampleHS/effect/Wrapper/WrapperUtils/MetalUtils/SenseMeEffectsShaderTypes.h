//
//  SenseMeEffectsShaderTypes.h
//  SenseMeEffects-Metal
//
//  Created by 马浩萌 on 2023/9/5.
//

#ifndef SenseMeEffectsShaderTypes_h
#define SenseMeEffectsShaderTypes_h

#include <simd/simd.h>

typedef enum SenseMeVertexInputChannel {
    SenseMeVertexInputIndexVertices     = 0,
    SenseMeVertexInputIndexViewportSize = 1,
} SenseMeVertexInputChannel;

typedef enum SenseMeTextureInputChannel {
    SenseMeTextureInputIndexBaseColor = 0,
} SenseMeTextureInputChannel;

typedef struct {
    vector_float3 position;
    vector_float4 color;
    vector_float2 textureCoordinate;
} SenseMeVertex;

typedef enum STVertexInputIndex {
    STVertexInputIndexVertices     = 0,
    STVertexInputIndexViewportSize = 1,
} STVertexInputIndex;


typedef struct st_pointf_tf {
    float x;    ///< 点的水平方向坐标,为浮点数
    float y;    ///< 点的竖直方向坐标,为浮点数
} st_pointf_tf;

#endif /* SenseMeEffectsShaderTypes_h */
