//
//  EngkooWebViewFeature.m
//  HBuilder
//
//  Created by 张为涧 on 2019/6/8.
//  Copyright © 2019 DCloud. All rights reserved.
//
#import "EngkooWebViewFeature.h"
#import "EngkooViewController.h"
#import <Foundation/Foundation.h>

@implementation EngkooWebViewFeature

- (void)startEngkooWebView:(PGMethod*)commands{
    
    if(commands){
        NSString* url = [commands.arguments objectAtIndex:1];
        NSString* accessToken = [commands.arguments objectAtIndex:2];
        NSString* title = [commands.arguments objectAtIndex:3];
        
        EngkooViewController *controller = [[EngkooViewController alloc] init];
        controller.modalPresentationStyle = UIModalPresentationFullScreen;
        
        controller.engkooParameter = [[NSMutableDictionary alloc] init];
        [controller.engkooParameter setObject:url forKey:@"englishAssistantScenarioLessonUrl"];
        [controller.engkooParameter setObject:accessToken forKey:@"accessToken"];
        [controller.engkooParameter setObject:title forKey:@"title"];
        
        [self.rootViewController presentViewController:controller animated:YES completion:nil];
    }
}

@end
