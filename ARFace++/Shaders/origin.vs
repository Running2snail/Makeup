attribute vec2 vPosition;
attribute vec2 inputTextureCoordinate;
varying vec2 texCoord;
void main(){
    texCoord = inputTextureCoordinate;
    gl_Position = vec4 (vPosition.x, vPosition.y, 0.0, 1.0);
}