
precision mediump float;

varying mediump vec2 coordinate;
uniform sampler2D videoframe;

void main()
{
    vec4 color = texture2D(videoframe, coordinate);
    gl_FragColor.bgra = vec4(color.b, color.g, color.r, color.a);
    
//    vec4 tc = texture2D(videoframe, coordinate);
//    float color = tc.r * 0.3 + tc.g * 0.59 + tc.b * 0.11;
//    gl_FragColor = vec4(color, color, color, 1.0);
}
