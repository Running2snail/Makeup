
/*
 File: RosyWriterOpenGLRenderer.m
 Abstract: The RosyWriter OpenGL effect renderer
 Version: 2.1
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 */

#import "MGOpenGLRenderer.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GLESUtils.h"
#import "MGHeader.h"
#import "MGFaceModelArray.h"

@interface MGOpenGLRenderer ()
{
    EAGLContext *_oglContext;
    CVOpenGLESTextureCacheRef _textureCache;
    CVOpenGLESTextureCacheRef _renderTextureCache;
    CVPixelBufferPoolRef _bufferPool;
    CFDictionaryRef _bufferPoolAuxAttributes;
    CMFormatDescriptionRef _outputFormatDescription;
    
    GLuint _faceProgram;
    GLint _facePointSize;
    GLint _colorSelectorSlot;
    GLuint _faceFrameBuffer;
    GLuint _faceRenderBuffer;
    GLuint _facetexture;
    
    GLuint _videoProgram;
    GLuint _originVideoProgram;
    GLint _frame;
    GLint _originFrame;
    GLuint _offscreenBufferHandle;
    GLfloat _videoFrameW;
    GLfloat _videoFrameH;
    GLuint positionSlot;
    GLuint colorSlot;
    GLuint texCoordSlor;
    GLuint ourTexture;
    BOOL isOpenBeauty;
    
    GLuint _colorIndex;
    GLuint _colorAlpha;
    GLuint _beautyColor;
    
    GLuint _blurProgram;
    GLuint _frameBuffer;
    GLuint _renderedTexture;
    GLuint _blurPosition;
}

@property (nonatomic , strong) NSArray *colorArr;

@end

@implementation MGOpenGLRenderer

#pragma mark API

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        _oglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (!_oglContext) {
            NSLog( @"Problem with OpenGL context." );
            return nil;
        }
        isOpenBeauty = YES;
        _beautyAlphe = 0.2;
    }
    return self;
}


- (void)dealloc
{
    [self deleteBuffers];
    _oglContext = nil;
}

- (void)deleteBuffers
{
    EAGLContext *oldContext = [EAGLContext currentContext];
    if ( oldContext != _oglContext ) {
        if ( ! [EAGLContext setCurrentContext:_oglContext] ) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem with OpenGL context" userInfo:nil];
            return;
        }
    }
    if ( _offscreenBufferHandle ) {
        glDeleteFramebuffers( 1, &_offscreenBufferHandle );
        _offscreenBufferHandle = 0;
    }
    if ( _videoProgram ) {
        glDeleteProgram( _videoProgram );
        _videoProgram = 0;
    }
    if ( _originVideoProgram ) {
        glDeleteProgram( _originVideoProgram );
        _originVideoProgram = 0;
    }
    if (_faceProgram) {
        glDeleteProgram(_faceProgram);
        _faceProgram = 0;
    }
    if ( _textureCache ) {
        CFRelease( _textureCache );
        _textureCache = 0;
    }
    if ( _renderTextureCache ) {
        CFRelease( _renderTextureCache );
        _renderTextureCache = 0;
    }
    if ( _bufferPool ) {
        CFRelease( _bufferPool );
        _bufferPool = NULL;
    }
    if ( _bufferPoolAuxAttributes ) {
        CFRelease( _bufferPoolAuxAttributes );
        _bufferPoolAuxAttributes = NULL;
    }
    if ( _outputFormatDescription ) {
        CFRelease( _outputFormatDescription );
        _outputFormatDescription = NULL;
    }
    if ( oldContext != _oglContext ) {
        [EAGLContext setCurrentContext:oldContext];
    }
}

#pragma mark RosyWriterRenderer

- (BOOL)operatesInPlace
{
    return NO;
}

- (FourCharCode)inputPixelFormat
{
    return kCVPixelFormatType_32BGRA;
}

- (void)prepareForInputWithFormatDescription:(CMFormatDescriptionRef)inputFormatDescription outputRetainedBufferCountHint:(size_t)outputRetainedBufferCountHint
{
    // The input and output dimensions are the same. This renderer doesn't do any scaling.
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions( inputFormatDescription );
    
    [self deleteBuffers];
    if ( ! [self initializeBuffersWithOutputDimensions:dimensions retainedBufferCountHint:outputRetainedBufferCountHint] ) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem preparing renderer." userInfo:nil];
    }
}

- (void)reset
{
    [self deleteBuffers];
}


