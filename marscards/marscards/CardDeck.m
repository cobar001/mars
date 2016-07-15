//
//  CardDeck.m
//  marscards
//
//  Created by Christopher Cobar on 7/13/16.
//  Copyright © 2016 Chris_Cobar. All rights reserved.
//

#import "CardDeck.h"
#import "Card.h"

@interface CardDeck()

@property (nonatomic, readwrite) NSMutableArray *cards;

@property (nonatomic, readwrite) NSDictionary *faceValue;

@property (nonatomic, strong, readwrite) NSArray *suits;

@property (nonatomic, readwrite)BOOL isTraditional;

@end

@implementation CardDeck

- (instancetype)init: (BOOL) isTraditional
{
    
    self = [super init];
    
    if (self)
    {
        self.isTraditional = isTraditional;
        self.cards = [[NSMutableArray alloc] init];
        if (self.isTraditional)
        {
            self.suits = @[@"Hearts", @"Clubs", @"Diamonds", @"Spades"];
            self.faceValue = @{[NSNumber numberWithInt:2] : @"2", [NSNumber numberWithInt:3] : @"3",
                           [NSNumber numberWithInt:4] : @"4", [NSNumber numberWithInt:5] : @"5",
                           [NSNumber numberWithInt:6] : @"6", [NSNumber numberWithInt:7] : @"7",
                           [NSNumber numberWithInt:8] : @"8", [NSNumber numberWithInt:9] : @"9",
                           [NSNumber numberWithInt:10] : @"10", [NSNumber numberWithInt:11] : @"Jack",
                           [NSNumber numberWithInt:12] : @"Queen", [NSNumber numberWithInt:13] : @"King",
                           [NSNumber numberWithInt:14] : @"Ace"};
    
            for (NSString *suit in self.suits)
            { //make TRADITIONAL deck
            
                int i = 2;
                while (i < 15)
                {
                
                    Card *c = [[Card alloc] init:suit Name:[self.faceValue objectForKey:[NSNumber numberWithInt:i]] Value:i Traditional:true];
                    [self.cards addObject:c];
                    i += 1;
                
                }
                
            }
        
        
        } else
        {
            
            self.suits = nil;
            self.faceValue = nil;
            for (int i = 0; i < 60; i++)
            { //make NUMERICAL deck
            
                Card *c = [[Card alloc] init:nil Name:[NSString stringWithFormat:@"%d", i] Value:i Traditional:false];
                [self.cards addObject:c];
        
            }
        
        }
        
    } else
    {
        
        self = nil;
        
    }
    
    return self;
    
}

- (BOOL)isEmpty
{
    
    if (self.cards) {
        
        return true;
        
    } else {
        
        return false;
        
    }
    
}

- (Card *)pop
{
    
    if (self.cards) {
        
        Card *retCard = [[Card alloc] init];
        retCard = [self.cards lastObject];
        [self.cards removeLastObject];
        
        return retCard;
        
    } else {
        
        return nil;
        
    }
    
}

- (void)push:(Card *)card
{
    
    [self.cards addObject:card];
    
}

- (void)shuffle
{
    
    int index;
    int count = (int)[self.cards count];
    
    if (count > 0) {
        
        for (int i = count - 1; i > 0; i--) {
            
            index = (arc4random() % (i + 1));
            [self.cards exchangeObjectAtIndex:i withObjectAtIndex:index];
            
        }
        
    }
    
}

- (void)sort
{

    Card *tempCard = [[Card alloc] init];
    NSMutableArray *retArray = [[NSMutableArray alloc] init];
    
    if (self.isTraditional)
    {
        
        for (NSString *suit in self.suits)
        { //for each suit
            
            NSMutableArray *tempArray = [[NSMutableArray alloc] init];
            
            for (Card *c in self.cards)
            { //group individual suit
                
                if ([[c suit] isEqualToString:suit])
                {
                    
                    [tempArray addObject:c];
                    
                }
                
            }
            
            for (int i = 1; i < (int)[tempArray count]; i++)
            {
                
                for (int j = i; j > 0; j--)
                {
                    
                    if ([[tempArray objectAtIndex:j] compareTo:tempArray[j - 1]] < 1)
                    {
                        
                        tempCard = [tempArray objectAtIndex:j];
                        [tempArray exchangeObjectAtIndex:j withObjectAtIndex:j - 1];
                        [tempArray exchangeObjectAtIndex:j - 1 withObjectAtIndex:[tempArray indexOfObject:tempCard]];
                        
                    }
                    
                }
                
            }
            
            for (Card *tc in tempArray)
            {
                
                [retArray addObject:tc];
                
            }
            
        }
        
        self.cards = retArray;
        
    } else if (!self.isTraditional) {
        
        for (int i = 1; i < (int)[self.cards count]; i++) {
            
            for (int j = i; j > 0; j--) {
                
                if ([[self.cards objectAtIndex:j] compareTo:self.cards[j - 1]] < 1) {
                    
                    tempCard = [self.cards objectAtIndex:j];
                    [self.cards exchangeObjectAtIndex:j withObjectAtIndex:j - 1];
                    [self.cards exchangeObjectAtIndex:j - 1 withObjectAtIndex:[self.cards indexOfObject:tempCard]];
                    
                }
                
            }
            
        }
        
    }
    
}


@end
