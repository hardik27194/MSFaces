//
//  NetworkHelper.m
//  MSFaces
//
//  Created by Lee on 10/7/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import "NetworkHelper.h"
#import "AFNetworking.h"
#import "SDImageCache.h"
#import "UIImageView+WebCache.h"


@implementation NetworkHelper
NetworkHelper *_sharedHelper;

+(NetworkHelper *)sharedHelper
{
    if (!_sharedHelper)
    {
        _sharedHelper = [[NetworkHelper alloc] init];
    }
    
    return _sharedHelper;
}

#pragma User

- (void)getUserWithCompletion:(void(^)(User *user, NSError *err))completion
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *path = [serverPath stringByAppendingFormat:@"/users/%@", [User sharedUser].alias];
    
    [manager GET:path
      parameters:@{@"u":[User sharedUser].alias}
        progress:nil
         success:^(NSURLSessionTask *task, id responseObject)
     {
         NSDictionary *userDict = (NSDictionary *)responseObject;
         if ([[userDict objectForKey:@"status"] isEqualToString:@"OK"])
         {
             NSDictionary *result = [userDict objectForKey:@"result"];
             NSString *imageUrl = [result objectForKey:@"profileImage"];
             [[User sharedUser] setFirstName:[result objectForKey:@"firstName"]];
             [[User sharedUser] setLastName:[result objectForKey:@"lastName"]];
             
             AFHTTPSessionManager *imageManager = [AFHTTPSessionManager manager];
             [imageManager GET:[serverPath stringByAppendingString:imageUrl]
                    parameters:nil
                      progress:nil
                       success:^(NSURLSessionDataTask *task, id imgResponse)
             {
                 UIImage *image = [UIImage imageWithData:imgResponse];
                 [[User sharedUser] setProfileImage:image];
                 completion([User sharedUser], nil);
             }
                       failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
             {
                 completion(nil, error);
             }];
             
         }
         else
         {
             completion(nil, nil);
         }
         
     }
         failure:^(NSURLSessionTask *operation, NSError *error)
     {
         completion(nil, error);
     }];
}

- (void)createUserWithAlias:(NSString *)alias
               profileImage:(UIImage *)image
                 completion:(void(^)(BOOL success, NSError *err))completion;
{
    NSError *error;
    NSData *imageData = UIImageJPEGRepresentation([User sharedUser].profileImage, 0.1);
    NSString *path = [serverPath stringByAppendingFormat:@"/users"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"alias":[User sharedUser].alias,
                                                                 @"profileImage":@{@"format":@"jpg",
                                                                                   @"data":[imageData base64Encoding]}}
                                                       options:0
                                                         error:&error];
    NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST"
                                                                             URLString:path
                                                                            parameters:nil
                                                                                 error:nil];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setHTTPBody:jsonData];
    [[manager dataTaskWithRequest:req
                completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error)
      {
          if (!error)
          {
              completion(YES, nil);
          }
          else
          {
              completion(NO, error);
          }
      }] resume];
}

#pragma Draw

- (void)getDrawWithCompletion:(void(^)(Draw *draw, NSError *err))completion
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *path = [serverPath stringByAppendingFormat:@"/draw"];
    [manager GET:path
      parameters:@{@"u":[User sharedUser].alias}
        progress:nil
         success:^(NSURLSessionTask *task, id responseObject)
     {
         NSDictionary *response = (NSDictionary *)responseObject;
         if ([[response objectForKey:@"status"] isEqualToString:@"OK"])
         {
             NSDictionary *drawDict = [response objectForKey:@"result"];
             Draw *draw = [[Draw alloc] init];
             draw.identifier = [drawDict objectForKey:@"id"];
             
             NSString *imageUrl = [serverPath stringByAppendingString:[drawDict objectForKey:@"path"]];
             dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
             dispatch_async(queue, ^(void) {
                 NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
                 UIImage* image = [[UIImage alloc] initWithData:imageData];
                 dispatch_async(dispatch_get_main_queue(), ^{
                     if (image) {
                         draw.image = image;
                         completion(draw, nil);
                     }
                     else
                     {
                         completion(nil, nil);
                     }
                 });
                 
             });
         }
         else
         {
             completion(nil, nil);
         }
     }
         failure:^(NSURLSessionTask *operation, NSError *error)
     {
         completion(nil, error);
     }];
}
- (void)createDrawWithDraw:(Draw *)draw
                     graph:(Graph *)graph
                completion:(void(^)(NSNumber *score, NSError *err))completion
{
    NSError *error;
    NSString *path = [serverPath stringByAppendingFormat:@"/draw/%@?u=%@", draw.identifier, [User sharedUser].alias];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"data":[graph string], @"faceType":@(1)} options:0 error:&error];
    
    NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:path parameters:nil error:nil];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [req setHTTPBody:jsonData];
    
    [[manager dataTaskWithRequest:req completionHandler:^(NSURLResponse * _Nonnull response, id _Nullable responseObject, NSError * _Nullable error)
      {
          NSDictionary *res = (NSDictionary *)responseObject;
          if ([[res objectForKey:@"status"] isEqualToString:@"OK"])
          {
              NSDictionary *result = [res objectForKey:@"result"];
              NSNumber *score = [result objectForKey:@"score"];
              completion(score, nil);
          }
          else
          {
              completion(nil, nil);
          }
    }] resume];
}

