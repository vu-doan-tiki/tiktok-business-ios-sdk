//
//  TikTokAppEventQueue.m
//  TikTokBusinessSDK
//
//  Created by Christopher Yang on 9/4/20.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "TikTokAppEvent.h"
#import "TikTokAppEventQueue.h"
#import "TikTokAppEventStore.h"
#import "TikTokAppEventUtility.h"

#define EVENT_NUMBER_THRESHOLD 100
#define FLUSH_PERIOD_IN_SECONDS 15

@implementation TikTokAppEventQueue

- (id)init {
    if (self == nil) return nil;
    self.eventQueue = [NSMutableArray array];
    
    __weak TikTokAppEventQueue *weakSelf = self;
    self.flushTimer = [TikTokAppEventUtility startTimerWithInterval:FLUSH_PERIOD_IN_SECONDS
                                                        block:^{
        [weakSelf flush:TikTokAppEventsFlushReasonTimer];
    }];
    
    return self;
}

- (void)addEvent:(TikTokAppEvent *)event {
    [self.eventQueue addObject:event];
    if(self.eventQueue.count > EVENT_NUMBER_THRESHOLD) {
        [self flush:TikTokAppEventsFlushReasonEventThreshold];
    }
}

- (void)flush:(TikTokAppEventsFlushReason)flushReason {
    NSLog(@"Start flush, with flush reason: %lu current queue count: %lu", flushReason, self.eventQueue.count);
    NSArray *eventsFromDisk = [TikTokAppEventStore retrievePersistedAppEvents];
    NSLog(@"Number events from disk: %lu", eventsFromDisk.count);
    NSMutableArray *eventsToBeFlushed = [NSMutableArray arrayWithArray:self.eventQueue];
    [eventsToBeFlushed addObjectsFromArray:eventsFromDisk];
    NSLog(@"Total number events to be flushed: %lu", eventsToBeFlushed.count);
    
    for (TikTokAppEvent* event in eventsToBeFlushed) {
        NSLog(@"%@", event.eventName);
    }
    // TODO: If flushing fails, persist app events
    // [TikTokAppEventStore persistAppEvents:self];
    [self.eventQueue removeAllObjects];
    NSLog(@"End flush, current queue count: %lu", self.eventQueue.count);
}

@end
