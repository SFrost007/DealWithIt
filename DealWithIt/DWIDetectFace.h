//
//  DWIDetectFace.h
//  DealWithIt
//
//  Created by Simon Frost on 03/04/2013.
//  Copyright (c) 2013 Orangeninja. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>


@class DWIDetectFace;

@protocol DWIDetectFaceDelegate <NSObject>

- (void) detectedFaceController:(DWIDetectFace*)controller
                       features:(NSArray*)features
                    forVideoBox:(CGRect)clap
                 withPreviewBox:(CGRect)previewBox;
@end





@interface DWIDetectFace : NSObject

@property (nonatomic, weak) id<DWIDetectFaceDelegate> delegate;
@property (nonatomic, strong) UIView *previewView;

- (void) startDetection;
- (void) stopDetection;

+ (CGRect) convertFrame:(CGRect)originalFrame
             previewBox:(CGRect)previewBox
            forVideoBox:(CGRect)videoBox
             isMirrored:(BOOL)isMirrored;

@end