- (CVPixelBufferRef )drawPixelBuffer:(CMSampleBufferRef)sampleBufferRef custumDrawing:(void (^)(void))draw
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
    
    if ( _offscreenBufferHandle == 0 ) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unintialized buffer" userInfo:nil];
        return nil;
    }
    
    if ( pixelBuffer == NULL ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL pixel buffer" userInfo:nil];
        return nil;
    }
    
    const CMVideoDimensions srcDimensions = { (int32_t)CVPixelBufferGetWidth(pixelBuffer), (int32_t)CVPixelBufferGetHeight(pixelBuffer) };
    const CMVideoDimensions dstDimensions = CMVideoFormatDescriptionGetDimensions( _outputFormatDescription );
    
    _videoFrameW = dstDimensions.width;
    _videoFrameH = dstDimensions.height;
    
    if ( _videoFrameW != _videoFrameW || _videoFrameH != _videoFrameH ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid pixel buffer dimensions" userInfo:nil];
        return nil;
    }
    
    if ( CVPixelBufferGetPixelFormatType( pixelBuffer ) != kCVPixelFormatType_32BGRA ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid pixel buffer format" userInfo:nil];
        return nil;
    }
    
    EAGLContext *oldContext = [EAGLContext currentContext];
    if ( oldContext != _oglContext ) {
        if ( ! [EAGLContext setCurrentContext:_oglContext] ) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem with OpenGL context" userInfo:nil];
            return nil;
        }
    }
    
    CVReturn err = noErr;
    CVOpenGLESTextureRef srcTexture = NULL, dstTexture = NULL;
    CVPixelBufferRef dstPixelBuffer = NULL;
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _textureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RGBA,
                                                       _videoFrameW, _videoFrameH,
                                                       GL_BGRA,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &srcTexture );
    if ( ! srcTexture || err ) {
        NSLog( @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err );
        goto bail;
    }
    
    err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes( kCFAllocatorDefault, _bufferPool, _bufferPoolAuxAttributes, &dstPixelBuffer );
    if ( err == kCVReturnWouldExceedAllocationThreshold ) {
        // Flush the texture cache to potentially release the retained buffers and try again to create a pixel buffer
        CVOpenGLESTextureCacheFlush( _renderTextureCache, 0 );
        err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes( kCFAllocatorDefault, _bufferPool, _bufferPoolAuxAttributes, &dstPixelBuffer );
    }
    if ( err ) {
        if ( err == kCVReturnWouldExceedAllocationThreshold ) {
            NSLog( @"Pool is out of buffers, dropping frame" );
        }
        else {
            NSLog( @"Error at CVPixelBufferPoolCreatePixelBuffer %d", err );
        }
        goto bail;
    }
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage( kCFAllocatorDefault,
                                                       _renderTextureCache,
                                                       dstPixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RGBA,
                                                       _videoFrameW, _videoFrameH,
                                                       GL_BGRA,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &dstTexture );
    
    if ( ! dstTexture || err ) {
        NSLog( @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err );
        goto bail;
    }
    
    glBindFramebuffer( GL_FRAMEBUFFER, _offscreenBufferHandle );
    glViewport( 0, 0, srcDimensions.width, srcDimensions.height );
    if (isOpenBeauty) {
        glUseProgram( _videoProgram );
    } else {
        glUseProgram( _originVideoProgram );
    }
    
//    [self setVideoProgram];
    // Set up our destination pixel buffer as the framebuffer's render target.
    glActiveTexture( GL_TEXTURE0 );
    glBindTexture( CVOpenGLESTextureGetTarget( dstTexture ), CVOpenGLESTextureGetName( dstTexture ) );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    
    glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget( dstTexture ), CVOpenGLESTextureGetName( dstTexture ), 0 );
    
    // Render our source pixel buffer.
    glActiveTexture( GL_TEXTURE1 );
    glBindTexture( CVOpenGLESTextureGetTarget( srcTexture ), CVOpenGLESTextureGetName( srcTexture ) );
    
    if (isOpenBeauty) {
        glUniform1i(_frame, 1 );
    } else {
        glUniform1i(_originFrame, 1 );
    }
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
    glEnableVertexAttribArray( ATTRIB_VERTEX );
    
    glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureVertices);
    glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON );
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindTexture( CVOpenGLESTextureGetTarget( srcTexture ), 0 );
    glBindTexture( CVOpenGLESTextureGetTarget( dstTexture ), 0 );
    
    if (draw != nil) {
        draw();
    }
    glFlush();
    
bail:
    if ( oldContext != _oglContext ) {
        [EAGLContext setCurrentContext:oldContext];
    }
    if ( srcTexture ) {
        CFRelease( srcTexture );
    }
    if ( dstTexture ) {
        CFRelease( dstTexture );
    }
    
    return dstPixelBuffer;
}

