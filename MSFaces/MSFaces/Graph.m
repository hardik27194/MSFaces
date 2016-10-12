//
//  Graph.m
//  MSFaces
//
//  Created by Lee on 10/7/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import "Graph.h"
#import "Line.h"

@implementation Graph

+ (Graph *)createFromString:(NSString *)string
{
    NSError * err;
    NSData *data =[string dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    NSArray *lineStrs = [dict objectForKey:@"lines"];
    NSNumber *face = [dict objectForKey:@"face"];
    
    NSMutableArray *lines = [NSMutableArray array];
    for (NSString *l in lineStrs)
    {
        [lines addObject:[Line createFromString:l]];
    }
    
    Graph *graph = [[Graph alloc] init];
    graph.lines = lines;
    graph.face = face;
    
    return graph;
}

- (NSString *)string
{
    NSMutableArray *lineStrs = [NSMutableArray array];
    for (Line *l in self.lines)
    {
        [lineStrs addObject:[l string]];
    }
    
    NSError * err;
    NSDictionary *dict = @{@"lines":lineStrs, @"face":self.face};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&err];
    NSString *str = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return str;
}

@end
