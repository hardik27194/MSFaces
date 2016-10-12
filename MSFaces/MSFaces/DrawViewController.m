//
//  DrawViewController.m
//  MSFaces
//
//  Created by Lee on 10/3/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import "DrawViewController.h"
#import "ACEDrawingView.h"
#import "ACEDrawingTools.h"
#import "Line.h"

#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import "UIColor+Hex.h"
#import "CNPPopupController.h"
#import "NetworkHelper.h"
#import "SVProgressHUD.h"
#import "UIImageView+WebCache.h"

#define kActionSheetColor       100
#define kActionSheetTool        101

@interface DrawViewController () <ACEDrawingViewDelegate, UIAlertViewDelegate, CNPPopupControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (weak, nonatomic) IBOutlet UIImageView *timerImageView;
@property (weak, nonatomic) IBOutlet ACEDrawingView *drawView;
@property (weak, nonatomic) IBOutlet UIView *topBarView;
@property (weak, nonatomic) IBOutlet UIView *toolBarView;
@property (weak, nonatomic) IBOutlet UIButton *profileButton;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView2;
@property (weak, nonatomic) IBOutlet UIView *overlayView;

@property (weak, nonatomic) IBOutlet UIButton *drawRedColorButton;
@property (weak, nonatomic) IBOutlet UIButton *drawGreenColorButton;
@property (weak, nonatomic) IBOutlet UIButton *drawBlueColorButton;
@property (weak, nonatomic) IBOutlet UIButton *drawYelloColorButton;
@property (weak, nonatomic) IBOutlet UIButton *drawGrayColorButton;
@property (weak, nonatomic) IBOutlet UIButton *drawBlackColorButton;
@property (weak, nonatomic) IBOutlet UIButton *drawFaceShapeButton;

@property (weak, nonatomic) IBOutlet UIButton *drawPenSmallButtom;
@property (weak, nonatomic) IBOutlet UIButton *drawPenMediumButton;
@property (weak, nonatomic) IBOutlet UIButton *drawPenLargeButton;

@property (weak, nonatomic) IBOutlet UIButton *drawUndoButton;
@property (weak, nonatomic) IBOutlet UIButton *drawCleanButton;
@property (weak, nonatomic) IBOutlet UIButton *drawDiscardButton;
@property (weak, nonatomic) IBOutlet UIButton *drawConfirmButton;
@property (weak, nonatomic) IBOutlet UIImageView *faceShapeImageView;

@property (assign, nonatomic) NSInteger currentFaceIndex;
@property (strong, nonatomic) CNPPopupController *popupController;
@property (strong, nonatomic) NSMutableArray *lineArray;
@property (assign, nonatomic) NSInteger timeLeft;
@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) NSArray *faceButtons;

@property (strong, nonatomic) Draw *draw;

@end

@implementation DrawViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lineArray = [NSMutableArray array];
    
    self.drawView.delegate = self;
    self.topBarView.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.33].CGColor;
    self.topBarView.layer.shadowRadius = 3;
    self.topBarView.layer.shadowOffset = CGSizeMake(0, 1);
    
    self.profileButton.layer.cornerRadius = 22.5;
    self.profileButton.clipsToBounds = YES;
    [self.profileButton addTarget:self action:@selector(profileButtonTouchBeginned:) forControlEvents:UIControlEventTouchDown];
    [self.profileButton addTarget:self action:@selector(profileButtonTouchCancelled:) forControlEvents:UIControlEventTouchUpInside];
    [self.profileButton addTarget:self action:@selector(profileButtonTouchCancelled:) forControlEvents:UIControlEventTouchDragOutside];
    
    self.profileImageView.layer.cornerRadius = 100;
    self.profileImageView.hidden = YES;
    self.profileImageView2.layer.cornerRadius = 22.5;
    self.profileImageView2.clipsToBounds = YES;
    
    self.drawUndoButton.layer.cornerRadius = 22.5;
    self.drawCleanButton.layer.cornerRadius = 22.5;
    self.drawDiscardButton.layer.cornerRadius = 22.5;
    self.drawConfirmButton.layer.cornerRadius = 22.5;
    self.drawFaceShapeButton.layer.cornerRadius = 22.5;
    self.drawFaceShapeButton.clipsToBounds = YES;
    
    self.drawPenLargeButton.layer.cornerRadius = 25/2.0;
    self.drawPenMediumButton.layer.cornerRadius = 21/2.0;
    self.drawPenSmallButtom.layer.cornerRadius = 17/2.0;
    
    self.drawRedColorButton.layer.cornerRadius = 12.5;
    self.drawGreenColorButton.layer.cornerRadius = 12.5;
    self.drawBlueColorButton.layer.cornerRadius = 12.5;
    self.drawYelloColorButton.layer.cornerRadius = 12.5;
    self.drawGrayColorButton.layer.cornerRadius = 12.5;
    self.drawBlackColorButton.layer.cornerRadius = 12.5;
    
    self.overlayView.hidden = YES;
    self.currentFaceIndex = 1;
    [self smallPenButtonClicked:self.drawPenSmallButtom];

    [self loadDraw];
}