- (void)drawFaceLandMark:(MGFaceModelArray *)faces
{
    if (!faces || faces.count == 0) return;
    [self setFaceFrameBuffer];
    glActiveTexture(GL_TEXTURE2);
    GLint beautyColor = glGetUniformLocation(_faceProgram, "beautyColor");
    glUseProgram(_faceProgram);
    GLfloat colorArr[] = {
        1, 0.0, 0.0,
        0.6, 0.04, 0.04,
        0.91, 0.07, 0.4,
        0.84, 0.05, 0.58,
        0.99, 0.09, 0.45,
        0.45, 0.03, 0.45,
        0.65, 0.28, 0.03
    };
    glUniform4f(beautyColor, colorArr[_beautyIndex * 3], colorArr[_beautyIndex * 3 + 1], colorArr[_beautyIndex * 3 + 2], _beautyAlphe);
    glBindTexture(GL_TEXTURE_2D, _facetexture);
    for (int i =0; i < faces.count; i++) {
        MGFaceInfo *model = [faces modelWithIndex:i];
        [self drawFacePointer:model.points faceRect:model.rect];
    }
}


- (void)dealWithBeautyWithType:(BOOL)isOpen;
{
    isOpenBeauty = isOpen;
}



- (CMFormatDescriptionRef)outputFormatDescription
{
    return _outputFormatDescription;
}

- (void)setupFaceProgram
{
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"FacePointSize"
                                                                 ofType:@"glsl"];
    NSString *fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"FacePointColor"
                                                                   ofType:@"glsl"];
    GLuint programHandle = [GLESUtils loadProgram:vertexShaderPath
                       withFragmentShaderFilepath:fragmentShaderPath];
    if (programHandle == 0) {
        NSLog(@" >> Error: Failed to setup face program.");
        return;
    }
    _faceProgram = programHandle;
    _colorSelectorSlot = glGetUniformLocation(_faceProgram, "sizeScale");
    GLint text = glueGetUniformLocation(_faceProgram, "Tex");
    glUniform1i(text, 1);
}



- (void)setupVideoProgram
{
    //Load vertex and fragment shaders
    GLint attribLocation[NUM_ATTRIBUTES] = {
        ATTRIB_VERTEX, ATTRIB_TEXTUREPOSITON,
    };
    GLchar *attribName[NUM_ATTRIBUTES] = {
        "position", "texturecoordinate",
    };

    const GLchar *originVertSrc = [GLESUtils readFile:@"VideoVert.glsl"];
    const GLchar *originFragSrc = [GLESUtils readFile:@"VideoFrag.glsl"];
    glueCreateProgram(originVertSrc, originFragSrc,
                      NUM_ATTRIBUTES, (const GLchar **)&attribName[0], attribLocation,
                      0, 0, 0,
                      &_originVideoProgram );

    if (_originVideoProgram == 0) {
        NSLog( @"Problem initializing the program." );
    }

  
    const GLchar *vertSrc = [GLESUtils readFile:@"beautys.vs"];
    const GLchar *fragSrc = [GLESUtils readFile:@"beautys.frag"];
    glueCreateProgram(vertSrc, fragSrc,
                      NUM_ATTRIBUTES, (const GLchar **)&attribName[0], attribLocation,
                      0, 0, 0,
                      &_videoProgram );

    if (_videoProgram == 0) {
        NSLog( @"Problem initializing the program." );
    }
   
}

- (void)setupBlureProgram
{
    GLint attribLocation[NUM_ATTRIBUTES] = {
        ATTRIB_VERTEX, ATTRIB_TEXTUREPOSITON,
    };
    GLchar *attribName[NUM_ATTRIBUTES] = {
        "position", "texturecoordinate",
    };
    
    const GLchar *originVertSrc = [GLESUtils readFile:@"blurVert.glsl"];
    const GLchar *originFragSrc = [GLESUtils readFile:@"blurFrag.glsl"];
    glueCreateProgram(originVertSrc, originFragSrc,
                      NUM_ATTRIBUTES, (const GLchar **)&attribName[0], attribLocation,
                      0, 0, 0,
                      &_blurProgram );
    
    if (_blurProgram == 0) {
        NSLog( @"Problem initializing the program." );
    }
    glBindTexture(GL_TEXTURE_2D, _facetexture);
    _renderedTexture = glueGetUniformLocation(_blurProgram, "renderedTexture");
    glUniform1f(_renderedTexture, 0);
//    GLuint texID = glGetUniformLocation(_blurProgram, "textureCoordinate");
//    glUniform1i(texID, 0);
}

