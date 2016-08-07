//
//  CustomViewController+Test.m
//  InitializeVSLoad
//
//  Created by 郝一鹏 on 16/7/30.
//  Copyright © 2016年 bupt. All rights reserved.
//

#import "CustomViewController+Test.h"

@implementation CustomViewController (Test)

+ (void)load {
    NSLog(@"-------load：Test-------%@",NSStringFromClass([self class]));
}

@end
