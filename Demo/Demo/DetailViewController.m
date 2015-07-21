//
//  DetailViewController.m
//  Demo
//
//  Created by unkosun on 15/7/21.
//  Copyright (c) 2015年 unko. All rights reserved.
//

#import "DetailViewController.h"
#import "UKWeakTimer.h"


@interface DetailViewController ()
@property (nonatomic,strong) UKWeakTimer * timer;
@end

@implementation DetailViewController

- (IBAction)fireButtonPressed:(id)sender {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    // scheduled
    
//    self.timer = [UKWeakTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(onTimer:) userInfo:@"FireTest" repeats:YES];
    
    // NSInvocation
    
    SEL sel = @selector(invokeMethod);
    NSMethodSignature * sig = [[self class] instanceMethodSignatureForSelector:sel];
    NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:self];
    [invocation setSelector:sel];
    self.timer = [UKWeakTimer scheduledTimerWithTimeInterval:2.0f invocation:invocation repeats:YES];
    
    //
    [self.timer fire];
}

- (IBAction)invalidateButtonPressed:(id)sender {
    [_timer invalidate];
}

-(void)dealloc {
//    [_timer invalidate];
    NSLog(@"%@ dealloc", NSStringFromClass([self class]));
}

-(void)onTimer:(id)sender{
    if ([sender isKindOfClass:[UKWeakTimer class]]) {
        UKWeakTimer * timer = (UKWeakTimer *)sender;
        NSLog(@"%@", timer.userInfo);
    }
}

-(void)invokeMethod {
    NSLog(@"Fire Test");
}

@end
