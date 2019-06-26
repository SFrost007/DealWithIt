//
//  DWIMainViewController.m
//  DealWithIt
//
//  Created by Simon Frost on 03/04/2013.
//  Copyright (c) 2013 Orangeninja. All rights reserved.
//

#import "DWIMainViewController.h"

@implementation DWIMainViewController {
    UIView *_previewView;
    UIImageView *_shades;
    DWIDetectFace *_detectFaceController;
}

- (void) loadView
{
    CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
    self.view = [[UIView alloc] initWithFrame:viewFrame];
    
    _shades = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Shades.png"]];
    _shades.contentMode = UIViewContentModeScaleToFill;
    _shades.hidden = YES;
    
    _previewView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewFrame.size.width, viewFrame.size.height)];
    [self.view addSubview:_previewView];
    [self.view addSubview:_shades];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _detectFaceController = [[DWIDetectFace alloc] init];
    _detectFaceController.delegate = self;
    _detectFaceController.previewView = _previewView;
    [_detectFaceController startDetection];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [_detectFaceController stopDetection];
    [super viewWillDisappear:animated];
}


- (void) detectedFaceController:(DWIDetectFace *)controller
                       features:(NSArray *)features
                    forVideoBox:(CGRect)clap
                 withPreviewBox:(CGRect)previewBox
{
    if (!features.count) {
        _shades.hidden = YES;
        return;
    }
    for (CIFaceFeature *feature in features) {
        CGRect faceRect = feature.bounds;
        faceRect = [DWIDetectFace convertFrame:faceRect previewBox:previewBox forVideoBox:clap isMirrored:YES];
        
        if (feature.hasLeftEyePosition && feature.hasRightEyePosition) {
            CGPoint leftEye = feature.leftEyePosition;
            CGPoint rightEye = feature.rightEyePosition;
            
            CGFloat xPos = MIN(leftEye.y, rightEye.y);
            CGFloat yPos = MIN(leftEye.x, rightEye.x);
            CGFloat width = ABS(leftEye.y - rightEye.y);
            CGFloat height = ABS(leftEye.x - rightEye.x);
            CGRect shadesRect = CGRectMake(xPos, yPos, width, height);
            shadesRect = faceRect;
            shadesRect.origin.x *= 0.9;
            shadesRect.origin.y *= 0.9;
            
            NSLog(@"faceRect: %@", NSStringFromCGRect(faceRect));
            NSLog(@"Left eye: %@, Right eye: %@", NSStringFromCGPoint(leftEye), NSStringFromCGPoint(rightEye));
            NSLog(@"Shades frame: %@", NSStringFromCGRect(shadesRect));
            
            _shades.frame = shadesRect;
            _shades.hidden = NO;
        } else {
            _shades.hidden = YES;
        }
    }
}

@end
