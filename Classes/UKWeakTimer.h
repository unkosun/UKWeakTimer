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

#import <Foundation/Foundation.h>

/**
 *  Weak target timer, when the target is deallocated, the timer don't fire and invalidate itself automatically
 *  Unlike NSTimer, you should keep a strong reference to WTTimer because we invalidate the timer in its dealloc method
 */
@interface UKWeakTimer : NSObject

+ (UKWeakTimer *)timerWithTimeInterval:(NSTimeInterval)ti
                            invocation:(NSInvocation *)invocation
                               repeats:(BOOL)yesOrNo;

+ (UKWeakTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti
                                     invocation:(NSInvocation *)invocation
                                        repeats:(BOOL)yesOrNo;

+ (UKWeakTimer *)timerWithTimeInterval:(NSTimeInterval)ti
                                target:(id)aTarget
                              selector:(SEL)aSelector
                              userInfo:(id)userInfo
                               repeats:(BOOL)yesOrNo;

+ (UKWeakTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti
                                         target:(id)aTarget
                                       selector:(SEL)aSelector
                                       userInfo:(id)userInfo
                                        repeats:(BOOL)yesOrNo;



- (void)fire;

@property (copy) NSDate *fireDate;
@property (readonly) NSTimeInterval timeInterval;

- (void)invalidate;

@property (readonly, getter=isValid) BOOL valid;

@property (readonly, retain) id userInfo;

/**
 *  extension:
 *
 */
-(void)scheduleRunLoop:(NSRunLoop *)loop forMode:(NSString *)mode;

@end
