//
//  CustomViewController.m
//  InitializeVSLoad
//
//  Created by 郝一鹏 on 16/7/30.
//  Copyright © 2016年 bupt. All rights reserved.
//

#import "CustomViewController.h"

@implementation CustomViewController

+ (void)initialize {
    NSLog(@"-------initialize-------%@",NSStringFromClass([self class]));
}

+ (void)load {
    NSLog(@"-------load-------%@",NSStringFromClass([self class]));
}

@end
