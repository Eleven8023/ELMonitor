//
//  ELMonitor.m
//  RunLoopMonitor
//
//  Created by Eleven on 2018/11/17.
//  Copyright © 2018 Eleven. All rights reserved.
//

#import "ELMonitor.h"
#import <libkern/OSAtomic.h>
#import <execinfo.h>

@interface ELMonitor () {
    CFRunLoopObserverRef _observer;
    dispatch_semaphore_t _semaphore;
    CFRunLoopActivity _activity;
    NSInteger _countTime;
    NSMutableArray *backTrace;
}

@end

@implementation ELMonitor
+ (instancetype)sharedInstance{
    static ELMonitor *monitor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor = [[super allocWithZone:NULL] init];
    });
    return monitor;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
   return [self sharedInstance];
}

- (void)startMonitor{
    [self registerObserver];
}

- (void)endMonitor{
    if (!_observer) {
        return;
    }
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = NULL;
}

- (void)printLogTrace{
    NSLog(@"stack heap=== 堆栈\n %@ \n", backTrace);
}

static void runloopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    ELMonitor *instace = [ELMonitor sharedInstance];
    instace->_activity = activity;
    dispatch_semaphore_t semaphore = instace->_semaphore;
    dispatch_semaphore_signal(semaphore);
}

- (void)registerObserver{
    CFRunLoopObserverContext context = {0, (__bridge void*)self, NULL, NULL};
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runloopObserverCallBack, &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);

    _semaphore = dispatch_semaphore_create(0);

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (1) {
            // 假定连续5次超市50ms认为卡顿  单次超过250ms
            long st = dispatch_semaphore_wait(self->_semaphore, dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC));
            if (st != 0) {
                if (self->_activity==kCFRunLoopBeforeSources || self->_activity==kCFRunLoopAfterWaiting)
                {
                    if (++self->_countTime < 5)
                        continue;
                    [self logStack];
                    NSLog(@"something lag");
                }
            }
            self->_countTime = 0;
        }
    });
}

- (void)logStack{
    void* callstack[128];
    int frame = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frame);
    backTrace = [NSMutableArray arrayWithCapacity:frame];
    for (int i = 0; i < frame; i++) {
        [backTrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
}

@end




