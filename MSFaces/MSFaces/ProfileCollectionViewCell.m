//
//  ProfileCollectionViewCell.m
//  MSFaces
//
//  Created by Lee on 10/5/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import "ProfileCollectionViewCell.h"

@implementation ProfileCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.imageView.layer.cornerRadius = 35;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.imageView.layer.cornerRadius = 35;
    }
    return self;
}

@end
