precision mediump float;

varying mediump vec2 texCoords;
uniform sampler2D renderedTexture;
varying vec4 fragColor;
const float offset = 1.0 / 300.0;

void main()
{
    //    vec4 color = texture2D(renderedTexture, texCoords);
    //    gl_FragColor.bgra = vec4(color.b, color.g, color.r, color.a);
    //    gl_FragColor.bgra = vec4(color.b, color.g, color.r, color.a);
    //    vec4 color = texture(screenTexture, TexCoords);
    //    vec2 offsets[9] = vec2[](
    //         vec2(-offset, offset),  // top-left
    //         vec2(0.0f,    offset),  // top-center
    //         vec2(offset,  offset),  // top-right
    //         vec2(-offset, 0.0f),    // center-left
    //         vec2(0.0f,    0.0f),    // center-center
    //         vec2(offset,  0.0f),    // center-right
    //         vec2(-offset, -offset), // bottom-left
    //         vec2(0.0f,    -offset), // bottom-center
    //         vec2(offset,  -offset)  // bottom-right
    //     );
    vec2 offsets[9];
    offsets[0] = vec2(-offset, offset);
    offsets[1] = vec2(0.0,    offset);
    offsets[2] = vec2(offset,  offset);
    offsets[3] = vec2(-offset, 0.0);
    offsets[4] = vec2(0.0,    0.0);
    offsets[5] = vec2(offset,  0.0);
    offsets[6] = vec2(-offset, -offset);
    offsets[7] = vec2(0.0,    -offset);
    offsets[8] = vec2(offset,  -offset);
    
    //    float kernel[9] = float[](
    //          1.0 / 16, 2.0 / 16, 1.0 / 16,
    //          2.0 / 16, 4.0 / 16, 2.0 / 16,
    //          1.0 / 16, 2.0 / 16, 1.0 / 16
    //      );
    float kernel[9];
    kernel[0] = 1.0 / 16.0;
    kernel[1] = 2.0 / 16.0;
    kernel[2] = 1.0 / 16.0;
    kernel[3] = 2.0 / 16.0;
    kernel[4] = 4.0 / 16.0;
    kernel[5] = 2.0 / 16.0;
    kernel[6] = 1.0 / 16.0;
    kernel[7] = 2.0 / 16.0;
    kernel[8] = 1.0 / 16.0;
    
    vec3 sampleTex[9];
    for(int i = 0; i < 9; i++)
    {
        sampleTex[i] = vec3(texture2D(renderedTexture, texCoords.st + offsets[i]));
    }
    vec3 col;
    for(int i = 0; i < 9; i++)
    {
        col += sampleTex[i] * kernel[i];
    }
    vec4 color = vec4(col, 1.0);
    gl_FragColor.bgra = vec4(color.b, color.g, color.r, color.a);
}
