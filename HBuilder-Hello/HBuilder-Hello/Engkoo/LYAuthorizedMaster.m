//
//  LYAuthorizedMaster.m
//  HBuilder
//
//  Created by YongMa on 2020/3/24.
//  Copyright © 2020 DCloud. All rights reserved.
//

#import "LYAuthorizedMaster.h"
#import <AVFoundation/AVFoundation.h>       //摄像头麦克风 必须
#import <AssetsLibrary/AssetsLibrary.h>     //相册权限
#import <Photos/Photos.h>                   //相册权限
#import <CoreLocation/CoreLocation.h>       //位置权限
#import <AddressBook/AddressBook.h>         //通讯录权限

#import "AppDelegate.h"

#define kAPPName [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]

@implementation LYAuthorizedMaster

#pragma mark -
+(BOOL)checkAuthority:(AVAuthorizationStatus)_status{
    return (_status == AVAuthorizationStatusAuthorized) || (_status == AVAuthorizationStatusNotDetermined);
}
+(void)showAlertController:(AuthorizedFinishBlock)_block device:(NSString *)_device{
    if (@available(iOS 8,*)) {
        UIAlertController *_alertC = [UIAlertController alertControllerWithTitle:@"没有权限" message:[NSString stringWithFormat:@"请开启‘%@’对 %@ 的使用权限",kAPPName,_device] preferredStyle:UIAlertControllerStyleAlert];
        [_alertC addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [_alertC addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (UIApplicationOpenSettingsURLString != NULL)
            {
                NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                
                if (@available(iOS 10,*)) {
                    [[UIApplication sharedApplication]openURL:appSettings options:@{} completionHandler:^(BOOL success) {
                    }];
                }
                else
                {
                    [[UIApplication sharedApplication]openURL:appSettings];
                }
            }
        }]];
        
        [[self currentTopViewController] presentViewController:_alertC animated:YES completion:_block];
    }
}

+ (UIViewController*)currentTopViewController
{
    UIViewController *currentViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    while ([currentViewController presentedViewController])    currentViewController = [currentViewController presentedViewController];
    
    if ([currentViewController isKindOfClass:[UITabBarController class]]
        && ((UITabBarController*)currentViewController).selectedViewController != nil )
    {
        currentViewController = ((UITabBarController*)currentViewController).selectedViewController;
    }
    
    while ([currentViewController isKindOfClass:[UINavigationController class]]
           && [(UINavigationController*)currentViewController topViewController])
    {
        currentViewController = [(UINavigationController*)currentViewController topViewController];
    }
    
    return currentViewController;
}

#pragma mark - 摄像头权限
+(BOOL)checkCameraAuthority{
    
    if ([AVCaptureDevice respondsToSelector:@selector(authorizationStatusForMediaType:)]) {
        return [self checkAuthority:[AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]];
    }
    return false;
}
+(void)cameraAuthorityCheckSuccess:(AuthorizedFinishBlock)_success fail:(AuthorizedFinishBlock)_fail;{
    
    if ([AVCaptureDevice respondsToSelector:@selector(authorizationStatusForMediaType:)]) {
        AVAuthorizationStatus permission =[AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        switch (permission) {
            case AVAuthorizationStatusAuthorized:
                if (_success) {
                    _success();
                }
                break;
            case AVAuthorizationStatusDenied:
            case AVAuthorizationStatusRestricted:
                [self showAlertController:_fail device:@"相机"];
                break;
            case AVAuthorizationStatusNotDetermined:
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (_success) {
                        _success();
                    }
                }];
                break;
        }
    }else{
        if (_success) {
            _success();
        }
    }
}

#pragma mark - 麦克风权限
/**
 permission status
 0 ：AVAudioSessionRecordPermissionUndetermined
 1 ：AVAudioSessionRecordPermissionDenied
 2 ：AVAudioSessionRecordPermissionGranted
 @return status
 */
+ (NSInteger)authorizationStatus
{
    if ( @available(iOS 8,*) ){
        return [[AVAudioSession sharedInstance] recordPermission];
    }
    else if (@available(iOS 7,*))
    {
        bool hasBeenAsked =
        [[NSUserDefaults standardUserDefaults] boolForKey:@"HasBeenAskedForMicrophonePermission"];
        if (hasBeenAsked) {
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            __block BOOL hasAccess;
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                hasAccess = granted;
                dispatch_semaphore_signal(sema);
            }];
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            
            return hasAccess ? 2 : 1;
        } else {
            return 0;
        }
    }
    else
        return 2;
}
+(BOOL)checkAudioAuthority{
    return [self checkAuthority:[AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio]];
}
+(void)audioAuthorityCheckSuccess:(AuthorizedFinishBlock)_success fail:(AuthorizedFinishBlock)_fail{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    if (@available(iOS 8.0, *)) {
        
        AVAudioSessionRecordPermission permission = [audioSession recordPermission];
        switch (permission) {
            case AVAudioSessionRecordPermissionGranted:
                if (_success) {
                    _success();
                }
                break;
            case AVAudioSessionRecordPermissionDenied:
                [self showAlertController:_fail device:@"麦克风"];
                break;
            case AVAudioSessionRecordPermissionUndetermined:
            {
                AVAudioSession *session = [[AVAudioSession alloc] init];
                NSError *error;
                [session setCategory:@"AVAudioSessionCategoryPlayAndRecord" error:&error];
                [session requestRecordPermission:^(BOOL granted) {
                    if (_success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            _success();
                        });
                    }
                }];
            }
                break;
            default:
                [self showAlertController:_fail device:@"麦克风"];
                break;
        }
    }
    else if([audioSession respondsToSelector:@selector(requestRecordPermission:)])
    {
        [audioSession requestRecordPermission:^(BOOL granted) {
            
            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
            
            if (_success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(granted){
                        _success();
                    }
                });
            }
            
            [ud setBool:YES forKey:@"AVAudioSessionCategoryPlayAndRecord"];
            [ud synchronize];
        }];
    }
    else
    {
        if (_success) {
            _success();
        }
    }
}

#pragma mark - 相册权限
+(BOOL)checkAlbumAuthority{
    
    if (@available(iOS 8,*))
    {
        return  [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized;
    }
    else
    {
        return  [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized;;
    }
}
+(void)albumAuthorityCheckSuccess:(AuthorizedFinishBlock)_success fail:(AuthorizedFinishBlock)_fail;
{
    if (@available(iOS 8.0, *)) {
        
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        
        switch (status) {
            case PHAuthorizationStatusAuthorized:
                if (_success) {
                    _success();
                }
                break;
            case PHAuthorizationStatusRestricted:
            case PHAuthorizationStatusDenied:
                [self showAlertController:_fail device:@"照片"];
                break;
            case PHAuthorizationStatusNotDetermined:
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    if (_success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(status == PHAuthorizationStatusAuthorized)
                            {
                                _success();
                            }
                        });
                    }
                }];
                break;
        }
    }else{
        
        ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
        switch (status) {
            case ALAuthorizationStatusAuthorized:
                if (_success) {
                    _success();
                }
                break;
            case ALAuthorizationStatusNotDetermined:
            {
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                
                [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *assetGroup, BOOL *stop) {
                    if (*stop) {
                        if (_success) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                _success( );
                            });
                        }
                    } else {
                        *stop = YES;
                    }
                } failureBlock:^(NSError *error) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showAlertController:_fail device:@"照片"];
                    });
                    
                }];
            }
                break;
            case ALAuthorizationStatusRestricted:
            case ALAuthorizationStatusDenied:
                [self showAlertController:_fail device:@"照片"];
                break;
        }
    }
}

@end
