//
//  MSGSRequestHelper.m
//  ENSSample
//
//  Created by Peter Verhage on 22-01-14.
//
//

#import "MSGSRequestHelper.h"
#import "MSGSRequestHelper-Protected.h"

@interface MSGSRequestHelper ()

@property (nonatomic, strong, readwrite) MSGSClient *client;
@property (nonatomic, copy) NSString *basePath;

@end

@implementation MSGSRequestHelper

- (id)initWithClient:(MSGSClient *)client basePath:(NSString *)basePath {
    self = [super init];
    if (self != nil) {
        self.client = client;
        self.basePath = basePath;
    }
    
    return self;
}

- (NSOperation *)fetchSubscriptionWithChannelCode:(NSString *)channelCode
                                          success:(void (^)(MSGSSubscription *subscription))success
                                          failure:(void (^)(NSError *error))failure {
    return [self getPath:[NSString stringWithFormat:@"subscriptions/%@", channelCode]
              parameters:nil
                 success:^(id data) {
                     success([[MSGSSubscription alloc] initWithDictionary:data]);
                 } failure:failure];
}

- (NSOperation *)fetchSubscriptionsWithLimit:(NSNumber *)limit
                                      offset:(NSNumber *)offset
                                        sort:(NSArray *)sort
                                     success:(void (^)(NSArray *subscriptions, BOOL hasMore))success
                                     failure:(void (^)(NSError *error))failure {
    return [self fetchSubscriptionsWithChannelCodes:nil tags:nil limit:limit offset:offset sort:sort success:success failure:failure];
}

- (NSOperation *)fetchSubscriptionsWithChannelCodes:(NSSet *)channelCodes
                                              limit:(NSNumber *)limit
                                             offset:(NSNumber *)offset
                                               sort:(NSArray *)sort
                                            success:(void (^)(NSArray *subscriptions, BOOL hasMore))success
                                            failure:(void (^)(NSError *error))failure {
    return [self fetchSubscriptionsWithChannelCodes:channelCodes tags:nil limit:limit offset:offset sort:sort success:success failure:failure];
}

- (NSOperation *)fetchSubscriptionsWithTags:(NSSet *)tags
                             limit:(NSNumber *)limit
                            offset:(NSNumber *)offset
                              sort:(NSArray *)sort
                           success:(void (^)(NSArray *subscriptions, BOOL hasMore))success
                           failure:(void (^)(NSError *error))failure {
    return [self fetchSubscriptionsWithChannelCodes:nil tags:tags limit:limit offset:offset sort:sort success:success failure:failure];
}

- (NSOperation *)fetchSubscriptionsWithChannelCodes:(NSSet *)channelCodes
                                               tags:(NSSet *)tags
                                              limit:(NSNumber *)limit
                                             offset:(NSNumber *)offset
                                               sort:(NSArray *)sort
                                            success:(void (^)(NSArray *subscriptions, BOOL hasMore))success
                                            failure:(void (^)(NSError *error))failure {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    if (channelCodes != nil) {
        [params setObject:[[channelCodes allObjects] componentsJoinedByString:@","] forKey:@"channelCodes"];
    }
    
    if (tags != nil) {
        [params setObject:[[tags allObjects] componentsJoinedByString:@","] forKey:@"tags"];
    }
    
    if (limit != nil) {
        [params setObject:limit forKey:@"limit"];
        [params setObject:offset != nil ? offset : @(0) forKey:@"offset"];
    }

    if (sort != nil) {
        NSMutableArray *sortStrings = [[NSMutableArray alloc] init];
        
        for (NSNumber *value in sort) {
            switch ([value integerValue]) {
                case MSGSSubscriptionSortCreatedAtAsc:
                    [sortStrings addObject:@"createdAt ASC"];
                    break;
                case MSGSSubscriptionSortCreatedAtDesc:
                    [sortStrings addObject:@"createdAt DESC"];
                    break;
                case MSGSSubscriptionSortChannelCreatedAtAsc:
                    [sortStrings addObject:@"channel.createdAt ASC"];
                    break;
                case MSGSSubscriptionSortChannelCreatedAtDesc:
                    [sortStrings addObject:@"channel.createdAt DESC"];
                    break;
                case MSGSSubscriptionSortChannelUpdatedAtAsc:
                    [sortStrings addObject:@"channel.updatedAt ASC"];
                    break;
                case MSGSSubscriptionSortChannelUpdatedAtDesc:
                    [sortStrings addObject:@"channel.updatedAt DESC"];
                    break;
            }
        }

        [params setObject:[sortStrings componentsJoinedByString:@","] forKey:@"sort"];
    }
    
    return [self getPath:@"subscriptions"
              parameters:params
                 success:^(id data) {
                     NSMutableArray *items = [[NSMutableArray alloc] init];
                     for (id itemData in [data valueForKey:@"items"]) {
                         [items addObject:[[MSGSSubscription alloc] initWithDictionary:itemData]];
                     }
              
                     BOOL hasMore = NO;
                     if (limit != nil) {
                         hasMore = (offset != nil ? [offset integerValue] : 0) + [items count] < [[data objectForKey:@"total"] integerValue];
                     }
              
                     success(items, hasMore);
                 } failure:failure];
}