#pragma mark Internal
- (BOOL)initializeBuffersWithOutputDimensions:(CMVideoDimensions)outputDimensions retainedBufferCountHint:(size_t)clientRetainedBufferCountHint
{
    BOOL success = YES;
    
    EAGLContext *oldContext = [EAGLContext currentContext];
    if ( oldContext != _oglContext ) {
        if ( ! [EAGLContext setCurrentContext:_oglContext] ) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem with OpenGL context" userInfo:nil];
            return NO;
        }
    }
    
    glDisable( GL_DEPTH_TEST );
    
    glGenFramebuffers( 1, &_offscreenBufferHandle );
    glBindFramebuffer( GL_FRAMEBUFFER, _offscreenBufferHandle );
    
    CVReturn err = CVOpenGLESTextureCacheCreate( kCFAllocatorDefault, NULL, _oglContext, NULL, &_textureCache );
    if ( err ) {
        NSLog( @"Error at CVOpenGLESTextureCacheCreate %d", err );
        success = NO;
        goto bail;
    }
    
    err = CVOpenGLESTextureCacheCreate( kCFAllocatorDefault, NULL, _oglContext, NULL, &_renderTextureCache );
    if ( err ) {
        NSLog( @"Error at CVOpenGLESTextureCacheCreate %d", err );
        success = NO;
        goto bail;
    }
    
    [self setupVideoProgram];
    _frame = glueGetUniformLocation(_videoProgram, "videoframe");
    _originFrame = glueGetUniformLocation(_originVideoProgram, "videoframe");
    /*设置人脸标点图层Program*/
    [self setupFaceProgram];
    [self setupBlureProgram];
//    [self setRenderToTesture];
//    [self fullscreenFBO];
    
    size_t maxRetainedBufferCount = clientRetainedBufferCountHint;
    _bufferPool = createPixelBufferPool(outputDimensions.width, outputDimensions.height, kCVPixelFormatType_32BGRA, (int32_t)maxRetainedBufferCount );
    if (! _bufferPool) {
        NSLog( @"Problem initializing a buffer pool." );
        success = NO;
        goto bail;
    }
    
    _bufferPoolAuxAttributes = createPixelBufferPoolAuxAttributes((int32_t)maxRetainedBufferCount);
    preallocatePixelBuffersInPool(_bufferPool, _bufferPoolAuxAttributes);
    
    CMFormatDescriptionRef outputFormatDescription = NULL;
    CVPixelBufferRef testPixelBuffer = NULL;
    CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, _bufferPool, _bufferPoolAuxAttributes, &testPixelBuffer );
    if ( ! testPixelBuffer ) {
        NSLog( @"Problem creating a pixel buffer." );
        success = NO;
        goto bail;
    }
    CMVideoFormatDescriptionCreateForImageBuffer( kCFAllocatorDefault, testPixelBuffer, &outputFormatDescription );
    _outputFormatDescription = outputFormatDescription;
    CFRelease( testPixelBuffer );
    
bail:
    if ( ! success ) {
        [self deleteBuffers];
    }
    if ( oldContext != _oglContext ) {
        [EAGLContext setCurrentContext:oldContext];
    }
    return success;
}

static CVPixelBufferPoolRef createPixelBufferPool(int32_t width, int32_t height, FourCharCode pixelFormat, int32_t maxBufferCount )
{
    CVPixelBufferPoolRef outputPool = NULL;
    
    NSDictionary *sourcePixelBufferOptions = @{(id)kCVPixelBufferPixelFormatTypeKey : @(pixelFormat),
                                               (id)kCVPixelBufferWidthKey : @(width),
                                               (id)kCVPixelBufferHeightKey : @(height),
                                               (id)kCVPixelFormatOpenGLESCompatibility : @(YES),
                                               (id)kCVPixelBufferIOSurfacePropertiesKey : @{ /*empty dictionary*/ } };
    
    NSDictionary *pixelBufferPoolOptions = @{ (id)kCVPixelBufferPoolMinimumBufferCountKey : @(maxBufferCount) };
    
    CVPixelBufferPoolCreate(kCFAllocatorDefault, (__bridge CFDictionaryRef)pixelBufferPoolOptions, (__bridge CFDictionaryRef)sourcePixelBufferOptions, &outputPool );
    
    return outputPool;
}

static CFDictionaryRef createPixelBufferPoolAuxAttributes(int32_t maxBufferCount)
{
    // CVPixelBufferPoolCreatePixelBufferWithAuxAttributes() will return kCVReturnWouldExceedAllocationThreshold if we have already vended the max number of buffers
    return CFRetain((__bridge CFTypeRef)(@{(id)kCVPixelBufferPoolAllocationThresholdKey : @(maxBufferCount)}));
}

