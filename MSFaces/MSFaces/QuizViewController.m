//
//  QuizViewController.m
//  MSFaces
//
//  Created by Lee on 10/4/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import "QuizViewController.h"
#import "BEMCheckBox.h"
#import "Line.h"
#import "UIColor+Hex.h"
#import "UIBezierPath+Length.h"
#import "NetworkHelper.h"
#import "SVProgressHUD.h"
#import "UIImageView+WebCache.h"
#import "CNPPopupController.h"

@interface QuizViewController () <CAAnimationDelegate, CNPPopupControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *timerImageView;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;

@property (weak, nonatomic) IBOutlet UIButton *optionOneButton;
@property (weak, nonatomic) IBOutlet UIButton *optionTwoButton;
@property (weak, nonatomic) IBOutlet UIButton *optionThreeButton;
@property (weak, nonatomic) IBOutlet UIButton *optionFourButton;

@property (weak, nonatomic) IBOutlet BEMCheckBox *optionOneBox;
@property (weak, nonatomic) IBOutlet BEMCheckBox *optionTwoBox;
@property (weak, nonatomic) IBOutlet BEMCheckBox *optionThreeBox;
@property (weak, nonatomic) IBOutlet BEMCheckBox *optionFourBox;

@property (weak, nonatomic) IBOutlet UILabel *optionOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *optionTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *optionThreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *optionFourLabel;

@property (weak, nonatomic) IBOutlet UILabel *optionOneSublabel;
@property (weak, nonatomic) IBOutlet UILabel *optionTwoSublabel;
@property (weak, nonatomic) IBOutlet UILabel *optionThreeSublabel;
@property (weak, nonatomic) IBOutlet UILabel *optionFourSublabel;

@property (weak, nonatomic) IBOutlet UIView *drawView;
@property (weak, nonatomic) IBOutlet UIImageView *faceImageView;
@property (weak, nonatomic) IBOutlet UIButton *userButton;

@property (strong, nonnull) CNPPopupController *popupController;

@property (assign, nonatomic) NSInteger timeLeft;
@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) NSArray *lineArray;
@property (assign, nonatomic) NSInteger currentLine;
@property (strong, nonatomic) NSMutableArray *curves;
@property (assign, nonatomic) NSInteger totalLength;

@property (assign, nonatomic) NSInteger faceIndex;
@property (assign, nonatomic) NSInteger optionIndex;
@property (strong, nonatomic) CAShapeLayer *currentLayer;

@property (strong, nonatomic) Guess *guess;

@end

@implementation QuizViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self resetTimer];
    self.faceIndex = 1;
    self.optionIndex = -1;
    self.userButton.layer.cornerRadius = 22.5;
    self.userButton.clipsToBounds= YES;
    
    if (self.profileImage)
    {
        [self.userButton setImage:self.profileImage forState:UIControlStateNormal];
    }
    
    [self loadGuess];
}

