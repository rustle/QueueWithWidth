//
//  dispatch_proposal.m
//  QueueWithWidth
//
//  Created by Doug Russell on 9/4/12.
//  Copyright (c) 2012 BPXL. All rights reserved.
//

#import "dispatch.h"

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
