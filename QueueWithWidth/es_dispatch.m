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
#import "ARCLogic.h"

static const void * es_queue_context_key = "es_queue_context_key";

@interface ESQueueContext : NSObject

- (instancetype)initWithWidth:(long)width;
- (dispatch_queue_t)syncQueue;
- (dispatch_semaphore_t)semaphore;
- (dispatch_group_t)group;

@end

static void es_queue_finalizer(void *context)
{
	CFRelease((CFTypeRef)context);
}

static ESQueueContext * es_lookup_context(dispatch_queue_t queue)
{
	ESQueueContext *context;
	IF_ARC(
		   context = (__bridge ESQueueContext *)dispatch_queue_get_specific(queue, es_queue_context_key);
		   ,
		   context = (ESQueueContext *)dispatch_queue_get_specific(queue, es_queue_context_key);
		   )
	return context;
}

dispatch_queue_t es_queue_create(const char *label, long width)
{
	if (width <= 0)
	{
		NSLog(@"Attempted to create a dispatch queue with a width of zero or less");
		return NULL;
	}
	dispatch_queue_t queue = dispatch_queue_create(label, DISPATCH_QUEUE_CONCURRENT);
	ESQueueContext *context = [[ESQueueContext alloc] initWithWidth:width];
	void * contextRef;
	IF_ARC(
		   contextRef = (void *)CFBridgingRetain(context);
		   ,
		   contextRef = (void *)context;
		   )
	dispatch_queue_set_specific(queue, es_queue_context_key, contextRef, &es_queue_finalizer);
	return queue;
}

#define _es_dispatch_func_preflight \
if (queue == NULL) \
{ \
NSLog(@"Attempted to schedule a block on a NULL queue"); \
return; \
} \
if (block == NULL) \
{ \
NSLog(@"Attempted to schedule a NULL block"); \
return; \
}

void _es_dispatch_async_func(dispatch_queue_t queue, dispatch_block_t block, void (*async_func)(dispatch_queue_t queue, dispatch_block_t block))
{
	_es_dispatch_func_preflight
	ESQueueContext *context = es_lookup_context(queue);
	dispatch_queue_t syncQueue = context.syncQueue;
	dispatch_semaphore_t semaphore = context.semaphore;
	dispatch_group_t group = context.group;
	if (semaphore && syncQueue && group)
    {
		dispatch_group_enter(group);
        dispatch_async(syncQueue, ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            async_func(queue, ^ {
                block();
                dispatch_semaphore_signal(semaphore);
                dispatch_group_leave(group);
            });
        });
    }
    else
    {
        async_func(queue, block);
    }
}

void _es_dispatch_sync_func(dispatch_queue_t queue, dispatch_block_t block, void (*sync_func)(dispatch_queue_t queue, dispatch_block_t block))
{
	_es_dispatch_func_preflight
	ESQueueContext *context = es_lookup_context(queue);
	dispatch_semaphore_t semaphore = context.semaphore;
	dispatch_group_t group = context.group;
	if (semaphore && group)
    {
		dispatch_group_enter(group);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
		sync_func(queue, ^ {
			block();
			dispatch_semaphore_signal(semaphore);
			dispatch_group_leave(group);
		});
    }
    else
    {
        sync_func(queue, block);
    }
}

void es_async(dispatch_queue_t queue, dispatch_block_t block)
{
	_es_dispatch_async_func(queue, block, &dispatch_async);
}

void es_sync(dispatch_queue_t queue, dispatch_block_t block)
{
	_es_dispatch_sync_func(queue, block, &dispatch_sync);
}

void es_barrier_async(dispatch_queue_t queue, dispatch_block_t block)
{
	_es_dispatch_async_func(queue, block, &dispatch_barrier_async);
}

void es_barrier_sync(dispatch_queue_t queue, dispatch_block_t block)
{
	_es_dispatch_sync_func(queue, block, &dispatch_barrier_sync);
}

long es_queue_wait(dispatch_queue_t queue, dispatch_time_t timeout)
{
	if (queue == NULL)
	{
		NSLog(@"Attempted to wait on a NULL queue");
		return 0;
	}
	ESQueueContext *context = es_lookup_context(queue);
	dispatch_group_t group = context.group;
	if (group) return dispatch_group_wait(group, timeout);
	return 0;
}

void es_queue_notify(dispatch_queue_t queue, dispatch_block_t block)
{
	if (queue == NULL)
	{
		NSLog(@"Attempted to schedule a notify block on a NULL queue");
		return;
	}
	if (block == NULL)
	{
		NSLog(@"Attempted to schedule a NULL notify block");
		return;
	}
	ESQueueContext *context = es_lookup_context(queue);
	dispatch_group_t group = context.group;
	if (group) return dispatch_group_notify(group, queue, block);
}

@implementation ESQueueContext
{
	dispatch_queue_t _syncQueue;
	dispatch_semaphore_t _semaphore;
	dispatch_group_t _group;
}

- (instancetype)initWithWidth:(long)width
{
	self = [super init];
	if (self)
	{
		_syncQueue = dispatch_queue_create("", DISPATCH_QUEUE_SERIAL);
		_semaphore = dispatch_semaphore_create(width);
		_group = dispatch_group_create();
	}
	return self;
}

- (dispatch_queue_t)syncQueue { return _syncQueue; }

- (dispatch_semaphore_t)semaphore { return _semaphore; }

- (dispatch_group_t)group { return _group; }

- (void)dealloc
{
	es_dispatch_release(_syncQueue);
	es_dispatch_release(_semaphore);
	es_dispatch_release(_group);
	NO_ARC([super dealloc];)
}

@end