- (void)loadDraw
{
    [SVProgressHUD show];
    [[NetworkHelper sharedHelper] getDrawWithCompletion:^(Draw *draw, NSError *err) {
        if (!err && draw)
        {
            [SVProgressHUD dismiss];
            self.draw = draw;
            [self updateData];
            [self showInitialPopup];
        }
        else
        {
            [SVProgressHUD showErrorWithStatus:@"Oops! Please try again later."];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

- (void)showInitialPopup
{
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"Are you ready?"
                                                                attributes:@{NSFontAttributeName : [UIFont fontWithName:@"SegoePrint" size:24],
                                                                             NSParagraphStyleAttributeName : paragraphStyle}];
    
    NSAttributedString *lineOne = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"You are about to create the artwork of your life within the next 60 seconds."]
                                                                  attributes:@{NSFontAttributeName : [UIFont fontWithName:@"SegoePrint" size:16],
                                                                               NSParagraphStyleAttributeName : paragraphStyle}];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView setImage:self.draw.image];
    [imageView setContentMode:UIViewContentModeScaleAspectFill];
    [imageView setFrame:CGRectMake(100, 0, 140, 140)];
    imageView.layer.cornerRadius = 70;
    imageView.backgroundColor = [UIColor whiteColor];
    imageView.clipsToBounds = YES;
    
    CNPPopupButton *button = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"SegoePrint" size:16];
    [button setTitle:@"Start!" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor colorWithRed:139/255.0 green:184/255.0 blue:56/255.0 alpha:1.0];
    button.layer.cornerRadius = 4;
    button.selectionHandler = ^(CNPPopupButton *button){
        [self.popupController dismissPopupControllerAnimated:YES];
        [self startGame];
    };
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.numberOfLines = 0;
    titleLabel.attributedText = title;
    
    UILabel *lineOneLabel = [[UILabel alloc] init];
    lineOneLabel.numberOfLines = 0;
    lineOneLabel.attributedText = lineOne;
    
    self.popupController = [[CNPPopupController alloc] initWithContents:@[titleLabel, lineOneLabel, imageView, button]];
    self.popupController.theme = [CNPPopupTheme defaultTheme];
    self.popupController.theme.popupStyle = CNPPopupStyleCentered;
    self.popupController.delegate = self;
    [self.popupController presentPopupControllerAnimated:YES];
}

