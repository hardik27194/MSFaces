//
//  ViewController.m
//  MSFaces
//
//  Created by Lee on 10/3/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import "HomeViewController.h"
#import "DrawViewController.h"

@interface HomeViewController ()

@property (weak, nonatomic) IBOutlet UIButton *drawButton;
@property (weak, nonatomic) IBOutlet UIButton *quizButton;
@property (weak, nonatomic) IBOutlet UIButton *rankButton;
@property (weak, nonatomic) IBOutlet UIButton *profileButton;
@property (weak, nonatomic) IBOutlet UIButton *userButton;

@end

@implementation HomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.drawButton.layer.cornerRadius = 60;
    self.quizButton.layer.cornerRadius = 60;
    self.rankButton.layer.cornerRadius = 60;
    self.profileButton.layer.cornerRadius = 60;
    self.userButton.layer.cornerRadius = 20;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Home2Draw"])
    {
        DrawViewController *drawVC = segue.destinationViewController;
        drawVC.profileImage = [UIImage imageNamed:@"logo_no_bg"];
    }
}

@end
