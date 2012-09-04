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
