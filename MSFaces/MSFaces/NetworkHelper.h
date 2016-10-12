//
//  NetworkHelper.h
//  MSFaces
//
//  Created by Lee on 10/7/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Draw.h"
#import "Guess.h"
#import "User.h"
#import "Graph.h"

static NSString *serverPath = @"http://10.168.160.165:1337";

@interface NetworkHelper : NSObject

+(NetworkHelper *)sharedHelper;

#pragma User
- (void)getUserWithCompletion:(void(^)(User *user, NSError *err))completion;
- (void)createUserWithAlias:(NSString *)alias
               profileImage:(UIImage *)image
                 completion:(void(^)(BOOL success, NSError *err))completion;

#pragma Draw
- (void)getDrawWithCompletion:(void(^)(Draw *draw, NSError *err))completion;
- (void)createDrawWithDraw:(Draw *)draw
                     graph:(Graph *)graph
                  completion:(void(^)(NSNumber *score, NSError *err))completion;

#pragma Guess
- (void)getGuessWithCompletion:(void(^)(Guess *guess, NSError *err))completion;
- (void)createGuessWithGuess:(Guess *)guess
                      option:(NSInteger)option
                   completion:(void(^)(BOOL correct, NSDictionary *user, NSNumber *score, NSError *err))completion;

#pragma LeaderBoard
- (void)getLeaderBoardWithCompletion:(void(^)(NSArray *drawUsers, NSArray *guessUsers, NSInteger drawRank, NSInteger guessRank, NSError *error))completion;;

#pragma Collection
- (void)getCollectionWithCompletion:(void(^)(NSArray *users, NSInteger revealed, NSInteger total, NSError *error))completion;
- (void)postCollection:(NSDictionary *)params
            completion:(void(^)(BOOL success, NSError *err))completion;

@end
