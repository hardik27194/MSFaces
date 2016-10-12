//
//  ViewController.m
//  MSFaces
//
//  Created by Lee on 10/3/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import "HomeViewController.h"
#import "DrawViewController.h"
#import "QuizViewController.h"
#import "RankViewController.h"
#import "ProfileViewController.h"
#import "User.h"
#import "NetworkHelper.h"
#import "SVProgressHUD.h"

@interface HomeViewController () <UINavigationControllerDelegate,UIImagePickerControllerDelegate, UITextFieldDelegate>

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
    self.userButton.layer.cornerRadius = 22.5;
    self.userButton.clipsToBounds = YES;
    [self.userButton setImage:[User sharedUser].profileImage forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self showQuestions];
}

- (void)showQuestions
{
    if (![User sharedUser].alias ||
        [[User sharedUser].alias isEqualToString:@""])
    {
        [self askAlias];
    }
    else if (![User sharedUser].profileImage)
    {
        [self takePhoto];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)askAlias
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alias"
                                                                             message:@"Please input your Microsoft Alias"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"Done"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action)
                               {
                                   [self showQuestions];
                               }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.placeholder = @"Alias";
         textField.delegate = self;
         [textField becomeFirstResponder];
     }];
    
    [alertController addAction:actionOk];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if ([textField.text isEqualToString:@""] || textField.text == nil)
    {
        return NO;
    }
    
    [User sharedUser].alias = textField.text;
    return YES;
}

- (void)takePhoto
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Take Picture"
                                                                             message:@"Please take a selfie before starting the game."
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"Ok"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action)
                               {
                                   UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                                   picker.delegate = self;
                                   picker.allowsEditing = YES;
                                   picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                                   picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
                                   picker.showsCameraControls = YES;
                                   [self presentViewController:picker animated:YES completion:^
                                    {
                                        
                                    }];
                               }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction *action)
                               {
                                   [self showQuestions];
                               }];
    
    [alertController addAction:actionOk];
    [alertController addAction:actionCancel];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    [[User sharedUser] setProfileImage:chosenImage];
    [self.userButton setImage:[User sharedUser].profileImage forState:UIControlStateNormal];
    [picker dismissViewControllerAnimated:YES completion:^{
        [SVProgressHUD showWithStatus:@"Creating..."];
        [[NetworkHelper sharedHelper] createUserWithAlias:[User sharedUser].alias
                                             profileImage:[User sharedUser].profileImage
                                               completion:^(BOOL success, NSError *err) {
                                                   [SVProgressHUD showSuccessWithStatus:@"Done! Enjoy your games :)"];
                                               }];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self showQuestions];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Home2Draw"])
    {
        DrawViewController *drawVC = segue.destinationViewController;
        drawVC.profileImage = [User sharedUser].profileImage;
    }
    else if ([segue.identifier isEqualToString:@"Home2Quiz"])
    {
        QuizViewController *drawVC = segue.destinationViewController;
        drawVC.profileImage = [User sharedUser].profileImage;
    }
    else if ([segue.identifier isEqualToString:@"Home2Rank"])
    {
        RankViewController *drawVC = segue.destinationViewController;
        drawVC.profileImage = [User sharedUser].profileImage;
    }
    else if ([segue.identifier isEqualToString:@"Home2Profile"])
    {
        ProfileViewController *drawVC = segue.destinationViewController;
        drawVC.profileImage = [User sharedUser].profileImage;
    }
}

@end