- (void)loadGuess
{
    [SVProgressHUD show];
    [[NetworkHelper sharedHelper] getGuessWithCompletion:^(Guess *guess, NSError *err) {
        if (!err && guess)
        {
            [SVProgressHUD dismiss];
            self.guess = guess;
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
    
    NSAttributedString *lineOne = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Observe how this masterpiece was created and see if you can figure out who is the subject within 30 seconds."]
                                                                  attributes:@{NSFontAttributeName : [UIFont fontWithName:@"SegoePrint" size:16],
                                                                               NSParagraphStyleAttributeName : paragraphStyle}];
    
    CNPPopupButton *button = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"SegoePrint" size:16];
    [button setTitle:@"Start!" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor colorWithRed:223/255.0 green:92/255.0 blue:53/255.0 alpha:1.0];
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
    
    self.popupController = [[CNPPopupController alloc] initWithContents:@[titleLabel, lineOneLabel, button]];
    self.popupController.theme = [CNPPopupTheme defaultTheme];
    self.popupController.theme.popupStyle = CNPPopupStyleCentered;
    self.popupController.delegate = self;
    [self.popupController presentPopupControllerAnimated:YES];
}

- (void)startGame
{
    [self drawLines];
    [self startAnimatingTimer];
}

- (void)finishQuiz
{
    [SVProgressHUD show];
    [[NetworkHelper sharedHelper] createGuessWithGuess:self.guess
                                                option:self.optionIndex
                                            completion:^(BOOL correct, NSDictionary *user, NSNumber *score, NSError *err)
     {
         if (score)
         {
             [self showResult:correct user:user score:score];
         }
         else
         {
             [SVProgressHUD showErrorWithStatus:@"Oops! Please try again later."];
             [self.navigationController popViewControllerAnimated:YES];
         }
     }];
}

- (void)showResult:(BOOL)correct
              user:(NSDictionary *)user
             score:(NSNumber *)score
{
    [SVProgressHUD dismiss];
    
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSInteger randomNumber = arc4random() % 3;
    NSInteger randomNumber2 = arc4random() % 10 + 1;
    NSString *text = @"";
    if (correct)
    {
        switch (randomNumber) {
            case 0:
                text = @"You have great intuition.";
                break;
            case 1:
                text = @"Your sense for arts is impeccable.";
                break;
            default:
                text = [NSString stringWithFormat:@"That was amazing! FYI, only %ld%% of people got that right.", randomNumber2];
                break;
        }
    }
    else
    {
        switch (randomNumber) {
            case 0:
                text = @"We'll try to give you something easier next time.";
                break;
            case 1:
                text = @"We couldn't have figured that one ourselves, to be honest.";
                break;
            default:
                text = @"Maybe you should draw a better one!";
                break;
        }
    }
    
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:correct?@"Correct!":@"Sorry..."
                                                                attributes:@{NSFontAttributeName : [UIFont fontWithName:@"SegoePrint" size:24],
                                                                             NSParagraphStyleAttributeName : paragraphStyle}];
    NSAttributedString *lineOne = [[NSAttributedString alloc] initWithString:text
                                                                  attributes:@{NSFontAttributeName : [UIFont fontWithName:@"SegoePrint" size:16],
                                                                               NSParagraphStyleAttributeName : paragraphStyle}];
    
    NSAttributedString *lineTwo = [[NSAttributedString alloc] initWithString: [[user objectForKey:@"firstName"] stringByAppendingFormat:@" %@", [user objectForKey:@"lastName"]]
                                                                  attributes:@{NSFontAttributeName :[UIFont fontWithName:@"SegoePrint" size:16],
                                                                               NSForegroundColorAttributeName : [UIColor blackColor],
                                                                               NSParagraphStyleAttributeName : paragraphStyle}];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView sd_setImageWithURL:[NSURL URLWithString:[serverPath stringByAppendingString:[user objectForKey:@"profileImage"]]]];
    [imageView setContentMode:UIViewContentModeScaleAspectFill];
    [imageView setFrame:CGRectMake(0, 0, 160, 160)];
    imageView.layer.cornerRadius = 80;
    imageView.clipsToBounds = YES;
    
    CNPPopupButton *button = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"SegoePrint" size:16];
    [button setTitle:@"Close" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor colorWithRed:223/255.0 green:92/255.0 blue:53/255.0 alpha:1.0];
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
    
    UILabel *lineTwoLabel = [[UILabel alloc] init];
    lineTwoLabel.numberOfLines = 0;
    lineTwoLabel.attributedText = lineTwo;
    
    self.popupController = [[CNPPopupController alloc] initWithContents:@[titleLabel, lineOneLabel, imageView, lineTwoLabel, button]];
    self.popupController.theme = [CNPPopupTheme defaultTheme];
    self.popupController.theme.popupStyle = CNPPopupStyleCentered;
    self.popupController.delegate = self;
    [self.popupController presentPopupControllerAnimated:YES];
}

