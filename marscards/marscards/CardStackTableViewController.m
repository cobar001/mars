//
//  CardStackTableViewController.m
//  marscards
//
//  Created by Christopher Cobar on 7/15/16.
//  Copyright © 2016 Chris_Cobar. All rights reserved.
//

#import "CardStackTableViewController.h"
#import "Card.h"

@interface CardStackTableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *table;

@end

@implementation CardStackTableViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self.content count] <= 0) {
        
        self.title = @"Empty stack";
        
    } else {
        
        self.title = @"Cards";
        
    }
    
}

#pragma mark - UITablView DataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
        return [self.content count];

}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    
    static NSString *cellId = @"cardCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    }
    
    cell.textLabel.text = [[self.content objectAtIndex:indexPath.row] toString];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    return cell;
    
}

    
@end
