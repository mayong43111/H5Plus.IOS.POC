//
//  JimPaymentFeatureImpl.m
//  HBuilder
//
//  Created by 张为涧 on 2019/6/8.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JimPlugin.h"

#import "JimViewController.h"

@implementation JimPlugin

- (void)PluginTestFunction:(PGMethod*)command{
    if(command){
        JimViewController *jimViewController = [[JimViewController alloc] init];
        
        [self.rootViewController presentViewController:jimViewController animated:YES completion:nil];
        
        //正式代码中需要添加回调函数
        /*
        NSString* cbId = [command.arguments objectAtIndex:0];
        NSString* pArgument1 = [command.arguments objectAtIndex:1];
        NSString* pArgument2 = [command.arguments objectAtIndex:2];
        
        NSArray* pResultString = [NSArray arrayWithObjects:pArgument1, pArgument2, nil];
        
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsArray:pResultString];
        
        [self toCallback:cbId withReslut:[result toJSONString]];
        */
    }
}
    
@end