- (void)showResult:(NSNumber *)score
{
    [SVProgressHUD dismiss];
    
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"Good Job!"
                                                                attributes:@{NSFontAttributeName : [UIFont fontWithName:@"SegoePrint" size:24],
                                                                             NSParagraphStyleAttributeName : paragraphStyle}];
    NSAttributedString *lineOne = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Your score is %@", score.stringValue]
                                                                  attributes:@{NSFontAttributeName : [UIFont fontWithName:@"SegoePrint" size:16],
                                                                               NSParagraphStyleAttributeName : paragraphStyle}];
    UIView *imagesView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 260, 140)];
    UIImageView *imageView2 = [[UIImageView alloc] init];
    [imageView2 setImage:self.draw.image];
    [imageView2 setContentMode:UIViewContentModeScaleAspectFill];
    [imageView2 setFrame:CGRectMake(110, 0, 140, 140)];
    imageView2.layer.cornerRadius = 70;
    imageView2.backgroundColor = [UIColor whiteColor];
    imageView2.clipsToBounds = YES;
    imageView2.layer.borderColor = [UIColor blackColor].CGColor;
    imageView2.layer.borderWidth = 2;
    [imagesView addSubview:imageView2];
    
    UIImageView *imageView1 = [[UIImageView alloc] init];
    [imageView1 setImage:[self takeScreenshot]];
    imageView1.backgroundColor = [UIColor whiteColor];
    [imageView1 setContentMode:UIViewContentModeScaleAspectFill];
    [imageView1 setFrame:CGRectMake(15, 0, 140, 140)];
    imageView1.layer.cornerRadius = 70;
    imageView1.layer.borderColor = [UIColor blackColor].CGColor;
    imageView1.layer.borderWidth = 2;
    imageView1.clipsToBounds = YES;
    [imagesView addSubview:imageView1];
    
    CNPPopupButton *button = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"SegoePrint" size:16];
    [button setTitle:@"Close" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor colorWithRed:139/255.0 green:184/255.0 blue:56/255.0 alpha:1.0];
    button.layer.cornerRadius = 4;
    button.selectionHandler = ^(CNPPopupButton *button){
        [self.popupController dismissPopupControllerAnimated:YES];
        [self.navigationController popViewControllerAnimated:YES];
    };
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.numberOfLines = 0;
    titleLabel.attributedText = title;
    
    UILabel *lineOneLabel = [[UILabel alloc] init];
    lineOneLabel.numberOfLines = 0;
    lineOneLabel.attributedText = lineOne;
    
//    UILabel *lineTwoLabel = [[UILabel alloc] init];
//    lineTwoLabel.numberOfLines = 0;
//    lineTwoLabel.attributedText = lineTwo;
    
    self.popupController = [[CNPPopupController alloc] initWithContents:@[titleLabel, lineOneLabel, imagesView, button]];
    self.popupController.theme = [CNPPopupTheme defaultTheme];
    self.popupController.theme.popupStyle = CNPPopupStyleCentered;
    self.popupController.delegate = self;
    [self.popupController presentPopupControllerAnimated:YES];
}

- (void)uploadDraw
{
    [SVProgressHUD show];
    Graph *graph = [self finishDrawing];
    [[NetworkHelper sharedHelper] createDrawWithDraw:self.draw
                                               graph:graph completion:^(NSNumber *score, NSError *err)
    {
        if (score)
        {
            [SVProgressHUD dismiss];
            [self showResult:score];
        }
        else
        {
            [SVProgressHUD showErrorWithStatus:@"Oops! Please try again later."];
        }
    }];
}

- (Graph *)finishDrawing
{
    NSMutableArray *lines = [NSMutableArray array];
    for (ACEDrawingPenTool *pen in self.lineArray)
    {
        if ([pen isKindOfClass:[ACEDrawingPenTool class]])
        {
            ACEDrawingPenTool *tool = (ACEDrawingPenTool *)pen;
            NSMutableArray *bezierPoints = [NSMutableArray array];
            CGPathApply(tool.path, (__bridge void *)bezierPoints, MyCGPathApplierFunc);
            Line *line = [[Line alloc] init];
            line.color = [tool.lineColor cssString];
            line.width = @(tool.lineWidth);
            line.points = bezierPoints;
            [lines addObject:line];
        }
    }
    Graph *graph = [[Graph alloc] init];
    graph.lines = lines;
    graph.face = @(self.currentFaceIndex);
    graph.identifier = self.draw.identifier;
    return graph;
}

- (void)updateData
{
    [self.profileButton.imageView setImage:self.profileImage];
    [self.profileImageView2 setImage:self.draw.image];
    [self.profileImageView setImage:self.draw.image];
}

- (void)startGame
{
    [self resetTimer];
    [self startAnimatingTimer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)updateCounter:(NSTimer *)theTimer
{
    if(self.timeLeft > 0 ) {
        self.timeLeft -- ;
        self.timerLabel.text = [NSString stringWithFormat:@"0:%02ld", (long)self.timeLeft];
    } else {
        self.timerLabel.text = @"0:00";
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
    [self resetTimer];
    [self startAnimatingTimer];
    [self.drawView clear];
}

- (UIImage *)takeScreenshot
{
    return self.drawView.image;
}

- (void)startAnimatingTimer;
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateCounter:) userInfo:nil repeats:YES];
    [self.timer fire];
    
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 * self.timeLeft * 1 ];
    rotationAnimation.duration = self.timeLeft+2;
    rotationAnimation.cumulative = YES;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [self.timerImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)stopAnimatingTimer
{
    [self.timer invalidate];
    
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 *1 ];
    rotationAnimation.duration = self.timeLeft>1?1:self.timeLeft;
    rotationAnimation.cumulative = YES;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [self.timerImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)resetTimer
{
    self.timeLeft = 60;
}

