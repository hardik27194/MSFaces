//
//  Line.h
//  MSFaces
//
//  Created by Lee on 10/5/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Line : NSObject
@property (strong, nonatomic) NSString *color;
@property (strong, nonatomic) NSNumber *width;
@property (strong, nonatomic) NSArray *points;
+(Line *)createFromString:(NSString *)string;
-(NSString *)string;
@end
