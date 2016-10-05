//
//  DrawViewController.m
//  MSFaces
//
//  Created by Lee on 10/3/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import "DrawViewController.h"
#import "ACEDrawingView.h"
#import "ASScreenRecorder.h"

#import <QuartzCore/QuartzCore.h>

#define kActionSheetColor       100
#define kActionSheetTool        101

@interface DrawViewController () <ACEDrawingViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (weak, nonatomic) IBOutlet UIImageView *timerImageView;
@property (weak, nonatomic) IBOutlet ACEDrawingView *drawView;
@property (weak, nonatomic) IBOutlet UIView *topBarView;
@property (weak, nonatomic) IBOutlet UIView *toolBarView;
@property (weak, nonatomic) IBOutlet UIButton *profileButton;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UIView *overlayView;

@property (weak, nonatomic) IBOutlet UIButton *drawRedColorButton;
@property (weak, nonatomic) IBOutlet UIButton *drawGreenColorButton;
@property (weak, nonatomic) IBOutlet UIButton *drawBlueColorButton;
@property (weak, nonatomic) IBOutlet UIButton *drawYelloColorButton;
@property (weak, nonatomic) IBOutlet UIButton *drawGrayColorButton;
@property (weak, nonatomic) IBOutlet UIButton *drawBlackColorButton;

@property (weak, nonatomic) IBOutlet UIButton *drawPenSmallButtom;
@property (weak, nonatomic) IBOutlet UIButton *drawPenMediumButton;
@property (weak, nonatomic) IBOutlet UIButton *drawPenLargeButton;

@property (weak, nonatomic) IBOutlet UIButton *drawUndoButton;
@property (weak, nonatomic) IBOutlet UIButton *drawCleanButton;
@property (weak, nonatomic) IBOutlet UIButton *drawDiscardButton;
@property (weak, nonatomic) IBOutlet UIButton *drawConfirmButton;

@property (assign, nonatomic) NSInteger timeLeft;
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation DrawViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.drawView.delegate = self;
    self.topBarView.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.33].CGColor;
    self.topBarView.layer.shadowRadius = 3;
    self.topBarView.layer.shadowOffset = CGSizeMake(0, 1);
    
    self.profileButton.layer.cornerRadius = 20;
    self.profileImageView.layer.cornerRadius = 100;

    if (self.profileImage)
    {
        [self.profileButton setImage:self.profileImage forState:UIControlStateNormal];
        [self.profileImageView setImage:self.profileImage];
    }
    
    [self.profileButton addTarget:self action:@selector(profileButtonTouchBeginned:) forControlEvents:UIControlEventTouchDown];
    [self.profileButton addTarget:self action:@selector(profileButtonTouchCancelled:) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.drawUndoButton.layer.cornerRadius = 22.5;
    self.drawCleanButton.layer.cornerRadius = 22.5;
    self.drawDiscardButton.layer.cornerRadius = 22.5;
    self.drawConfirmButton.layer.cornerRadius = 22.5;
 
    
    self.drawPenLargeButton.layer.cornerRadius = 15;
    self.drawPenMediumButton.layer.cornerRadius = 12.5;
    self.drawPenSmallButtom.layer.cornerRadius = 10;
    
    self.drawRedColorButton.layer.cornerRadius = 12.5;
    self.drawGreenColorButton.layer.cornerRadius = 12.5;
    self.drawBlueColorButton.layer.cornerRadius = 12.5;
    self.drawYelloColorButton.layer.cornerRadius = 12.5;
    self.drawGrayColorButton.layer.cornerRadius = 12.5;
    self.drawBlackColorButton.layer.cornerRadius = 12.5;
    
    self.profileImageView.hidden = YES;
    self.overlayView.hidden = YES;
    
    [self smallPenButtonClicked:self.drawPenSmallButtom];
    
    self.timeLeft = 60;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateCounter:) userInfo:nil repeats:YES];
    [self.timer fire];
    [self spinTimer];
    [self startRecording];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)updateCounter:(NSTimer *)theTimer
{
    if(self.timeLeft > 0 ) {
        self.timeLeft -- ;
        self.timerLabel.text = [NSString stringWithFormat:@"%02lds", (long)self.timeLeft];
    } else {
        self.timerLabel.text = @"0s";
        [self.timer invalidate];
        [self timeout];
    }
}

- (void)profileButtonTouchBeginned:(id)sender
{
    self.profileImageView.hidden = NO;
    self.overlayView.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.profileImageView.alpha = 1;
        self.overlayView.alpha = 1;
    } completion:^(BOOL finished) {
    }];
}

- (void)profileButtonTouchCancelled:(id)sender
{
    [UIView animateWithDuration:0.2 animations:^{
        self.profileImageView.alpha = 0;
        self.overlayView.alpha = 0;
    } completion:^(BOOL finished) {
        self.profileImageView.hidden = YES;
        self.overlayView.hidden = YES;
    }];
}

- (void)setDrawViewLineColor:(UIColor *)color
{
    self.drawView.lineColor = color;
}

- (void)setDrawViewLineWidth:(CGFloat)width
{
    self.drawView.lineWidth = width;
}

