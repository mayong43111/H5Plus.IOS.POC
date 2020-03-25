//
//  LYAuthorizedMaster.h
//  HBuilder-Hello
//
//  Created by YongMa on 2020/3/24.
//  Copyright © 2020 DCloud. All rights reserved.
//
#import <Foundation/Foundation.h>
typedef void(^AuthorizedFinishBlock)();

@interface LYAuthorizedMaster:NSObject


#pragma mark - 摄像头权限
+(BOOL)checkCameraAuthority;
+(void)cameraAuthorityCheckSuccess:(AuthorizedFinishBlock)_success fail:(AuthorizedFinishBlock)_fail;

#pragma mark - 麦克风权限
+(BOOL)checkAudioAuthority;
+(void)audioAuthorityCheckSuccess:(AuthorizedFinishBlock)_success fail:(AuthorizedFinishBlock)_fail;

#pragma mark - 相册权限
+(BOOL)checkAlbumAuthority;
+(void)albumAuthorityCheckSuccess:(AuthorizedFinishBlock)_success fail:(AuthorizedFinishBlock)_fail;

@end
