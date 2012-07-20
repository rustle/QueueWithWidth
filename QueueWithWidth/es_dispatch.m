//
//  es_dispatch.m
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

#import "es_dispatch.h"
#import <objc/runtime.h>

static const void * sync_queue_key = &sync_queue_key;
static const void * semaphore_key = &semaphore_key;
static const void * group_key = &group_key;

dispatch_queue_t es_queue_create(const char *label, long width)
{
	dispatch_queue_t queue = dispatch_queue_create(label, DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t syncQueue = dispatch_queue_create("", DISPATCH_QUEUE_SERIAL);
    objc_setAssociatedObject(queue, sync_queue_key, syncQueue, OBJC_ASSOCIATION_RETAIN);
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(width);
	objc_setAssociatedObject(queue, semaphore_key, semaphore, OBJC_ASSOCIATION_RETAIN);
    dispatch_group_t group = dispatch_group_create();
    objc_setAssociatedObject(queue, group_key, group, OBJC_ASSOCIATION_RETAIN);
	return queue;
}

void es_async(dispatch_queue_t queue, dispatch_block_t block)
{
	dispatch_queue_t syncQueue = objc_getAssociatedObject(queue, sync_queue_key);
	dispatch_semaphore_t semaphore = objc_getAssociatedObject(queue, semaphore_key);
	dispatch_group_t group = objc_getAssociatedObject(queue, group_key);
	if (semaphore && syncQueue && group)
    {
		dispatch_group_enter(group);
        dispatch_async(syncQueue, ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            dispatch_async(queue, ^ {
                block();
                dispatch_semaphore_signal(semaphore);
                dispatch_group_leave(group);
            });
        });
    }
    else
    {
        dispatch_async(queue, block);
    }
}

long es_queue_wait(dispatch_queue_t queue, dispatch_time_t timeout)
{
	dispatch_group_t group = objc_getAssociatedObject(queue, group_key);
	if (group) return dispatch_group_wait(group, timeout);
	return 0;
}

void es_queue_notify(dispatch_queue_t queue, dispatch_block_t block)
{
	dispatch_group_t group = objc_getAssociatedObject(queue, group_key);
	if (group) return dispatch_group_notify(group, queue, block);
}

// Rough idea of how I would implement the real API

// Assumes there's a dispatch_semapahore_t dsem member variable
// on the dispatch_queue_t struct

void
dispatch_set_queue_width(dispatch_queue_t queue, long width)
{
	// clear existing semaphore on queue
	dispatch_semaphore_t dsem;
	dsem = dispatch_semaphore_create(width);
	// associate it with queue
}

long
dispatch_queue_wait(dispatch_queue_t queue, dispatch_time_t timeout)
{
	dispatch_semaphore_t dsem; // get dsem off queue
	return dispatch_semaphore_wait(dsem, timeout);
}

void
dispatch_queue_notify(dispatch_queue_t queue,
					  dispatch_block_t block)
{
	dispatch_semaphore_t dsem; // get dsem off queue
	dispatch_semaphore_notify(dsem, block);
}

void
dispatch_semaphore_notify(dispatch_semaphore_t semaphore,
						  dispatch_block_t block)
{
	// Same basic implementation as
	// dispatch_group_notify
	// but instead of value==origvalue
	// use value >= 0
	// dispatch_semaphore_signal() would need to
	// consider to consider these notify blocks
	// in the same way it considers semaphores
	// waiting in dispatch_semaphore_wait()
}

void
dispatch_async(dispatch_queue_t queue, dispatch_block_t block)
{
	/*
	 Normal dispatch_async for serial and concurrent queues
	 */
	// If DISPATCH_QUEUE_CONCURRENT_WITH_WIDTH
	dispatch_semaphore_t dsem; // get dsem off queue
	dispatch_semaphore_notify(dsem, ^{
		dispatch_async(queue, block);
	});
}
