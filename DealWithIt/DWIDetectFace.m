//
//  DWIDetectFace.m
//  DealWithIt
//
//  Created by Simon Frost on 03/04/2013.
//  Copyright (c) 2013 Orangeninja. All rights reserved.
//
//  Taken from tutorial at http://www.devbridge.com/articles/face-recognition-ios-christmas-edition
//

#import "DWIDetectFace.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>


@interface DWIDetectFace() <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) CIDetector *faceDetector;

@end


@implementation DWIDetectFace


- (void) setupAVCapture
{
    AVCaptureSession *session = [AVCaptureSession new];
    [session setSessionPreset:AVCaptureSessionPreset1280x720];
    
    // Set up a device pointer
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Get the front camera
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
        for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
            if (d.position == AVCaptureDevicePositionFront)
                device = d;
        }
    }
    
    
    NSError *error = nil;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        exit(0);
    }
    
    if ([session canAddInput:deviceInput])
        [session addInput:deviceInput];
    
    // Create a new video output
    self.videoDataOutput = [AVCaptureVideoDataOutput new];
    
    // CoreGraphics and OpenGL work well with BGRA so set this as the format
    NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:@(kCMPixelFormat_32BGRA)
                                                                  forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    [self.videoDataOutput setVideoSettings:rgbOutputSettings];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
    
    
    if ([session canAddOutput:self.videoDataOutput])
        [session addOutput:self.videoDataOutput];
  
    [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
    
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    self.previewLayer.backgroundColor = [UIColor blackColor].CGColor;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    CALayer *rootLayer = self.previewView.layer;
    rootLayer.masksToBounds = YES;
    self.previewLayer.frame = rootLayer.bounds;
    [rootLayer addSublayer:self.previewLayer];
    [session startRunning];
}


- (void) captureOutput:(AVCaptureOutput *)captureOutput
 didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
    if (attachments)
        CFRelease(attachments);
    
    int exifOrientation = 2; // 6 means portrait with 0th row on right, 0th column on top
    NSDictionary *imageOptions = [NSDictionary dictionaryWithObject:CIDetectorImageOrientation
                                                             forKey:@(exifOrientation)];
    NSArray *features = [_faceDetector featuresInImage:ciImage options:imageOptions];
    
    // Get the rectangle representing image data valid for display
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGSize parentFrameSize = self.previewView.frame.size;
        NSString *gravity = _previewLayer.videoGravity;
        
        CGRect previewBox = [DWIDetectFace videoPreviewBoxForGravity:gravity
                                                           frameSize:parentFrameSize
                                                        apertureSize:clap.size];
        [self.delegate detectedFaceController:self
                                     features:features
                                  forVideoBox:clap
                               withPreviewBox:previewBox];
    });
}


- (void) startDetection
{
    [self setupAVCapture];
    [[_videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
    NSDictionary *detectorOptions = @{CIDetectorAccuracy : CIDetectorAccuracyLow};
    _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                       context:nil
                                       options:detectorOptions];
}


- (void) stopDetection
{
    if (_videoDataOutputQueue)
        _videoDataOutputQueue = nil;
}



// find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
    
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
    
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}



+ (CGRect)convertFrame:(CGRect)originalFrame previewBox:(CGRect)previewBox forVideoBox:(CGRect)videoBox isMirrored:(BOOL)isMirrored
{
    // flip preview width and height
    CGFloat temp = originalFrame.size.width;
    originalFrame.size.width = originalFrame.size.height;
    originalFrame.size.height = temp;
    temp = originalFrame.origin.x;
    originalFrame.origin.x = originalFrame.origin.y;
    originalFrame.origin.y = temp;
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy = previewBox.size.width / videoBox.size.height;
    CGFloat heightScaleBy = previewBox.size.height / videoBox.size.width;
    originalFrame.size.width *= widthScaleBy;
    originalFrame.size.height *= heightScaleBy;
    originalFrame.origin.x *= widthScaleBy;
    originalFrame.origin.y *= heightScaleBy;
    
    if(isMirrored)
    {
        originalFrame = CGRectOffset(originalFrame, previewBox.origin.x + previewBox.size.width - originalFrame.size.width - (originalFrame.origin.x * 2), previewBox.origin.y);
    }
    else
    {
        originalFrame = CGRectOffset(originalFrame, previewBox.origin.x, previewBox.origin.y);
    }
    
    return originalFrame;
}


@end
