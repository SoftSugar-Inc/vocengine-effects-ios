//
//  SenseMeEffectsNormalShader.metal
//  SenseMeEffects-Metal
//
//  Created by 马浩萌 on 2023/9/5.
//

#include <metal_stdlib>
using namespace metal;


// Include header shared between this Metal shader code and C code executing Metal API commands.
#include "SenseMeEffectsShaderTypes.h"

// Vertex shader outputs and fragment shader inputs
struct RasterizerData
{
    // The [[position]] attribute of this member indicates that this value
    // is the clip space position of the vertex when this structure is
    // returned from the vertex function.
    float4 position [[position]]; // position 关键字
    
    // Since this member does not have a special attribute, the rasterizer
    // interpolates its value with the values of the other triangle vertices
    // and then passes the interpolated value to the fragment shader for each
    // fragment in the triangle.
    float4 color;
    
    float pointsize [[point_size]]; // point_size 关键字
    
    float2 textureCoordinate;
};

vertex RasterizerData vertexShader(uint vertexID [[vertex_id]], constant SenseMeVertex *vertices [[buffer(SenseMeVertexInputIndexVertices)]], constant vector_uint2 *viewportSizePointer [[buffer(SenseMeVertexInputIndexViewportSize)]])
{
    RasterizerData out;
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);

    // Index into the array of positions to get the current vertex.
    // The positions are specified in pixel dimensions (i.e. a value of 100
    // is 100 pixels from the origin).
    float2 pixelSpacePosition = vertices[vertexID].position.xy;
    
    // Get the viewport size and cast to float.
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    

    // To convert from positions in pixel space to positions in clip-space,
    //  divide the pixel coordinates by half the size of the viewport.
    out.position.xy = pixelSpacePosition / (viewportSize / 2.0);
    out.position.z = vertices[vertexID].position.z;

    // Pass the input color directly to the rasterizer.
    out.color = vertices[vertexID].color;
    out.textureCoordinate = vertices[vertexID].textureCoordinate;
    out.pointsize = 10.0;
    
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    // Return the interpolated color.
//    return in.color;
    return { 0.0, 1.0, 0.0, 1.0 };
}

fragment float4 samplingShader(RasterizerData in [[stage_in]], texture2d<half> colorTexture [[texture(SenseMeTextureInputIndexBaseColor)]])
{
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);

    // return the color of the texture
    return float4(colorSample);
}

kernel void yuvToRGBATexture(texture2d<float, access::read> yTexture [[texture(0)]],
                             texture2d<float, access::read> uvTexture [[texture(1)]],
                             texture2d<float, access::write> rgbaTexture [[texture(2)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= rgbaTexture.get_width() || gid.y >= rgbaTexture.get_height()) return;

    // 获取Y、UV的像素值
    float y = yTexture.read(gid).r;
    float2 uv = uvTexture.read(gid / 2).rg - float2(0.5, 0.5);  // UV数据的分辨率是Y的一半

    // YUV到RGB转换
    float3 rgb;
    rgb.r = y + 1.402 * uv.y;
    rgb.g = y - 0.344 * uv.x - 0.714 * uv.y;
    rgb.b = y + 1.772 * uv.x;

    // 写入RGBA纹理
    rgbaTexture.write(float4(rgb, 1.0), gid);
}
