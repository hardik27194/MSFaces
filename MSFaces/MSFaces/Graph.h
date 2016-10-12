//
//  Graph.h
//  MSFaces
//
//  Created by Lee on 10/7/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Graph : NSObject

@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSArray *lines;
@property (strong, nonatomic) NSNumber *face;

+ (Graph *)createFromString:(NSString *)string;
- (NSString *)string;

@end
