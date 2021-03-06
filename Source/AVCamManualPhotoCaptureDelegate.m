/*

	Abstract:
	Photo capture delegate.
*/

#import "AVCamManualPhotoCaptureDelegate.h"

@import Photos;
#import <SimpleExif/ExifContainer.h>
#import <SimpleExif/UIImage+Exif.h>

#import <Parse/Parse.h>
@interface AVCamManualPhotoCaptureDelegate ()

@property (nonatomic, readwrite) AVCapturePhotoSettings *requestedPhotoSettings;
@property (nonatomic) void (^willCapturePhotoAnimation)(void);
@property (nonatomic) void (^completed)(AVCamManualPhotoCaptureDelegate *photoCaptureDelegate);

@property (nonatomic) NSData *jpegPhotoData;
@property (nonatomic) NSData *dngPhotoData;

@end

@implementation AVCamManualPhotoCaptureDelegate

- (instancetype)initWithRequestedPhotoSettings:(AVCapturePhotoSettings *)requestedPhotoSettings willCapturePhotoAnimation:(void (^)(void))willCapturePhotoAnimation completed:(void (^)(AVCamManualPhotoCaptureDelegate *))completed
{
	self = [super init];
	if ( self ) {
		self.requestedPhotoSettings = requestedPhotoSettings;
		self.willCapturePhotoAnimation = willCapturePhotoAnimation;
		self.completed = completed;
	}
	return self;
}

- (void)didFinish
{
	self.completed( self );
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
{
	self.willCapturePhotoAnimation();
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error
{
	if ( error != nil ) {
		NSLog( @"Error capturing photo: %@", error );
		return;
	}
	
	self.jpegPhotoData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingRawPhotoSampleBuffer:(CMSampleBufferRef)rawSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error
{
	if ( error != nil ) {
		NSLog( @"Error capturing RAW photo: %@", error );
		return;
	}
	
	self.dngPhotoData = [AVCapturePhotoOutput DNGPhotoDataRepresentationForRawSampleBuffer:rawSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error
{
	if ( error != nil ) {
		NSLog( @"Error capturing photo: %@", error );
		[self didFinish];
		return;
	}
	
	if ( self.jpegPhotoData == nil && self.dngPhotoData == nil ) {
		NSLog( @"No photo data resource" );
		[self didFinish];
		return;
	}
	
	[PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
		if ( status == PHAuthorizationStatusAuthorized ) {
			NSURL *temporaryDNGFileURL;
			if ( self.dngPhotoData ) {
                // write filename_gps_with
                NSDate *currDate = [NSDate date];
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                [dateFormatter setDateFormat:@"ddMMYYHHmmss"];
                
                
				temporaryDNGFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%lld.dng", resolvedSettings.uniqueID]]];
                NSLog ([NSString stringWithFormat:@"%lld.dng", resolvedSettings.uniqueID]);
				[self.dngPhotoData writeToURL:temporaryDNGFileURL atomically:YES];
                
                
                int unixtime = [[NSNumber numberWithDouble: [[NSDate date] timeIntervalSince1970]] integerValue];
                
                NSString *iSpexImageName = [NSString stringWithFormat:@"%d.dng",unixtime];
                
                PFFileObject *imageFile = [PFFileObject fileObjectWithName: iSpexImageName data:self. dngPhotoData];
  
                
                
                
                // DEBUG
                PFObject *iSPEXMeasurement = [PFObject objectWithClassName:@"raw_images"];
                
                
                
                
                
                [iSPEXMeasurement setObject:imageFile forKey:@"raw_image"];
//                [iSPEXMeasurement setObject:@"TEST" forKey:@"product"];
                [iSPEXMeasurement save];
                iSPEXMeasurement=NULL;
                
                
                
                
//                [imageFile saveInBackground];

                
                // send it to parse (test)
                
                
                
                
                // UIImage *image = [[UIImage alloc] initWithData:self.dngPhotoData];
                
                
                
                
                
                
			}
			
			[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
				PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
				
				if ( self.jpegPhotoData ) {
                    
                    ExifContainer *container = [[ExifContainer alloc] init];
                    
                    
                    [container addUserComment:@"A long time ago, in a galaxy far, far away"];
                    [container addCreationDate:[NSDate dateWithTimeIntervalSinceNow:-10000000]];
                    
					[creationRequest addResourceWithType:PHAssetResourceTypePhoto data:self.jpegPhotoData options:nil];
					
                    
                    
                    
					if ( temporaryDNGFileURL ) {
						PHAssetResourceCreationOptions *companionDNGResourceOptions = [[PHAssetResourceCreationOptions alloc] init];
						companionDNGResourceOptions.shouldMoveFile = YES;
						[creationRequest addResourceWithType:PHAssetResourceTypeAlternatePhoto fileURL:temporaryDNGFileURL options:companionDNGResourceOptions];
					}
				}
				else {
					PHAssetResourceCreationOptions *dngResourceOptions = [[PHAssetResourceCreationOptions alloc] init];
					dngResourceOptions.shouldMoveFile = YES;
					[creationRequest addResourceWithType:PHAssetResourceTypePhoto fileURL:temporaryDNGFileURL options:dngResourceOptions];
				}
				
			} completionHandler:^( BOOL success, NSError * _Nullable error ) {
				if ( ! success ) {
					NSLog( @"Error occurred while saving photo to photo library: %@", error );
				}
				
				if ( [[NSFileManager defaultManager] fileExistsAtPath:temporaryDNGFileURL.path] ) {
					[[NSFileManager defaultManager] removeItemAtURL:temporaryDNGFileURL error:nil];
				}
				
				[self didFinish];
			}];
		}
		else {
			NSLog( @"Not authorized to save photo" );
			[self didFinish];
		}
	}];
}

@end
