//
//  Line.m
//  MSFaces
//
//  Created by Lee on 10/5/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import "Line.h"

@implementation Line

+ (Line *)createFromString:(NSString *)string
{
    NSError * err;
    NSData *data =[string dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];

    Line *line = [[Line alloc] init];
    line.color = [dict objectForKey:@"color"];
    line.width = [dict objectForKey:@"width"];
    line.points = [dict objectForKey:@"points"];
    
    return line;
}

- (NSString *)string
{
    NSError * err;
    NSDictionary *dict = @{@"color":self.color, @"width":self.width, @"points":self.points};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&err];
    NSString *str = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return str;
}

@end