- (NSOperation *)countSubscriptionsWithTags:(NSSet *)tags
                                    success:(void (^)(NSInteger count))success
                                    failure:(void (^)(NSError *error))failure {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

    if (tags != nil) {
        [params setObject:[[tags allObjects] componentsJoinedByString:@","] forKey:@"tags"];
    }
    [params setObject:@0 forKey:@"limit"];
    [params setObject:@0 forKey:@"offset"];

    return [self getPath:@"subscriptions"
              parameters:params
                 success:^(id data) {
                     NSInteger count = [[data objectForKey:@"total"] integerValue];
                     success(count);
                 } failure:failure];
}


- (NSOperation *)subscribeWithChannelCode:(NSString *)channelCode
                                  success:(void (^)(MSGSSubscription *subscription))success
                                  failure:(void (^)(NSError *error))failure {
    return [self postPath:@"subscriptions"
               parameters:@{ @"channelCode": channelCode }
                  success:^(id data) {
                      if (success != nil) {
                          success([[MSGSSubscription alloc] initWithDictionary:data]);
                      }
                  } failure:failure];
}

- (NSOperation *)unsubscribeWithChannelCode:(NSString *)channelCode
                                    success:(void (^)())success
                                    failure:(void (^)(NSError *error))failure {
    return [self deletePath:[NSString stringWithFormat:@"subscriptions/%@", channelCode]
                 parameters:nil
                    success:^(id data) {
                        if (success != nil) {
                            success();
                        }
                    } failure:failure];
}

- (NSOperation *)getPath:(NSString *)path
              parameters:(NSDictionary *)params
                 success:(void (^)(id data))success
                 failure:(void (^)(NSError *error))failure {
        path = path == nil ? self.basePath : [NSString stringWithFormat:@"%@/%@", self.basePath, path];
    return [self.client getPath:path parameters:params success:success failure:failure];
}

- (NSOperation *)postPath:(NSString *)path
               parameters:(NSDictionary *)params
                  success:(void (^)(id data))success
                  failure:(void (^)(NSError *error))failure {
    path = path == nil ? self.basePath : [NSString stringWithFormat:@"%@/%@", self.basePath, path];
    return [self.client postPath:path parameters:params success:success failure:failure];
}


- (NSOperation *)deletePath:(NSString *)path
                 parameters:(NSDictionary *)params
                    success:(void (^)(id data))success
                    failure:(void (^)(NSError *error))failure {
    path = path == nil ? self.basePath : [NSString stringWithFormat:@"%@/%@", self.basePath, path];
    return [self.client deletePath:path parameters:params success:success failure:failure];
}

@end
