/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller for camera interface.
*/

@import UIKit;
#import <CoreMotion/CoreMotion.h>

@interface AVCamManualCameraViewController : UIViewController {
    CMMotionManager *motionManager;

}
@property (nonatomic, strong) CMMotionManager *motionManager;

@end
