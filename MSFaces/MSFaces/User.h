//
//  User.h
//  MSFaces
//
//  Created by Lee on 10/7/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface User : NSObject

@property (strong, nonatomic) NSString *alias;
@property (strong, nonatomic) UIImage *profileImage;

@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;

+(instancetype)sharedUser;

@end
