//
//  ViewController.m
//  marscards
//
//  Created by Christopher Cobar on 7/13/16.
//  Copyright © 2016 Chris_Cobar. All rights reserved.
//

#import "HomeViewController.h"
#import "CardDeck.h"
#import "Card.h"
#import "CardStackTableViewController.h"

@interface HomeViewController ()

@property (weak, nonatomic) IBOutlet UILabel *actionLabelOutlet;

@property (nonatomic) BOOL isTraditional;

@property (nonatomic) CardDeck *cd;

@property (nonatomic) NSMutableArray *hand;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    
    self.actionLabelOutlet.text = @"";
    
}

-(void)viewWillAppear:(BOOL)animated {
    
    self.actionLabelOutlet.text = @"";
    
}


- (IBAction)touchButtonZero:(UIButton *)sender {
    
     UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Hello" message:@"Please select deck type" preferredStyle:UIAlertControllerStyleActionSheet];
    
     UIAlertAction *traditionalDeck = [UIAlertAction actionWithTitle:@"Traditional" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
         
         CardDeck *traditionalDeck = [[CardDeck alloc] init:true];
         self.cd = traditionalDeck;
         self.isTraditional = true;
         self.hand = [[NSMutableArray alloc] init];
         self.actionLabelOutlet.text = @"deck created";
         
     }];
    
    UIAlertAction *numericalDeck = [UIAlertAction actionWithTitle:@"Numerical" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        CardDeck *numericalDeck = [[CardDeck alloc] init:false];
        self.cd = numericalDeck;
        self.isTraditional = false;
        self.hand = [[NSMutableArray alloc] init];
        self.actionLabelOutlet.text = @"deck created";
        
    }];
    
    [alertController addAction:traditionalDeck];
    [alertController addAction:numericalDeck];
    
    [self presentViewController:alertController animated:YES completion:nil];

}

- (IBAction)touchButtonOne
{
    
    if ([[self.cd cards] count] > 0) {
        
        Card *drawn = [self.cd pop];
        self.actionLabelOutlet.text = [NSString stringWithFormat:@"%@ drawn", [drawn toString]];
        [self.hand addObject:drawn];

    } else {
        
        self.actionLabelOutlet.text = @"no deck to draw from";
        
    }
    
}

- (IBAction)touchButtonTwo
{
    
    if ([self.hand count] > 0) {
        
        Card *take = [self.hand lastObject];
        self.actionLabelOutlet.text = [NSString stringWithFormat:@"%@ removed from hand, placed on deck", [take toString]];
        [self.hand removeLastObject];
        [self.cd push:take];
        
    } else {
        
        self.actionLabelOutlet.text = @"no cards in hand";
        
    }
    
}

- (IBAction)touchButtonThree
{
    
    if ([[self.cd cards] count] > 0) {
        
        [self.cd shuffle];
        self.actionLabelOutlet.text = @"Deck shuffled";
        
    } else {
        
        self.actionLabelOutlet.text = @"no deck created";
        
    }
    
}

- (IBAction)touchButtonFour
{
    
    if ([[self.cd cards] count] > 0) {
        
        [self.cd sort];
        self.actionLabelOutlet.text = @"Deck sorted";
        
    } else {
        
        self.actionLabelOutlet.text = @"no deck created";
        
    }
    
}

- (IBAction)touchButtonFive
{
    
    if ([[self.cd cards] count] <= 0) {
        
        self.actionLabelOutlet.text = @"";
        
    }
    
}

- (IBAction)touchButtonSix
{
    
    if ([[self.cd cards] count] <= 0) {
        
        self.actionLabelOutlet.text = @"";
        
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([[segue identifier] isEqualToString:@"buttonSixSegue"]) {
        
        CardStackTableViewController *csvc = [segue destinationViewController];
        csvc.content = [self.cd cards];
        
    } else if ([[segue identifier] isEqualToString:@"buttonFiveSegue"]) {
        
        CardStackTableViewController *csvc = [segue destinationViewController];
        csvc.content = self.hand;
        
    } else {
        
        NSLog(@"missed case");
        
    }
    
}

@end