- (void)timeout
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Time Out"
                                                                             message:@"Would you like to submit your drawing?"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"Yes"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         [self uploadDraw];
                                                     }];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"No"
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         [self.navigationController popViewControllerAnimated:YES];
                                                     }];
    [alertController addAction:actionOk];
    [alertController addAction:actionCancel];
    [self presentViewController:alertController animated:YES completion:nil];
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
    [self stopAnimatingTimer];
    
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
                                                         [self startAnimatingTimer];
                                                     }];
    
    [alertController addAction:actionOk];
    [alertController addAction:actionCancel];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)confirmButtonClicked:(id)sender
{
    [self stopAnimatingTimer];
    
    if (self.lineArray.count == 0)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Oops!"
                                                                                 message:@"Please draw something before submitting"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"Ok"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self startAnimatingTimer];
                                                         }];
        [alertController addAction:actionOk];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Confirm"
                                                                                 message:@"Are you sure to submit your drawing?"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"Ok"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self stopAnimatingTimer];
                                                             [self uploadDraw];
                                                         }];
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 [self startAnimatingTimer];
                                                             }];
        
        [alertController addAction:actionOk];
        [alertController addAction:actionCancel];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (IBAction)faceShapeButtonClicked:(id)sender
{
    [self stopAnimatingTimer];
    [self showPopupWithStyle:CNPPopupStyleActionSheet];
}

#pragma mark - ACEDrawing View Delegate

- (void)drawingView:(ACEDrawingView *)view didEndDrawUsingTool:(id<ACEDrawingTool>)tool;
{
    [self.lineArray removeAllObjects];
    [self.lineArray addObjectsFromArray:view.pathArray];
}

void MyCGPathApplierFunc (void *info, const CGPathElement *element)
{
    NSMutableArray *bezierPoints = (__bridge NSMutableArray *)info;
    CGPoint *points = element->points;
    CGPathElementType type = element->type;
    
    switch(type) {
        case kCGPathElementAddQuadCurveToPoint: // contains 2 points
            [bezierPoints addObject:NSStringFromCGPoint(points[0])];
            [bezierPoints addObject:NSStringFromCGPoint(points[1])];
            break;
            
        case kCGPathElementAddCurveToPoint: // contains 3 points
            [bezierPoints addObject:NSStringFromCGPoint(points[0])];
            [bezierPoints addObject:NSStringFromCGPoint(points[1])];
            [bezierPoints addObject:NSStringFromCGPoint(points[2])];
            break;
            
        case kCGPathElementCloseSubpath: // contains no point
            break;
            
        default:
            break;
    }
}

