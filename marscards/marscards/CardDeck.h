//
//  CardDeck.h
//  marscards
//
//  Created by Christopher Cobar on 7/13/16.
//  Copyright © 2016 Chris_Cobar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Card.h"

@interface CardDeck : NSObject

@property (nonatomic, strong, readonly) NSMutableArray *cards; //of card

@property (nonatomic, strong, readonly) NSArray *suits;

@property (nonatomic, readonly) NSDictionary *faceValue;

@property (nonatomic, readonly)BOOL isTraditional;

- (instancetype)init: (BOOL) isTraditional;

- (BOOL)isEmpty;

- (Card *)pop;

- (void)push: (Card *) card;

- (void)shuffle;

- (void)sort;

@end