static void preallocatePixelBuffersInPool( CVPixelBufferPoolRef pool, CFDictionaryRef auxAttributes )
{
    // Preallocate buffers in the pool, since this is for real-time display/capture
    NSMutableArray *pixelBuffers = [[NSMutableArray alloc] init];
    while ( 1 )
    {
        CVPixelBufferRef pixelBuffer = NULL;
        OSStatus err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes( kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer );
        
        if ( err == kCVReturnWouldExceedAllocationThreshold ) {
            break;
        }
        assert( err == noErr );
        
        [pixelBuffers addObject:(__bridge id)(pixelBuffer)];
        CFRelease( pixelBuffer );
    }
}

#pragma mark - 绘制矩形
- (void)drawRect:(CGRect )rect
{
    if (CGRectIsNull(rect))  return;
    
    GLfloat lineWidth = _videoFrameH/480.0 * 3.0;
    glLineWidth(lineWidth);
    
    GLfloat top = (rect.origin.y - _videoFrameH/2) / (_videoFrameH/2);
    GLfloat left = (_videoFrameW/2 - rect.origin.x) / (_videoFrameW/2);
    GLfloat right = (_videoFrameW/2 - (rect.origin.x+rect.size.width)) / (_videoFrameW/2);
    GLfloat bottom = ((rect.origin.y + rect.size.height) - _videoFrameH/2) / (_videoFrameH/2);
    
    GLfloat tempFace[]= {
        right, top, 0.0f, // right  top
        left, top, 0.0f, // left  top
        left,  bottom, 0.0f, // left bottom
        right,  bottom, 0.0f, // right Bottom
    };
    GLubyte indices[] = {
        0, 1, 1, 2, 2, 3, 3, 0
    };
    
    glVertexAttribPointer( 0, 3, GL_FLOAT, GL_FALSE, 0, tempFace );
    glEnableVertexAttribArray(0 );
    glDrawElements(GL_LINES, sizeof(indices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, indices);
}

#pragma mark - 绘制关键点
- (void)drawFaceWithRect:(CGRect)rect {
    if (CGRectIsNull(rect))  return;
    
    GLfloat lineWidth = _videoFrameH/480.0 * 3.0;
    glLineWidth(lineWidth);
    
    GLfloat top = [self changeToGLPointT:rect.origin.y];
    GLfloat left = [self changeToGLPointL:rect.origin.x];
    GLfloat right = [self changeToGLPointR:rect.size.width];
    GLfloat bottom = [self changeToGLPointB:rect.size.height];
    
    GLfloat tempFace[] = {
        bottom,left,0.0f,
        top, left, 0.0f,
        top, right, 0.0f,
        bottom,right,0.0f,
    };
    
    GLubyte indices[] = {
        0, 1, 1, 2, 2, 3, 3, 0
    };
    
    glVertexAttribPointer( 0, 3, GL_FLOAT, GL_FALSE, 0, tempFace );
    glEnableVertexAttribArray(0 );
    glDrawElements(GL_LINES, sizeof(indices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, indices);
}


//- (void)didDrawImageViaOpenGLES:(UIImage *)image pointArr:(NSArray *)pointArr
//{
//    // 将image绑定到GL_TEXTURE_2D上，即传递到GPU中
//   GLuint texture = [self setupTexture:image];
//    // 此时，纹理数据就可看做已经在纹理对象_textureID中了，使用时从中取出即可
//
//    // 第一行和第三行不是严格必须的，默认使用GL_TEXTURE0作为当前激活的纹理单元
//    glActiveTexture(GL_TEXTURE5); // 指定纹理单元GL_TEXTURE5
//    glBindTexture(GL_TEXTURE_2D, texture); // 绑定，即可从_textureID中取出图像数据。
////    glUniform1i(ourTexture, 5); // 与纹理单元的序号对应
//
//    // 渲染需要的数据要从GL_TEXTURE_2D中得到。
//    // GL_TEXTURE_2D与_textureID已经绑定
//    [self renderEyeBrowsWithArr:pointArr];
//}

//- (GLuint)setupTexture:(UIImage *)image {
//    CGImageRef cgImageRef = [image CGImage];
//    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
//    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
//    CGRect rect = CGRectMake(0, 0, width, height);
//
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    void *imageData = malloc(width * height * 4);
//    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
//    CGContextTranslateCTM(context, 0, height);
//    CGContextScaleCTM(context, 1.0f, -1.0f);
//    CGColorSpaceRelease(colorSpace);
//    CGContextClearRect(context, rect);
//    CGContextDrawImage(context, rect, cgImageRef);
//
//    glEnable(GL_TEXTURE_2D);
//
//    /**
//     *  GL_TEXTURE_2D表示操作2D纹理
//     *  创建纹理对象，
//     *  绑定纹理对象，
//     */
//
//    GLuint textureID;
//    glGenTextures(1, &textureID);
//    glBindTexture(GL_TEXTURE_2D, textureID);
//
//    /**
//     *  纹理过滤函数
//     *  图象从纹理图象空间映射到帧缓冲图象空间(映射需要重新构造纹理图像,这样就会造成应用到多边形上的图像失真),
//     *  这时就可用glTexParmeteri()函数来确定如何把纹理象素映射成像素.
//     *  如何把图像从纹理图像空间映射到帧缓冲图像空间（即如何把纹理像素映射成像素）
//     */
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); // S方向上的贴图模式
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); // T方向上的贴图模式
//    // 线性过滤：使用距离当前渲染像素中心最近的4个纹理像素加权平均值
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//
//    /**
//     *  将图像数据传递给到GL_TEXTURE_2D中, 因其于textureID纹理对象已经绑定，所以即传递给了textureID纹理对象中。
//     *  glTexImage2d会将图像数据从CPU内存通过PCIE上传到GPU内存。
//     *  不使用PBO时它是一个阻塞CPU的函数，数据量大会卡。
//     */
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
//
//    // 结束后要做清理
//    glBindTexture(GL_TEXTURE_2D, 0); //解绑
//    CGContextRelease(context);
//    free(imageData);
//
//    return textureID;
//}

