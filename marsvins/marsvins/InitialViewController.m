//
//  ViewController.m
//  marsvins
//
//  Created by Christopher Cobar on 7/16/16.
//  Copyright © 2016 marslab. All rights reserved.
//

#import "InitialViewController.h"
#import "VinsViewController.h"
#import "AppDelegate.h"

@interface InitialViewController ()

@end

@implementation InitialViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupLeftSwipeLabel];
    [self setupRightSwipeLabel];

}

- (void)setupLeftSwipeLabel {
    
    UILabel *switchLabel = [[UILabel alloc] init];
    switchLabel.text = @"<- swipe left for 640x480 30 fps";
    switchLabel.numberOfLines = 2;
    switchLabel.textColor = [UIColor whiteColor];
    switchLabel.translatesAutoresizingMaskIntoConstraints = false;
    switchLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:switchLabel];
    
    [switchLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = true;
    [switchLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:80.0].active = true;
    [switchLabel.widthAnchor constraintEqualToAnchor:self.view.widthAnchor constant:-50.0].active = true;
    [switchLabel.heightAnchor constraintEqualToConstant:60].active = true;
    
}

- (void)setupRightSwipeLabel {
    
    UILabel *switchLabel = [[UILabel alloc] init];
    switchLabel.text = @"-> swipe right for 1280 720 ~240fps? collecting at 30fps";
    switchLabel.numberOfLines = 2;
    switchLabel.textColor = [UIColor whiteColor];
    switchLabel.translatesAutoresizingMaskIntoConstraints = false;
    switchLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:switchLabel];
    
    [switchLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = true;
    [switchLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:160.0].active = true;
    [switchLabel.widthAnchor constraintEqualToAnchor:self.view.widthAnchor constant:-50.0].active = true;
    [switchLabel.heightAnchor constraintEqualToConstant:60].active = true;
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    VinsViewController *vc = segue.destinationViewController;
    
    if ([[segue identifier] isEqualToString:@"toVins640"]) {
        
        vc.is640 = true;
        
    } else {
        
        vc.is640 = false;
        
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    //show navbar, if not already visible
    [[self navigationController] setNavigationBarHidden:NO animated:YES];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
