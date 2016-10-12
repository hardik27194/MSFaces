//
//  Guess.h
//  MSFaces
//
//  Created by Lee on 10/7/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Draw.h"
#import "Graph.h"

@interface Guess : NSObject

@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) Graph *graph;
@property (strong, nonatomic) NSArray *options;

@end
