//
//  main.m
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
#import "es_dispatch.h"

// The first and second examples demonstrate the same exact logical flow,
// except that the first uses associated objects
// to hide away all the messiness (not that associated objects are the
// cleanest thing)

// Background reading http://www.mikeash.com/pyblog/friday-qa-2009-09-25-gcd-practicum.html

// I'd love to see something like this folded into GCD to make IO bound tasks simpler
// Plus if it was official API, instead of blocking on the semaphore, they could
// do something like a semaphore_notify to delay dispatching the block and avoid
// runaway thread creation.

int main(int argc, const char * argv[])
{
	@autoreleasepool {
#if 1
		
		NSLog(@"Start");
		dispatch_queue_t queue = es_queue_create(NULL, [[NSProcessInfo processInfo] processorCount]);
		for (int i = 0; i < 20; i++)
		{
			es_async(queue, ^{
				sleep(4);
				NSLog(@"%d", i);
			});
		}
		es_queue_notify(queue, ^{
			NSLog(@"Done");
			exit(0);
		});
		dispatch_main();
		
#else
		
		dispatch_queue_t queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
		dispatch_semaphore_t semaphore = dispatch_semaphore_create([[NSProcessInfo processInfo] processorCount]);
		dispatch_group_t group = dispatch_group_create();
		for (int i = 0; i < 20; i++)
		{
			dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
			dispatch_group_async(group, queue, ^{
				sleep(4);
				NSLog(@"%d", i);
				dispatch_semaphore_signal(semaphore);
			});
		}
		dispatch_group_notify(group, queue, ^{
			NSLog(@"Done");
			exit(0);
		});
		dispatch_main();
		
#endif
	}
    return 0;
}