#pragma Guess

- (void)getGuessWithCompletion:(void(^)(Guess *guess, NSError *err))completion
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *path = [serverPath stringByAppendingFormat:@"/guess?u=%@", [User sharedUser].alias];
    [manager GET:path
      parameters:nil
        progress:nil
         success:^(NSURLSessionTask *task, id responseObject)
     {
         NSDictionary *response = (NSDictionary *)responseObject;
         if ([[response objectForKey:@"status"] isEqualToString:@"OK"])
         {
             NSDictionary *guessDict = [response objectForKey:@"result"];
             Guess *guess = [[Guess alloc] init];
             guess.identifier = [guessDict objectForKey:@"sessionId"];
             guess.graph = [Graph createFromString:[[guessDict objectForKey:@"drawing"] objectForKey:@"data"]];
             guess.options = [guessDict objectForKey:@"choices"];
             completion(guess, nil);
         }
         else
         {
            completion(nil, nil);
         }
     }
         failure:^(NSURLSessionTask *operation, NSError *error)
     {
         completion(nil, error);
     }];
}
- (void)createGuessWithGuess:(Guess *)guess
                      option:(NSInteger)option
                   completion:(void(^)(BOOL correct, NSDictionary *user, NSNumber *score, NSError *err))completion;
{
    
    NSError *error;
    NSString *path = [serverPath stringByAppendingFormat:@"/guess/%@?u=%@", guess.identifier, [User sharedUser].alias];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"choice":@(option)} options:0 error:&error];
    NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:path parameters:nil error:nil];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setHTTPBody:jsonData];
    
    [[manager dataTaskWithRequest:req completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error)
      {
          NSDictionary *res = (NSDictionary *)responseObject;
          if ([[res objectForKey:@"status"] isEqualToString:@"OK"])
          {
              NSDictionary *result = [res objectForKey:@"result"];
              NSNumber *score = [result objectForKey:@"score"];
              NSDictionary *user = [result objectForKey:@"rightUser"];
              NSNumber *correct = [result objectForKey:@"isRightAnswer"];
              completion(correct.boolValue, user, score, nil);
          }
          else
          {
              completion(NO, nil, nil, nil);
          }
      }] resume];
}

#pragma LeaderBoard

- (void)getLeaderBoardWithCompletion:(void(^)(NSArray *drawUsers, NSArray *guessUsers, NSInteger drawRank, NSInteger guessRank, NSError *error))completion
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *path = [serverPath stringByAppendingFormat:@"/leaderboard"];
    [manager GET:path
      parameters:@{@"u":[User sharedUser].alias}
        progress:nil
         success:^(NSURLSessionTask *task, id responseObject)
     {
         NSDictionary *response = (NSDictionary *)responseObject;
         if ([[response objectForKey:@"status"] isEqualToString:@"OK"])
         {
             NSDictionary *result = [response objectForKey:@"result"];
             NSArray *drawArray = [result objectForKey:@"draw"];
             NSArray *guessArray = [result objectForKey:@"guess"];
             NSDictionary *rankings = [result objectForKey:@"myRankings"];
             completion(drawArray,
                        guessArray,
                        [[rankings objectForKey:@"draw"] integerValue],
                        [[rankings objectForKey:@"guess"] integerValue],
                        nil);
         }
         else
         {
             completion(nil, nil, 0, 0, nil);
         }
     }
         failure:^(NSURLSessionTask *operation, NSError *error)
     {
         completion(nil, nil, 0, 0, error);
     }];
}

#pragma Collection

- (void)getCollectionWithCompletion:(void(^)(NSArray *users, NSInteger revealed, NSInteger total, NSError *error))completion
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *path = [serverPath stringByAppendingFormat:@"/collection"];
    [manager GET:path
      parameters:@{@"u":[User sharedUser].alias, @"limit":@(10000), @"offset":@(0)}
        progress:nil
         success:^(NSURLSessionTask *task, id responseObject)
     {
         NSDictionary *response = (NSDictionary *)responseObject;
         if ([[response objectForKey:@"status"] isEqualToString:@"OK"])
         {
             NSDictionary *result = [response objectForKey:@"result"];
             NSArray *userArray = [result objectForKey:@"users"];
             NSNumber *re = [result objectForKey:@"revealed"];
             NSNumber *to = [result objectForKey:@"total"];
             completion(userArray, re.integerValue, to.integerValue,nil);
         }
         else
         {
             completion(nil, 0, 0, nil);
         }
     }
         failure:^(NSURLSessionTask *operation, NSError *error)
     {
         completion(nil, 0, 0, error);
     }];
}
- (void)postCollection:(NSDictionary *)params
            completion:(void(^)(BOOL success, NSError *err))completion;
{
    
}

@end
