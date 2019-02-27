attribute vec4 position;
attribute mediump vec4 textureCoordinate;
varying mediump vec2 texCoords;

void main(void)
{
    gl_Position = position;
    texCoords = textureCoordinate.xy;
}

