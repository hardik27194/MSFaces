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

@interface RankViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *drawCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *guessCollectionView;

@property (weak, nonatomic) IBOutlet UILabel *drawRankLabel;
@property (weak, nonatomic) IBOutlet UILabel *guessRankLabel;

@property (strong, nonatomic) NSMutableArray *drawObjects;
@property (strong, nonatomic) NSMutableArray *guessObjects;

@end

@implementation RankViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    return CGSizeMake(self.view.frame.size.width/3, 120);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 3;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.drawCollectionView])
    {
        RankCollectionViewDrawCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"RankCollectionViewCellDraw"
                                                                                 forIndexPath:indexPath];
        return cell;
    }
    else
    {
        RankCollectionViewGuessCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"RankCollectionViewCellGuess"
                                                                                 forIndexPath:indexPath];
        return cell;
    }
}

@end
