//
//  QuizViewController.m
//  MSFaces
//
//  Created by Lee on 10/4/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import "QuizViewController.h"
#import "BEMCheckBox.h"

@interface QuizViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *timerImageView;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;

@property (weak, nonatomic) IBOutlet UIButton *optionOneButton;
@property (weak, nonatomic) IBOutlet UIButton *optionTwoButton;
@property (weak, nonatomic) IBOutlet UIButton *optionThreeButton;
@property (weak, nonatomic) IBOutlet UIButton *optionFourButton;

@property (weak, nonatomic) IBOutlet UILabel *optionOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *optionTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *optionThreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *optionFourLabel;

@property (weak, nonatomic) IBOutlet UILabel *optionOneSublabel;
@property (weak, nonatomic) IBOutlet UILabel *optionTwoSublabel;
@property (weak, nonatomic) IBOutlet UILabel *optionThreeSublabel;
@property (weak, nonatomic) IBOutlet UILabel *optionFourSublabel;

@property (assign, nonatomic) NSInteger timeLeft;
@property (strong, nonatomic) NSTimer *timer;

@end

@implementation QuizViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.timeLeft = 60;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateCounter:) userInfo:nil repeats:YES];
    [self.timer fire];
    
    [self spinTimer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateCounter:(NSTimer *)theTimer
{
    if(self.timeLeft > 0 ) {
        self.timeLeft -- ;
        self.timerLabel.text = [NSString stringWithFormat:@"%02lds", (long)self.timeLeft];
    } else {
        self.timerLabel.text = @"0s";
        [self.timer invalidate];
//        [self timeout];
    }
}

- (void)spinTimer;
{
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 * 60 * 1 ];
    rotationAnimation.duration = 62;
    rotationAnimation.cumulative = YES;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [self.timerImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (IBAction)optionOneButtonClicked:(id)sender
{
    
}

- (IBAction)optionTwoButtonClicked:(id)sender
{
    
}

- (IBAction)optionThreeButton:(id)sender
{
    
}

- (IBAction)optionFourButton:(id)sender
{
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