- (void)updateData
{
    self.faceIndex = self.guess.graph.face.integerValue;
    self.lineArray = self.guess.graph.lines;
    
    NSDictionary *o1 = [self.guess.options objectAtIndex:0];
    self.optionOneSublabel.text = [o1 objectForKey:@"alias"];
    self.optionOneLabel.text = [[o1 objectForKey:@"firstName"] stringByAppendingFormat:@" %@", [o1 objectForKey:@"lastName"]];
    
    NSDictionary *o2 = [self.guess.options objectAtIndex:1];
    self.optionTwoSublabel.text = [o2 objectForKey:@"alias"];
    self.optionTwoLabel.text = [[o2 objectForKey:@"firstName"] stringByAppendingFormat:@" %@", [o2 objectForKey:@"lastName"]];
    
    NSDictionary *o3 = [self.guess.options objectAtIndex:2];
    self.optionThreeSublabel.text = [o3 objectForKey:@"alias"];
    self.optionThreeLabel.text = [[o3 objectForKey:@"firstName"] stringByAppendingFormat:@" %@", [o3 objectForKey:@"lastName"]];

    NSDictionary *o4 = [self.guess.options objectAtIndex:3];
    self.optionFourSublabel.text = [o4 objectForKey:@"alias"];
    self.optionFourLabel.text = [[o4 objectForKey:@"firstName"] stringByAppendingFormat:@" %@", [o4 objectForKey:@"lastName"]];

    [self resetTimer];
    [self.faceImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"face_%ld", (long)self.faceIndex]]];
}

- (void)drawLines
{
    self.curves = [NSMutableArray array];
    self.currentLine = 0;
    [self createCurves];
    [self drawWithLines];
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

- (void)timeout
{
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;

    NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"Timeout"
                                                                attributes:@{NSFontAttributeName : [UIFont fontWithName:@"SegoePrint" size:24],
                                                                             NSParagraphStyleAttributeName : paragraphStyle}];
    
    NSAttributedString *lineOne = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Sorry, your guess timed out."]
                                                                  attributes:@{NSFontAttributeName : [UIFont fontWithName:@"SegoePrint" size:16],
                                                                               NSParagraphStyleAttributeName : paragraphStyle}];
    
    CNPPopupButton *button = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"SegoePrint" size:16];
    [button setTitle:@"Close" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor colorWithRed:223/255.0 green:92/255.0 blue:53/255.0 alpha:1.0];
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
    
    self.popupController = [[CNPPopupController alloc] initWithContents:@[titleLabel, lineOneLabel, button]];
    self.popupController.theme = [CNPPopupTheme defaultTheme];
    self.popupController.theme.popupStyle = CNPPopupStyleCentered;
    self.popupController.delegate = self;
    [self.popupController presentPopupControllerAnimated:YES];
}

- (void)resetTimer
{
    self.timeLeft = 30;
}

- (void)startAnimatingTimer
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
    
    if (self.currentLayer)
    {
        [self resumeLayer:self.currentLayer];
    }
}

- (void)stopAnimatingTimer
{
    [self.timer invalidate];
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2 ];
    rotationAnimation.duration = 1;
    rotationAnimation.cumulative = YES;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    [self.timerImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
    if (self.currentLayer)
    {
        [self pauseLayer:self.currentLayer];
    }
}

- (IBAction)optionOneButtonClicked:(id)sender
{
    [self deselectAllButtons];
    [self.optionOneBox setOn:YES animated:YES];
    self.optionIndex = 0;
    
    [self optionChoosed];
}

- (IBAction)optionTwoButtonClicked:(id)sender
{
    [self deselectAllButtons];
    [self.optionTwoBox setOn:YES animated:YES];
    self.optionIndex = 1;
    
    [self optionChoosed];
}

