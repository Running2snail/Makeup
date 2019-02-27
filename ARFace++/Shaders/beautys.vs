attribute vec4 position;
attribute mediump vec2 texturecoordinate;
varying mediump vec2 coordinate;

varying vec2 blurCoord1s[14];
const highp float mWidth = 720.0;
const highp float mHeight = 1280.0;
uniform float sizeScale;

void main(){
    gl_Position = position;
    gl_PointSize = 5.0 * sizeScale;
    coordinate = texturecoordinate;

    highp float mul_x = 2.0 / mWidth;
    highp float mul_y = 2.0 / mHeight;

    // 14个采样点
    blurCoord1s[0] = texturecoordinate + vec2( 0.0 * mul_x, -10.0 * mul_y );
    blurCoord1s[1] = texturecoordinate + vec2( 8.0 * mul_x, -5.0 * mul_y );
    blurCoord1s[2] = texturecoordinate + vec2( 8.0 * mul_x, 5.0 * mul_y );
    blurCoord1s[3] = texturecoordinate + vec2( 0.0 * mul_x, 10.0 * mul_y );
    blurCoord1s[4] = texturecoordinate + vec2( -8.0 * mul_x, 5.0 * mul_y );
    blurCoord1s[5] = texturecoordinate + vec2( -8.0 * mul_x, -5.0 * mul_y );
    blurCoord1s[6] = texturecoordinate + vec2( 0.0 * mul_x, -6.0 * mul_y );
    blurCoord1s[7] = texturecoordinate + vec2( -4.0 * mul_x, -4.0 * mul_y );
    blurCoord1s[8] = texturecoordinate + vec2( -6.0 * mul_x, 0.0 * mul_y );
    blurCoord1s[9] = texturecoordinate + vec2( -4.0 * mul_x, 4.0 * mul_y );
    blurCoord1s[10] = texturecoordinate + vec2( 0.0 * mul_x, 6.0 * mul_y );
    blurCoord1s[11] = texturecoordinate + vec2( 4.0 * mul_x, 4.0 * mul_y );
    blurCoord1s[12] = texturecoordinate + vec2( 6.0 * mul_x, 0.0 * mul_y );
    blurCoord1s[13] = texturecoordinate + vec2( 4.0 * mul_x, -4.0 * mul_y );
}
