//
//  EngkooViewController.h
//  EngkooViewController
//
//  Created by SunXP on 17/4/28.
//  Copyright © 2017年 L. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface EngkooViewController : UIViewController<WKNavigationDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (strong,nonatomic) NSMutableDictionary* engkooParameter;

@end
