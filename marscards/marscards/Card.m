//
//  Card.m
//  marscards
//
//  Created by Christopher Cobar on 7/13/16.
//  Copyright © 2016 Chris_Cobar. All rights reserved.
//

#import "Card.h"

@implementation Card

- (instancetype)init: (NSString *) suit
                Name: (NSString *) name
               Value: (int) value
         Traditional: (BOOL) isTraditional
{
    self = [super init];
    
    if (self) {
        
        self.suit = suit;
        self.name = name;
        self.value = value;
        self.istraditional = isTraditional;
        
    } else {
        
        self = nil;
        
    }
    
    return self;
    
}

- (int)compareTo:(Card *)card
{
    
    if ([self value] > card.value) {
        return 1;
    } else if ([self value] < card.value) {
        return -1;
    } else {
        return 0;
    }
    
}

- (NSString *) toString
{
    
    if ([self istraditional]) {
        return [NSString stringWithFormat:@"%@ of %@", [self name], [self suit]];
    } else {
        return [NSString stringWithFormat:@"Card %@", [self name]];
    }
    
}

@end