//
//- (void)setRenderToTexture
//{
////    创建帧缓冲区对象
//    glGenFramebuffers(1, &_frameBuffer);
//    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
//
//   //创建纹理对象并绑定
//    glGenTextures(1, &_renderedTexture);
//    glBindTexture(GL_TEXTURE_2D, _renderedTexture);
//
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 640, 480, 0, GL_RGB, GL_UNSIGNED_BYTE, 0);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
//
//    //创建深度缓存区
//    GLuint depthrenderbuffer;
//    glGenRenderbuffers(1, &depthrenderbuffer);
//    glBindRenderbuffer(GL_RENDERBUFFER, depthrenderbuffer);
//    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, 640, 480);
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthrenderbuffer);
//
//    // 将纹理配置到帧缓存中
//    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _renderedTexture, 0);
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, _renderedTexture, 0);
//    glDrawArrays(GL_COLOR_ATTACHMENT0, 0, 1);
//    if ( glCheckFramebufferStatus( GL_FRAMEBUFFER ) != GL_FRAMEBUFFER_COMPLETE ) {
//        NSLog( @"Failure with framebuffer generation" );
//    }
//    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
//    glViewport(0, 0, 640, 480);
//}

//- (void)fullscreenFBO
//{
//    static const GLfloat g_quad_vertex_buffer_data[] = {
//        -1.0f, -1.0f, 0.0f,
//        1.0f, -1.0f, 0.0f,
//        -1.0f,  1.0f, 0.0f,
//        -1.0f,  1.0f, 0.0f,
//        1.0f, -1.0f, 0.0f,
//        1.0f,  1.0f, 0.0f,
//    };
//
//    GLuint quad_vertexbuffer;
//    glGenBuffers(1, &quad_vertexbuffer);
//    glBindBuffer(GL_ARRAY_BUFFER, quad_vertexbuffer);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(g_quad_vertex_buffer_data), g_quad_vertex_buffer_data, GL_STATIC_DRAW);
//    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"blurVert"
//                                                                 ofType:@"glsl"];
//    NSString *fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"blurFrag"
//                                                                   ofType:@"glsl"];
//    GLuint programHandle = [GLESUtils loadProgram:vertexShaderPath
//                       withFragmentShaderFilepath:fragmentShaderPath];
//    _blurProgram = programHandle;
//    GLuint texID = glGetUniformLocation(_blurProgram, "textureCoordinate");
//    glUniform1i(texID, 0);
//    _blurPosition = glGetUniformLocation(_blurProgram, "position");
//}
//
//- (void)renderToTheScreen
//{
//    glBindFramebuffer(GL_FRAMEBUFFER, 0);
//    glViewport(0, 0, 640, 480);
//}