- (void)showPopupWithStyle:(CNPPopupStyle)popupStyle
{
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"Choose a face shape"
                                                                attributes:@{NSFontAttributeName:[UIFont fontWithName:@"SegoePrint" size:24],
                                                                             NSParagraphStyleAttributeName:paragraphStyle}];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.numberOfLines = 0;
    titleLabel.attributedText = title;

    CGFloat height = self.view.frame.size.width/3;
    CGFloat width = self.view.frame.size.width/3;
    CGFloat x = 0;
    CGFloat y = 0;
    
    UIImageView *mark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"draw_confirm"]];
    mark.frame = CGRectMake(width*(self.currentFaceIndex%3)+width/2.0-10,
                            height*(self.currentFaceIndex/4+1)-20, 20, 20);
    mark.backgroundColor = [UIColor clearColor];
    
    UIView *faceView = [[UIView alloc] initWithFrame:CGRectMake(0, 10, width*3, height*2)];
    
    UIButton *face1 = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, height)];
    face1.contentMode = UIViewContentModeScaleAspectFit;
    face1.imageView.contentMode = UIViewContentModeScaleAspectFit;
    face1.layer.cornerRadius = height/2;
    face1.clipsToBounds = YES;
    [face1 setImage:[UIImage imageNamed:@"face_0"] forState:UIControlStateNormal];
    [face1 addTarget:self action:@selector(faceChoosed:) forControlEvents:UIControlEventTouchUpInside];
    [faceView addSubview:face1];
    
    x += width;
    UIButton *face2 = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, height)];
    face2.contentMode = UIViewContentModeScaleAspectFit;
    face2.imageView.contentMode = UIViewContentModeScaleAspectFit;
    face2.layer.cornerRadius = height/2;
    face2.clipsToBounds = YES;
    [face2 setImage:[UIImage imageNamed:@"face_1"] forState:UIControlStateNormal];
    [face2 addTarget:self action:@selector(faceChoosed:) forControlEvents:UIControlEventTouchUpInside];
    [faceView addSubview:face2];
    
    x += width;
    UIButton *face3 = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, height)];
    face3.contentMode = UIViewContentModeScaleAspectFit;
    face3.imageView.contentMode = UIViewContentModeScaleAspectFit;
    face3.layer.cornerRadius = height/2;
    face3.clipsToBounds = YES;
    [face3 setImage:[UIImage imageNamed:@"face_2"] forState:UIControlStateNormal];
    [face3 addTarget:self action:@selector(faceChoosed:) forControlEvents:UIControlEventTouchUpInside];
    [faceView addSubview:face3];
    
    x = 0;
    y += height;
    UIButton *face4 = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, height)];
    face4.contentMode = UIViewContentModeScaleAspectFit;
    face4.imageView.contentMode = UIViewContentModeScaleAspectFit;
    face4.layer.cornerRadius = height/2;
    face4.clipsToBounds = YES;
    [face4 setImage:[UIImage imageNamed:@"face_3"] forState:UIControlStateNormal];
    [face4 addTarget:self action:@selector(faceChoosed:) forControlEvents:UIControlEventTouchUpInside];
    [faceView addSubview:face4];
    
    x += width;
    UIButton *face5 = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, height)];
    face5.contentMode = UIViewContentModeScaleAspectFit;
    face5.imageView.contentMode = UIViewContentModeScaleAspectFit;
    face5.layer.cornerRadius = height/2;
    face5.clipsToBounds = YES;
    [face5 setImage:[UIImage imageNamed:@"face_4"] forState:UIControlStateNormal];
    [face5 addTarget:self action:@selector(faceChoosed:) forControlEvents:UIControlEventTouchUpInside];
    [faceView addSubview:face5];
    
    x += width;
    UIButton *face6 = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, height)];
    face6.contentMode = UIViewContentModeScaleAspectFit;
    face6.imageView.contentMode = UIViewContentModeScaleAspectFit;
    face6.layer.cornerRadius = height/2;
    face6.clipsToBounds = YES;
    [face6 setImage:[UIImage imageNamed:@"face_5"] forState:UIControlStateNormal];
    [face6 addTarget:self action:@selector(faceChoosed:) forControlEvents:UIControlEventTouchUpInside];
    [faceView addSubview:face6];
    
    [faceView addSubview:mark];
    self.faceButtons = @[face1, face2, face3, face4, face5, face6];
    
    self.popupController = [[CNPPopupController alloc] initWithContents:@[titleLabel, faceView]];
    self.popupController.theme = [CNPPopupTheme defaultTheme];
    self.popupController.theme.popupStyle = CNPPopupStyleActionSheet;
    self.popupController.theme.shouldDismissOnBackgroundTouch = NO;
    self.popupController.delegate = self;
    [self.popupController presentPopupControllerAnimated:YES];
}

- (void)faceChoosed:(UIButton *)button
{
    [self startAnimatingTimer];
    [self.popupController dismissPopupControllerAnimated:YES];
    NSInteger index = [self.faceButtons indexOfObject:button];
    self.currentFaceIndex = index;
    [self.faceShapeImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"face_%ld", index]]];
}

#pragma mark - CNPPopupController Delegate

- (void)popupController:(CNPPopupController *)controller didDismissWithButtonTitle:(NSString *)title
{
    NSLog(@"Dismissed with button title: %@", title);
}

- (void)popupControllerDidPresent:(CNPPopupController *)controller
{
    NSLog(@"Popup controller presented.");
}

@end
