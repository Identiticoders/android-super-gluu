//
//  DataStoreManager.h
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/3/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TokenEntity.h"
#import "UserLoginInfo.h"

@interface DataStoreManager : NSObject

+ (instancetype) sharedInstance;

-(void)saveTokenEntity:(TokenEntity*)tokenEntity;
-(int)incrementCountForToken:(TokenEntity*)tokenEntity;
-(NSArray*)getTokenEntitiesByID:(NSString*)keyID;
-(TokenEntity*)getTokenEntityByKeyHandle:(NSString*)keyHandle;
-(BOOL)deleteTokenEntitiesByID:(NSString*)keyID;

-(void)saveUserLoginInfo:(UserLoginInfo*)userLoginInfo;
-(NSArray*)getUserLoginInfo;

@end