- (void)setFaceFrameBuffer
{
    //创建帧缓冲区对象
    glGenFramebuffers(1, &_faceFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _faceFrameBuffer);

    //将2D纹理图像附加到FBO
    glGenTextures(1, &_facetexture);
    glBindTexture(GL_TEXTURE_2D, _facetexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 640, 480, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindTexture(GL_TEXTURE_2D, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _facetexture, 0);
    
    //创建深度缓存区
    glGenRenderbuffers(1, &_faceRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _faceRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, 640, 480);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _faceRenderBuffer);
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"FramebufferError");
    }
//    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

- (void)unBindFaceFrameBuffer
{
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, 0);
}



- (void)drawFacePointer:(NSArray *)pointArray faceRect:(CGRect)rect
{
//    if (pointArray.count >= 81) {
//        [self renderWithArr:@[pointArray[50], pointArray[44], pointArray[52]]];
//        [self renderWithArr:@[pointArray[50], pointArray[52], pointArray[48]]];
//        [self renderWithArr:@[pointArray[48] ,pointArray[52], pointArray[46]]];
//        [self renderWithArr:@[pointArray[46] ,pointArray[52], pointArray[47]]];
//        [self renderWithArr:@[pointArray[46], pointArray[47], pointArray[49]]];
//        [self renderWithArr:@[pointArray[49], pointArray[47], pointArray[53]]];
//        [self renderWithArr:@[pointArray[49], pointArray[53], pointArray[51]]];
//        [self renderWithArr:@[pointArray[51], pointArray[53], pointArray[45]]];
//
//        [self renderWithArr:@[pointArray[58], pointArray[44], pointArray[56]]];
//        [self renderWithArr:@[pointArray[58], pointArray[59], pointArray[56]]];
//        [self renderWithArr:@[pointArray[59] ,pointArray[56], pointArray[54]]];
//        [self renderWithArr:@[pointArray[59] ,pointArray[54], pointArray[55]]];
//        [self renderWithArr:@[pointArray[55], pointArray[54], pointArray[60]]];
//        [self renderWithArr:@[pointArray[60], pointArray[54], pointArray[57]]];
//        [self renderWithArr:@[pointArray[60], pointArray[57], pointArray[61]]];
//        [self renderWithArr:@[pointArray[61], pointArray[57], pointArray[45]]];
//    }
    if (pointArray.count >= 106) {
        [self renderWithArr:@[pointArray[84], pointArray[96], pointArray[85]]];
        [self renderWithArr:@[pointArray[96], pointArray[97], pointArray[85]]];
        [self renderWithArr:@[pointArray[97] ,pointArray[85], pointArray[86]]];
        [self renderWithArr:@[pointArray[97] ,pointArray[86], pointArray[98]]];
        [self renderWithArr:@[pointArray[98], pointArray[86], pointArray[87]]];
        [self renderWithArr:@[pointArray[98], pointArray[87], pointArray[88]]];
        [self renderWithArr:@[pointArray[98], pointArray[88], pointArray[99]]];
        [self renderWithArr:@[pointArray[99], pointArray[88], pointArray[89]]];
        [self renderWithArr:@[pointArray[99], pointArray[89], pointArray[100]]];
        [self renderWithArr:@[pointArray[100], pointArray[89], pointArray[90]]];

        [self renderWithArr:@[pointArray[84], pointArray[96], pointArray[95]]];
        [self renderWithArr:@[pointArray[96], pointArray[95], pointArray[103]]];
        [self renderWithArr:@[pointArray[103] ,pointArray[95], pointArray[94]]];
        [self renderWithArr:@[pointArray[103] ,pointArray[94], pointArray[102]]];
        [self renderWithArr:@[pointArray[102], pointArray[94], pointArray[93]]];
        [self renderWithArr:@[pointArray[102], pointArray[93], pointArray[92]]];
        [self renderWithArr:@[pointArray[102], pointArray[92], pointArray[91]]];
        [self renderWithArr:@[pointArray[102], pointArray[91], pointArray[101]]];
        [self renderWithArr:@[pointArray[101], pointArray[91], pointArray[100]]];
        [self renderWithArr:@[pointArray[100], pointArray[91], pointArray[90]]];
    }
//        GLfloat lineWidth = _videoFrameH/480.0;
    
//        const GLfloat lineWidth = rect.size.width/WIN_WIDTH * 1.5;
//        glUniform1f(_facePointSize, lineWidth);
//
//        const GLsizei pointCount = (GLsizei)pointArray.count;
//        GLfloat tempPoint[pointCount * 3];
//        GLubyte indices[pointCount];
//        for (int i = 0; i < pointArray.count; i ++) {
//            CGPoint pointer = [pointArray[i] CGPointValue];
//            GLfloat top = [self changeToGLPointT:pointer.x];
//            GLfloat left = [self changeToGLPointL:pointer.y];
//
//            tempPoint[i*3+0]=top;
//            tempPoint[i*3+1]=left;
//            tempPoint[i*3+2]=0.0f;
//
//            indices[i]=i;
//        }
//        glVertexAttribPointer( 0, 3, GL_FLOAT, GL_TRUE, 0, tempPoint );
//        glEnableVertexAttribArray(GL_VERTEX_ATTRIB_ARRAY_POINTER);
//        glDrawElements(GL_POINTS, (GLsizei)sizeof(indices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, indices);
}


