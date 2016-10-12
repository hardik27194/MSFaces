//
//  ProfileViewController.m
//  MSFaces
//
//  Created by Lee on 10/4/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import "ProfileViewController.h"
#import "ProfileCollectionViewCell.h"
#import "NetworkHelper.h"
#import "SVProgressHUD.h"
#import "UIImageView+WebCache.h"

@interface ProfileViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIButton *msButton;
@property (weak, nonatomic) IBOutlet UIButton *userButton;

@property (strong, nonatomic) NSMutableArray *objects;

@end

@implementation ProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:244/255.0 green:188/255.0 blue:64/255.0 alpha:1.0];
    self.pageControl.pageIndicatorTintColor = [UIColor grayColor];
    
    [self.collectionView setPagingEnabled:YES];
    
    self.userButton.layer.cornerRadius = 22.5;
    self.userButton.clipsToBounds= YES;
    
    if (self.profileImage)
    {
        [self.userButton setImage:self.profileImage forState:UIControlStateNormal];
    }
    
    self.users = @[];
    
    [self loadUsers];
}

- (void)loadUsers
{
    [SVProgressHUD show];
    [[NetworkHelper sharedHelper] getCollectionWithCompletion:^(NSArray *users, NSInteger re, NSInteger to, NSError *error)
    {
        self.users = users;
        [self.collectionView reloadData];
        self.countLabel.text = [NSString stringWithFormat:@"%ld/%ld", (long)re, (long)to];
        [SVProgressHUD dismiss];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSInteger number = ((int)self.collectionView.contentSize.width) / ((int)self.collectionView.frame.size.width);
    number += (((int)self.collectionView.contentSize.width) % ((int)self.collectionView.frame.size.width)) > 0 ? 1 : 0;
    self.pageControl.numberOfPages = number;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)msButtonClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.view.frame.size.width/3, 145);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.users.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ProfileCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ProfileCollectionViewCell" forIndexPath:indexPath];
    NSDictionary *user = [self.users objectAtIndex:indexPath.row];
    cell.nameLabel.text = [[user objectForKey:@"firstName"] stringByAppendingFormat:@" %@", [user objectForKey:@"lastName"]];
    cell.aliasLabel.text = [user objectForKey:@"alias"];
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[serverPath stringByAppendingString:[user objectForKey:@"profileImage"]]]
                      placeholderImage:[UIImage imageNamed:@"face"]];
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat pageWidth = self.collectionView.frame.size.width;
    NSInteger page = ((int)self.collectionView.contentOffset.x) / ((int)pageWidth);
    page += self.collectionView.contentOffset.x > (pageWidth * page) ? 1 : 0;
    self.pageControl.currentPage = page;
}

@end
