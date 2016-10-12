//
//  User.m
//  MSFaces
//
//  Created by Lee on 10/7/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import "User.h"
#import <UIKit/UIKit.h>

@implementation User
User *_sharedUser;
@synthesize alias = _alias;
@synthesize profileImage = _profileImage;

+(instancetype)sharedUser
{
    if (!_sharedUser)
    {
        _sharedUser = [[User alloc] init];
    }
    
    return _sharedUser;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self alias];
        [self profileImage];
    }
    return self;
}

#pragma Alias

- (NSString *)alias
{
    _alias = [[NSUserDefaults standardUserDefaults] objectForKey:@"User-Alias"];
    return _alias;
}

- (void)setAlias:(NSString *)alias
{
    if (!alias || [alias isEqualToString:@""]) return;
    
    _alias = alias;
    [[NSUserDefaults standardUserDefaults] setObject:alias forKey:@"User-Alias"];
}

#pragma Image

- (UIImage *)profileImage
{
    if (!_profileImage)
    {
        NSData *imageData = [[NSUserDefaults standardUserDefaults] objectForKey:@"User-ProfileImage"];
        _profileImage = [[UIImage alloc] initWithData:imageData];
    }
    return _profileImage;
}

- (void)setProfileImage:(UIImage *)profileImage
{
    if (!profileImage) return;
    
    _profileImage = profileImage;
    NSData *imageData = UIImageJPEGRepresentation(_profileImage, 1.0);
    [[NSUserDefaults standardUserDefaults] setObject:imageData forKey:@"User-ProfileImage"];
}

@end
