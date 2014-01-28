//
//  MSGSEndpointRequestHelper.m
//  ENSSample
//
//  Created by Peter Verhage on 22-01-14.
//
//

#import "MSGSEndpointRequestHelper.h"
#import "MSGSRequestHelper-Protected.h"

@implementation MSGSEndpointRequestHelper

- (id)initWithClient:(MSGSClient *)client token:(NSString *)token {
    return [self initWithClient:client token:token basePath:nil];
}

- (id)initWithClient:(MSGSClient *)client token:(NSString *)token basePath:(NSString *)basePath {
    basePath = basePath == nil ? [NSString stringWithFormat:@"endpoints/%@", token] : [NSString stringWithFormat:@"%@/endpoints/%@", basePath, token];
    return [super initWithClient:client basePath:basePath];
}

- (void)fetchWithSuccess:(void (^)(MSGSEndpoint *endpoint))success
                 failure:(void (^)(NSError *error))failure {
    [self getPath:nil parameters:nil success:^(id data) {
        success([[MSGSEndpoint alloc] initWithDictionary:data]);
    } failure:failure];
}

- (void)updateWithDictionary:(NSDictionary *)keyedValues
                     success:(void (^)(MSGSEndpoint *endpoint))success
                     failure:(void (^)(NSError *error))failure {
    [self postPath:nil parameters:keyedValues success:^(id data) {
        if (success != nil) {
            success([[MSGSEndpoint alloc] initWithDictionary:data]);
        }
    } failure:failure];
}

- (void)deleteWithSuccess:(void (^)())success
                  failure:(void (^)(NSError *error))failure {
    [self deletePath:nil parameters:nil success:^(id data) {
        if (success != nil) {
            success();
        }
    } failure:failure];
}

@end