- (void)setDrawPenColor:(UIColor *)color
{
    UIColor *unselectedColor = [color colorWithAlphaComponent:0.25];
    UIColor *selectedColor = [color colorWithAlphaComponent:1];
    
    [self.drawPenSmallButtom setBackgroundColor:self.drawPenSmallButtom.selected?selectedColor:unselectedColor];
    [self.drawPenMediumButton setBackgroundColor:self.drawPenMediumButton.selected?selectedColor:unselectedColor];
    [self.drawPenLargeButton setBackgroundColor:self.drawPenLargeButton.selected?selectedColor:unselectedColor];
}

- (void)undoDraw
{
    [self.drawView undoLatestStep];
}

- (void)clearDraws
{
    self.timeLeft = 60;
    [self spinTimer];
    [self.drawView clear];
}

- (UIImage *)takeScreenshot
{
    return self.drawView.image;
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

- (void)timeout
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Time Out"
                                                                             message:@"Sorry, time out!"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"Ok"
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                     }];
    [alertController addAction:actionOk];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)startRecording
{
    ASScreenRecorder *recorder = [ASScreenRecorder sharedInstance];
    [recorder startRecording];
}

- (void)stopRecording
{
    ASScreenRecorder *recorder = [ASScreenRecorder sharedInstance];
    [recorder stopRecordingWithCompletion:^{
    }];
}

#pragma mark - Color Change

- (IBAction)redColorButtonClicked:(id)sender
{
    UIColor *color = [UIColor colorWithRed:223/255.0 green:92/255.0 blue:58/255.0 alpha:1];
    [self setDrawViewLineColor:color];
    [self setDrawPenColor:color];
}

- (IBAction)greenColorButtonClicked:(id)sender
{
    UIColor *color = [UIColor colorWithRed:139/255.0 green:184/255.0 blue:56/255.0 alpha:1];
    [self setDrawViewLineColor:color];
    [self setDrawPenColor:color];
}

- (IBAction)blueColorButtonClicked:(id)sender
{
    UIColor *color = [UIColor colorWithRed:72/255.0 green:160/255.0 blue:232/255.0 alpha:1];
    [self setDrawViewLineColor:color];
    [self setDrawPenColor:color];
}

- (IBAction)yellowColorButtonClicked:(id)sender
{
    UIColor *color = [UIColor colorWithRed:244/255.0 green:188/255.0 blue:64/255.0 alpha:1];
    [self setDrawViewLineColor:color];
    [self setDrawPenColor:color];
}

- (IBAction)grayColorButtonClicked:(id)sender
{
    UIColor *color = [UIColor colorWithRed:166/255.0 green:166/255.0 blue:166/255.0 alpha:1];
    [self setDrawViewLineColor:color];
    [self setDrawPenColor:color];
}

- (IBAction)blackColorButtonClicked:(id)sender
{
    UIColor *color = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1];
    [self setDrawViewLineColor:color];
    [self setDrawPenColor:color];
}

- (IBAction)smallPenButtonClicked:(id)sender
{
    [self.drawPenSmallButtom setSelected:YES];
    [self.drawPenMediumButton setSelected:NO];
    [self.drawPenLargeButton setSelected:NO];
    
    [self setDrawViewLineWidth:4];
    [self setDrawPenColor:self.drawPenSmallButtom.backgroundColor];
}

- (IBAction)mediumPenClicked:(id)sender
{
    [self.drawPenSmallButtom setSelected:NO];
    [self.drawPenMediumButton setSelected:YES];
    [self.drawPenLargeButton setSelected:NO];
    
    [self setDrawViewLineWidth:7];
    [self setDrawPenColor:self.drawPenMediumButton.backgroundColor];
}

- (IBAction)largePenButtonClicked:(id)sender
{
    [self.drawPenSmallButtom setSelected:NO];
    [self.drawPenMediumButton setSelected:NO];
    [self.drawPenLargeButton setSelected:YES];
    
    [self setDrawViewLineWidth:10];
    [self setDrawPenColor:self.drawPenLargeButton.backgroundColor];
}

- (IBAction)undoButtonClicked:(id)sender
{
    [self undoDraw];
}

- (IBAction)cleanButtonClicked:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Clean"
                                                                             message:@"Are you sure to clean everything and restart?"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"Ok"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         [self clearDraws];
                                                     }];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             
                                                         }];
    
    [alertController addAction:actionOk];
    [alertController addAction:actionCancel];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)discardButtonClicked:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Discard"
                                                                             message:@"Are you sure to stop drawing?"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"Ok"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         [self.navigationController popViewControllerAnimated:YES];
                                                     }];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         
                                                     }];
    
    [alertController addAction:actionOk];
    [alertController addAction:actionCancel];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)confirmButtonClicked:(id)sender
{
    [self stopRecording];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Confirm"
                                                                             message:@"Are you sure to submit your drawing?"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"Ok"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                     }];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    [alertController addAction:actionOk];
    [alertController addAction:actionCancel];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - ACEDrawing View Delegate

- (void)drawingView:(ACEDrawingView *)view didEndDrawUsingTool:(id<ACEDrawingTool>)tool;
{
}

@end
