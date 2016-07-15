//
//  Card.h
//  marscards
//
//  Created by Christopher Cobar on 7/13/16.
//  Copyright © 2016 Chris_Cobar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Card : NSObject

@property (strong, nonatomic) NSString *suit;

@property (strong, nonatomic) NSString *name;

@property (nonatomic) int value;

@property (nonatomic) BOOL istraditional;

- (instancetype)init: (NSString *) suit
                Name: (NSString *) name
               Value: (int) value
         Traditional: (BOOL) isTraditional;


- (int) compareTo:(Card *)card;

- (NSString *) toString;

@end
