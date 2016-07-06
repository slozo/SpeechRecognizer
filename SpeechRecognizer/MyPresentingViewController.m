//
//  MyPresentingViewController.m
//  SpeechRecognizer
//
//  Created by Mateusz Szlosek on 28.06.2016.
//  Copyright © 2016 slozo. All rights reserved.
//

#import "MyPresentingViewController.h"
#import "ViewController.h"


@interface MyPresentingViewController()
@property (weak, nonatomic) IBOutlet UITextView *myTextView;
@end

@implementation MyPresentingViewController


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    NSString *identifier = segue.identifier;
    if ([identifier isEqualToString:@"popover"]) {
        UIViewController *dvc = segue.destinationViewController;
        if ([dvc isKindOfClass:[ViewController class]]) {
            ((ViewController *)dvc).destinationTextView = self.myTextView;
        }
        
        UIPopoverPresentationController *ppc = dvc.popoverPresentationController;
        if (ppc) {
            ppc.delegate = self;
        }
    }
}
- (IBAction)presentPopover:(id)sender {
    [self performSegueWithIdentifier:@"popover" sender:self];
}
- (IBAction)dismissPopover:(id)sender {
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    
    return UIModalPresentationNone;
}

@end
