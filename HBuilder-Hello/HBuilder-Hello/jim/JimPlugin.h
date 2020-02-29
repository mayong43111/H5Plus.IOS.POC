//
//  JimFeatureImpl.h
//  HBuilder-Hello
//
//  Created by 张为涧 on 2019/6/8.
//  Copyright © 2019 DCloud. All rights reserved.
//

#ifndef JimFeatureImpl_h
#define JimFeatureImpl_h

#include "PGPlugin.h"
#include "PGMethod.h"
#import <Foundation/Foundation.h>

@interface JimPlugin : PGPlugin
    
    - (void)PluginTestFunction:(PGMethod*)command;
    
@end


#endif /* JimFeatureImpl_h */


