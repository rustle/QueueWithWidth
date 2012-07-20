//
//  es_dispatch.h
//  QueueWithWidth
//
//  Created by Doug Russell on 7/18/12.
//  Copyright (c) 2012 Doug Russell. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>

// creates a queue that can be used with the other es_ dispatch api
extern dispatch_queue_t es_queue_create(const char *label, long width);
// Same as dispatch_async, but respects the queues width
extern void es_async(dispatch_queue_t queue, dispatch_block_t block);
// Same as dispatch_group_wait
extern long es_queue_wait(dispatch_queue_t queue, dispatch_time_t timeout);
// Same as dispatch_group_notify
extern void es_queue_notify(dispatch_queue_t queue, dispatch_block_t block);

// My idea of what a real api for this would look like

// dispatch_queue_attr_t
// Used by dispatch_queue_create() to create a
// queue with a concept of width
#define DISPATCH_QUEUE_CONCURRENT_WITH_WIDTH

#define DISPATCH_QUEUE_CONCURRENT_WITH_WIDTH_DEFAULT_WIDTH /*Processor Count*/

// Set queues width (internally this creates a semaphore
// with given width and attaches it to the queue)
__OSX_AVAILABLE_STARTING(__MAC_10_8,__IPHONE_6_0)
DISPATCH_EXPORT DISPATCH_NOTHROW
void
dispatch_set_queue_width(dispatch_queue_t queue, long width);

// Only accepts DISPATCH_QUEUE_CONCURRENT_WITH_WIDTH queues
// and waits with the same behavior as dispatch_semaphore_wait()
__OSX_AVAILABLE_STARTING(__MAC_10_6,__IPHONE_4_0)
DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
long
dispatch_queue_wait(dispatch_queue_t queue, dispatch_time_t timeout);

// Only accepts DISPATCH_QUEUE_CONCURRENT_WITH_WIDTH queues
// and notifies with the same behavior as dispatch_group_notify(),
// but instead of waiting for it's group to reach
// value==originalvalue for it's value to become non-negative
#ifdef __BLOCKS__
__OSX_AVAILABLE_STARTING(__MAC_10_6,__IPHONE_4_0)
DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
void
dispatch_queue_notify(dispatch_queue_t queue,
					  dispatch_block_t block);
#endif /* __BLOCKS__ */

// Notifies with the same behavior as dispatch_group_notify(),
// but instead of waiting for it's group to reach
// value==originalvalue for it's value to become non-negative
// Should queue with the same ordering as dispatch_semaphore_wait()
// i.e. if you called wait then notify then wait, they'd signal in
// that order
#ifdef __BLOCKS__
__OSX_AVAILABLE_STARTING(__MAC_10_6,__IPHONE_4_0)
DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
void
dispatch_semaphore_notify(dispatch_semaphore_t semaphore,
						  dispatch_block_t block);
#endif /* __BLOCKS__ */

