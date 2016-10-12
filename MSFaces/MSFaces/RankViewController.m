//
//  RankViewController.m
//  MSFaces
//
//  Created by Lee on 10/4/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import "RankViewController.h"
#import "RankCollectionViewDrawCell.h"
#import "RankCollectionViewGuessCell.h"
#import "SVProgressHUD.h"
#import "UIImageView+WebCache.h"
#import "NetworkHelper.h"

@interface RankViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *drawCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *guessCollectionView;

@property (weak, nonatomic) IBOutlet UILabel *drawRankLabel;
@property (weak, nonatomic) IBOutlet UILabel *guessRankLabel;

@property (nonatomic, strong) NSArray *drawUsers;
@property (nonatomic, strong) NSArray *guessUsers;
@property (nonatomic, assign) NSInteger drawRank;
@property (nonatomic, assign) NSInteger guessRank;

@property (weak, nonatomic) IBOutlet UIButton *userButton;

@end

@implementation RankViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.userButton.layer.cornerRadius = 22.5;
    self.userButton.clipsToBounds= YES;
    
    self.drawUsers = @[];
    self.guessUsers = @[];
    self.drawRank = 0;
    self.guessRank = 0;
    
    if (self.profileImage)
    {
        [self.userButton setImage:self.profileImage forState:UIControlStateNormal];
    }
    
    [self loadUsers];
}

- (void)loadUsers
{
    [SVProgressHUD show];
    [[NetworkHelper sharedHelper] getLeaderBoardWithCompletion:^(NSArray *drawUsers, NSArray *guessUsers, NSInteger drawRank, NSInteger guessRank, NSError *error)
     {
         self.drawUsers = drawUsers;
         self.guessUsers = guessUsers;
         self.drawRank = drawRank;
         self.guessRank = guessRank;
         
         [self.drawCollectionView reloadData];
         [self.guessCollectionView reloadData];
         [SVProgressHUD dismiss];
         
         self.drawRankLabel.text = [NSString stringWithFormat:@"Your current rank: No. %ld", self.drawRank];
         self.guessRankLabel.text = [NSString stringWithFormat:@"Your current rank: No. %ld", self.guessRank];
     }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)msButtonClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.view.frame.size.width/3, 142);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ([collectionView isEqual:self.drawCollectionView])
    {
        return self.drawUsers.count > 3 ? 3 : self.drawUsers.count;
    }
    else
    {
        return self.guessUsers.count > 3 ? 3 : self.guessUsers.count;
    }
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.drawCollectionView])
    {
        NSDictionary *user = [self.drawUsers objectAtIndex:indexPath.row];
        RankCollectionViewDrawCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"RankCollectionViewCellDraw"
                                                                                 forIndexPath:indexPath];
        cell.rankLabel.text = [NSString stringWithFormat:@"No. %ld", indexPath.row+1];
        cell.nameLabel.text = [user objectForKey:@"alias"];
        cell.pointLabel.text = [NSString stringWithFormat:@"%ld points", [[user objectForKey:@"pts"] integerValue]];
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[serverPath stringByAppendingString:[user objectForKey:@"profileImage"]]]];
        return cell;
    }
    else
    {
        NSDictionary *user = [self.guessUsers objectAtIndex:indexPath.row];
        RankCollectionViewGuessCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"RankCollectionViewCellGuess"
                                                                                 forIndexPath:indexPath];
        cell.rankLabel.text = [NSString stringWithFormat:@"No. %ld", indexPath.row+1];
        cell.nameLabel.text = [user objectForKey:@"alias"];
        cell.pointLabel.text = [NSString stringWithFormat:@"%ld points", [[user objectForKey:@"pts"] integerValue]];
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[serverPath stringByAppendingString:[user objectForKey:@"profileImage"]]]];
        return cell;
    }
}

@end