- (IBAction)optionThreeButton:(id)sender
{
    [self deselectAllButtons];
    [self.optionThreeBox setOn:YES animated:YES];
    self.optionIndex = 2;
    
    [self optionChoosed];
}

- (IBAction)optionFourButton:(id)sender
{
    [self deselectAllButtons];
    [self.optionFourBox setOn:YES animated:YES];
    self.optionIndex = 3;
    
    [self optionChoosed];
}

- (void)deselectAllButtons
{
    [self.optionOneBox setOn:NO animated:YES];
    [self.optionTwoBox setOn:NO animated:YES];
    [self.optionThreeBox setOn:NO animated:YES];
    [self.optionFourBox setOn:NO animated:YES];
    self.optionIndex = -1;
}

- (void)optionChoosed
{
    [self stopAnimatingTimer];
    [self pauseLayer: self.currentLayer];
    
    NSDictionary *o4 = [self.guess.options objectAtIndex:self.optionIndex];
    NSString *name = [[o4 objectForKey:@"firstName"] stringByAppendingFormat:@" %@", [o4 objectForKey:@"lastName"]];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Confirmation"
                                                                             message:[NSString stringWithFormat:@"Are you sure this is %@'s face?", name]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"Confirm"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         [self finishQuiz];
                                                     }];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self deselectAllButtons];
                                                             [self startAnimatingTimer];
                                                         }];
    
    [alertController addAction:actionOk];
    [alertController addAction:actionCancel];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)createCurves
{
    CGFloat length = 0;
    for (int i=0; i<self.lineArray.count; i++)
    {
        Line *line = [self.lineArray objectAtIndex:i];
        UIBezierPath *path = [UIBezierPath bezierPath];
        CGPoint previous = CGPointZero;
        CGPoint current = CGPointZero;
        
        for (int i=0; i<line.points.count; i++)
        {
            NSString *string = [line.points objectAtIndex:i];
            CGPoint point = CGPointFromString(string);
            
            if (i==0)
            {
                current = point;
                [path moveToPoint:point];
            }
            
            else
            {
                previous = current;
                current = point;
                [path addQuadCurveToPoint:current controlPoint:previous];
            }
        }
        
        length += [path length];
        [self.curves addObject:path];
    }
    
    self.totalLength = length;
}

- (void)drawWithLines
{
    if (self.currentLine >= self.lineArray.count)
    {
        return;
    }
    
    Line *line = [self.lineArray objectAtIndex:self.currentLine];
    UIBezierPath *path = [self.curves objectAtIndex:self.currentLine];
    self.currentLine ++;

    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.frame = self.drawView.bounds;
    shapeLayer.path = path.CGPath;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.lineWidth = line.width.floatValue;
    shapeLayer.strokeColor = [UIColor colorWithCSS:line.color].CGColor;
    [self.drawView.layer addSublayer:shapeLayer];
    self.currentLayer = shapeLayer;
    
    shapeLayer.strokeStart = 0.0; // reset stroke start before animating
    CABasicAnimation* strokeAnim = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    strokeAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    strokeAnim.duration = ([path length]/self.totalLength) * 20; // duration of the animation
    strokeAnim.fromValue = @(0.0); // provide the start value for the animation, wrapped in an NSNumber literal.
    strokeAnim.toValue = @(1.0); // provide the end value for the animation, wrapped in an NSNumber literal.
    strokeAnim.delegate = self;
    [shapeLayer addAnimation:strokeAnim forKey:@"strokeAnim"];
}

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished
{
    [self drawWithLines];
}

-(void)pauseLayer:(CALayer*)layer
{
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
}

-(void)resumeLayer:(CALayer*)layer
{
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}

- (void)popupController:(CNPPopupController *)controller didDismissWithButtonTitle:(NSString *)title
{
    NSLog(@"Dismissed with button title: %@", title);
}

- (void)popupControllerDidPresent:(CNPPopupController *)controller
{
    NSLog(@"Popup controller presented.");
}


@end
