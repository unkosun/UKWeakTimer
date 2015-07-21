// The MIT License (MIT)
//
// Created by unko ( https://github.com/unkosun ) on 15/7/15.
// Copyright (c) 2015  www.unko.cn. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "UKWeakTimer.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


@class TimerDelegateObject ;

@protocol UKWeakTimerDelegate <NSObject>

- (void)weakTimerFired:(TimerDelegateObject *)obj ;

@end

@interface TimerDelegateObject : NSObject

@property (nonatomic, weak) id<UKWeakTimerDelegate> delegate ;

- (void)timerFired:(NSTimer *)timer ;

@end

@implementation TimerDelegateObject

- (void)dealloc
{
#ifdef DEBUG
    NSLog(@"%@ %@", self, NSStringFromSelector(_cmd)) ;
#endif
}

- (void)timerFired:(NSTimer *)timer
{
    [_delegate weakTimerFired:self] ;
}

@end

@interface UKWeakTimer () <UKWeakTimerDelegate>

@property (nonatomic, strong) NSTimer *timer ;

// target and selector
@property (nonatomic, weak) id weakTarget ;
@property (nonatomic) SEL selector ;
@property (nonatomic,assign) BOOL isScheduled;


// for NSInvocation
@property (nonatomic, strong) NSInvocation *invocation ;

@end

@implementation UKWeakTimer

- (instancetype)initWithFireDate:(NSDate *)date
                        interval:(NSTimeInterval)seconds
                          target:(id)target
                        selector:(SEL)aSelector
                        userInfo:(id)userInfo
                         repeats:(BOOL)repeats
{
    self = [super init] ;
    if (self) {
        _timer = [[NSTimer alloc] initWithFireDate:date interval:seconds target:target selector:aSelector userInfo:userInfo repeats:repeats] ;
        _isScheduled = NO;
    }
    return self ;
}

- (void)dealloc
{
    _invocation = nil;
#ifdef DEBUG
    NSLog(@"%@ %@", self, NSStringFromSelector(_cmd)) ;
#endif
    if ([_timer isValid]) {
        [_timer invalidate];
    }
}


 #pragma mark - Create with NSInvocation
+ (UKWeakTimer *)timerWithTimeInterval:(NSTimeInterval)ti invocation:(NSInvocation *)invocation repeats:(BOOL)yesOrNo {
    TimerDelegateObject *delegateObj = [[TimerDelegateObject alloc] init] ;
 
    NSDate *dateFire = [NSDate dateWithTimeIntervalSinceNow:ti] ;
    UKWeakTimer *timer = [[UKWeakTimer alloc] initWithFireDate:dateFire
                                                      interval:ti
                                                        target:delegateObj
                                                      selector:@selector(timerFired:)
                                                      userInfo:nil
                                                       repeats:yesOrNo] ;
    delegateObj.delegate = timer ;
 
    timer.weakTarget = invocation.target ;
    [invocation setTarget:delegateObj];
    [invocation retainArguments] ;
    timer.invocation = invocation ;
    return timer ;
 }

+ (UKWeakTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti invocation:(NSInvocation *)invocation repeats:(BOOL)yesOrNo {
    UKWeakTimer *timer = [UKWeakTimer timerWithTimeInterval:ti invocation:invocation repeats:yesOrNo] ;
    [timer scheduleRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    return timer ;
}

#pragma mark - Create with target and selector

+ (UKWeakTimer *)timerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo
{
    TimerDelegateObject *obj = [[TimerDelegateObject alloc] init] ;
    
    NSDate *dateFire = [NSDate dateWithTimeIntervalSinceNow:ti] ;
    UKWeakTimer *timer = [[UKWeakTimer alloc] initWithFireDate:dateFire
                                              interval:ti
                                                target:obj
                                              selector:@selector(timerFired:)
                                              userInfo:userInfo
                                               repeats:yesOrNo] ;
    obj.delegate = timer ;
    // config UKWeakTimer
    timer.selector = aSelector ;
    timer.weakTarget = aTarget ;
    return timer ;
}

+ (UKWeakTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo
{
    UKWeakTimer *timer = [self timerWithTimeInterval:ti
                                          target:aTarget
                                        selector:aSelector
                                        userInfo:userInfo
                                         repeats:yesOrNo] ;
    [timer scheduleRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    return timer ;
}

#pragma mark - common function

- (void)weakTimerFired:(TimerDelegateObject *)obj
{
    if (_weakTarget) {
        if (_invocation) {
            NSInvocation * copy = [self copyInvocation:_invocation];
            [copy setTarget:_weakTarget];
            [copy invoke];
            copy = nil;
        }else
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [_weakTarget performSelector:_selector withObject:self] ;
#pragma clang diagnostic pop
        }

    } else {
        // the target is deallocated, the timer should be invalidated
        [self.timer invalidate] ;
#ifdef DEBUG
        NSLog(@"the target is deallocated, invalidate the timer") ;
#endif
    }
}


-(NSInvocation *)copyInvocation:(NSInvocation *)sourceInvocation {
    NSMethodSignature * sig = [sourceInvocation methodSignature];
    NSInvocation * copy = [NSInvocation invocationWithMethodSignature:sig];
    [copy setSelector:sourceInvocation.selector];
    NSUInteger numArgs = [sig numberOfArguments];
    if (numArgs > 2) {
        for (int i = 2; i < numArgs; ++i) {
            __unsafe_unretained id pointer;
            [sourceInvocation getArgument:&pointer atIndex:i];
            [copy setArgument:&pointer atIndex:i];
        }
    }
    return copy;
}

#pragma mark - extension

-(void)scheduleRunLoop:(NSRunLoop *)loop forMode:(NSString *)mode {
    NSString * loopMode = mode;
    if (!loopMode || [loopMode isKindOfClass:[NSNull class]] || [loopMode isEqualToString:@""]) {
        loopMode = NSDefaultRunLoopMode;
    }
    if ( loop && _timer && !_isScheduled) {
        [loop addTimer:_timer forMode:loopMode];
        _isScheduled = YES;
    }
}

#pragma mark - override NSTimer

- (NSDate *)fireDate
{
    return [_timer fireDate] ;
}

- (void)setFireDate:(NSDate *)fireDate
{
    _timer.fireDate = fireDate ;
}

- (NSTimeInterval)timeInterval
{
    return [_timer timeInterval] ;
}

- (void)fire
{
    return [_timer fire] ;
}

- (void)invalidate
{
    [_timer invalidate] ;
}

- (BOOL)isValid
{
    return [_timer isValid] ;
}

- (id)userInfo
{
    return _timer.userInfo ;
}


@end
