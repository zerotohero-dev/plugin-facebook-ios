//
//  FBClass.h
//  FacebookPluginTest
//
//  Created by Tolga Haliloğlu on 16/10/15.
//  Copyright © 2015 Smartface,Inc. All rights reserved.
//

//#import <Foundation/Foundation.h>

#import <JavaScriptCore/JavaScriptCore.h>

#ifdef SMARTFACE_PRODUCTION
#include <iOSPlayer/inc/SMFJSObject.h>
#include <iOSPlayer/inc/ESpratIOSPlayer.h>
#include <iOSPlayer/inc/ESpratNavigationController.h>
#else
#import "SMFJSObject.h"
#import "ESpratIOSPlayer.h"
#import "ESpratNavigationController.h"
#endif


#import <FacebookSDK/FacebookSDK.h>

@interface FBClass : NSObject <FBFriendPickerDelegate>

-(bool)isSessionActive;

-(void)openSession:(NSArray *)permissions
         onSuccess:(SMFJSObject *)onSuccess
           onError:(SMFJSObject *)onError;

-(void)userDetailsOnSuccess:(SMFJSObject *)onSuccess
                    onError:(SMFJSObject *)onError;

-(void)closeSession;

-(void)postStatusUpdate:(NSString *)message
              onSuccess:(SMFJSObject *)onSuccess
                onError:(SMFJSObject *)onError;

-(void)showFriendPicker:(bool)allowMultiSelect
             onSelected:(SMFJSObject *)onSelected
            onCancelled:(SMFJSObject *)onCancelled
                onError:(SMFJSObject *)onError;

-(void)sendPostToFriend:(NSString *)friendId
                message:(NSString *)message
                linkUrl:(NSString *)linkUrl
              onSuccess:(SMFJSObject *)onSuccess
               onCancel:(SMFJSObject *)onCancel
                onError:(SMFJSObject *)onError;

-(void)getFriendsListOnSuccess:(SMFJSObject *)onSuccess
                       onError:(SMFJSObject *)onError;

-(NSString *)getKeyHash;

-(void)requestWithPath:(NSString *)path
                params:(NSString *)params
            httpMethod:(NSString *)httpMethod
             onSuccess:(SMFJSObject *)onSuccess
               onError:(SMFJSObject *)onError;

@end