// 渲染
- (void)renderWithArr:(NSArray *)pointArr
{
    CGPoint pointer1 = [pointArr[0] CGPointValue];
    CGPoint pointer2 = [pointArr[1] CGPointValue];
    CGPoint pointer3 = [pointArr[2] CGPointValue];
    GLfloat verteices[] = {
        [self changeToGLPointT:pointer1.x],  [self changeToGLPointL:pointer1.y],  0.0f,
        [self changeToGLPointT:pointer2.x],  [self changeToGLPointL:pointer2.y],  0.0f,
        [self changeToGLPointT:pointer3.x],  [self changeToGLPointL:pointer3.y],  0.0f
    };
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, verteices);
    glEnableVertexAttribArray(0);
    glDrawArrays(GL_TRIANGLES, 0, 3);
}

- (GLfloat)changeToGLPointT:(CGFloat)x{
    GLfloat tempX = (x - _videoFrameW/2) / (_videoFrameW/2);
    
    return tempX;
}
- (GLfloat)changeToGLPointL:(CGFloat)y{
    GLfloat tempY = (_videoFrameH/2 - (_videoFrameH - y)) / (_videoFrameH/2);
    return tempY;
}
- (GLfloat)changeToGLPointR:(CGFloat)y{
    GLfloat tempR = (_videoFrameH/2 - y) / (_videoFrameH/2);
    return tempR;
}
- (GLfloat)changeToGLPointB:(CGFloat)y{
    GLfloat tempB = (y - _videoFrameW/2) / (_videoFrameW/2);
    return tempB;
}


static void rotatePoint3f(float *points, int offset, float angle/*radis*/, int x_axis, int y_axis) {
    float x = points[offset + x_axis], y = points[offset + y_axis];
    float alpha_x = cosf(angle), alpha_y = sinf(angle);
    
    points[offset + x_axis] = x * alpha_x - y * alpha_y;
    points[offset + y_axis] = x * alpha_y + y * alpha_x;
}

- (void)drawTriConeX:(float)pitch Y:(float)yaw Z:(float)roll {
    
    GLfloat lineWidth = _videoFrameH/480.0 * 2.0;
    glLineWidth(lineWidth);
    
    GLfloat vertices[] = {
        0.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        0.0f, -1.0f, 0.0f,
        0.0f, 0.0f, -1.0f
    };
    int n = sizeof(vertices) / sizeof(GLfloat) / 3;
    
    float a = 0.2;
    GLfloat resize = _videoFrameW / _videoFrameH;
    for (int i = 0; i < n; ++i) {
        rotatePoint3f(vertices, i * 3, yaw, 2, 0);
        rotatePoint3f(vertices, i * 3, pitch, 2, 1);
        rotatePoint3f(vertices, i * 3, roll, 0, 1);
        
        vertices[i * 3 + 0] = vertices[i * 3 + 0] * a * 1 + 0.8f;
        vertices[i * 3 + 1] = vertices[i * 3 + 1] * a * resize + 0;
        vertices[i * 3 + 2] = vertices[i * 3 + 2] * a * 1 + 0;
    }
    
    GLubyte indices[] = {0, 1, 0, 2, 0, 3};
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_TRUE, 0, vertices );
    glEnableVertexAttribArray(GL_VERTEX_ATTRIB_ARRAY_POINTER);
    
    for (int i = 0; i < 3; ++i) {
        glUniform1f(_colorSelectorSlot, (float)(i + 1));
        glDrawElements(GL_LINES, 2, GL_UNSIGNED_BYTE, indices + i * 2);
    }
}

- (void)setUpOutSampleBuffer:(CGSize)outSize devicePosition:(AVCaptureDevicePosition)devicePosition{
    [EAGLContext setCurrentContext:_oglContext];
    
    CMVideoDimensions dimensions;
    dimensions.width = outSize.width;
    dimensions.height = outSize.height;
    
    [self deleteBuffers];
    if ( ! [self initializeBuffersWithOutputDimensions:dimensions retainedBufferCountHint:6] ) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem preparing renderer." userInfo:nil];
    }
}

@end

