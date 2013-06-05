//
//  DEMainController.m
//  DEFileBrowserController
//
//  Created by Jeremy Flores on 6/4/13.
//  Copyright (c) 2013 Dream Engine Interactive, Inc. All rights reserved.
//
//  Copyright (c) 2013 Dream Engine Interactive, Inc. ( http://dreamengineinteractive.com )
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "DEMainController.h"

#import "DEFileBrowserController.h"

@interface DEMainController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end


@implementation DEMainController

-(void)viewDidLoad {
    [super viewDidLoad];

    [self.textView becomeFirstResponder];
}

-(IBAction)saveButtonTapped:(id)sender {
    DEFileBrowserController *controller = [DEFileBrowserController new];
    controller.canCreateFiles = YES;
    controller.canCreateFolders = YES;
    controller.canSelectFiles = NO;
    controller.canSelectFolders = NO;
    controller.canOverwriteFiles = YES;
    controller.fileCreationExtension = @"dat";

    controller.fileShouldBeCreatedBlock =
    ^(NSString *createdFilePath) {
        NSDictionary *fileRepresentation = @{
                                             @"text": self.textView.text,
                                             };

        [fileRepresentation writeToFile: createdFilePath
                             atomically: YES];

        [self.navigationController dismissViewControllerAnimated: YES
                                                      completion: ^{
                                                          
                                                      }];
    };

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];

    controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                      initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target: self
                                                      action: @selector(modalCancelButtonTapped)];

    [self.navigationController presentViewController: navController
                                            animated: YES
                                          completion: ^{
                                              
     }];
}

-(IBAction)loadButtonTapped:(id)sender {
    DEFileBrowserController *controller = [DEFileBrowserController new];
    controller.canCreateFiles = NO;
    controller.canCreateFolders = NO;
    controller.canSelectFiles = YES;
    controller.canSelectFolders = NO;

    controller.fileSelectedBlock = ^(NSString *selectedFilePath) {
        NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:selectedFilePath];
        self.textView.text = dictionary[@"text"];

        [self.navigationController dismissViewControllerAnimated:YES
                                                      completion:^{
                                                      }];
    };

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                   initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                   target: self
                                                   action: @selector(modalCancelButtonTapped)];
    
    [self.navigationController presentViewController: navController
                                            animated: YES
                                          completion: ^{
                                              
                                          }];
}

-(void)modalCancelButtonTapped {
    [self.navigationController dismissViewControllerAnimated: YES
                                                  completion: ^{
                                                      
                                                  }];
}

@end
