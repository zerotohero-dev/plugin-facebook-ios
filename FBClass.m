//
//  FBClass.m
//  FacebookPluginTest
//
//  Created by Tolga Haliloğlu on 16/10/15.
//  Copyright © 2015 Smartface,Inc. All rights reserved.
//

#import "FBClass.h"

@interface FBClass ()

@property (retain, nonatomic) UINavigationController* fbFriendPicker;

//FBFriendPickerDelegate Handlers
@property (nonatomic, retain) SMFJSObject *friendPickerOnSelectedHandler;
@property (nonatomic, retain) SMFJSObject *friendPickerOnCancelledHandler;
@property (nonatomic, retain) SMFJSObject *friendPickerOnErrorHandler;

//Helper Function
+ (NSDictionary *)userDictionaryForGraphUser:(NSDictionary<FBGraphUser> *)user;

@end

@implementation FBClass

-(instancetype)init{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

-(void)initialize{
    _fbFriendPicker = nil;
    _friendPickerOnSelectedHandler = nil;
    _friendPickerOnCancelledHandler = nil;
    _friendPickerOnErrorHandler = nil;
}

-(void)dealloc{
    if (_fbFriendPicker) {
        [_fbFriendPicker release];
    }
    if (_friendPickerOnSelectedHandler) {
        [_friendPickerOnSelectedHandler release];
    }
    if (_friendPickerOnCancelledHandler) {
        [_friendPickerOnCancelledHandler release];
    }
    if (_friendPickerOnErrorHandler) {
        [_friendPickerOnErrorHandler release];
    }
    [super dealloc];
}

-(bool)isSessionActive{
    return FBSession.activeSession.isOpen;
}

-(void)openSession:(NSArray *)permissions onSuccess:(SMFJSObject *)onSuccess onError:(SMFJSObject *)onError {
    [FBSession openActiveSessionWithPublishPermissions:permissions
                                       defaultAudience:FBSessionDefaultAudienceEveryone
                                          allowLoginUI:YES
                                     completionHandler:^(FBSession *session, FBSessionState state, NSError *error)
    {
        if (state == FBSessionStateCreated || state == FBSessionStateOpen)
        {
            NSString *dataString = [NSString stringWithFormat:@"{\"data\":\"%@\"}",session.accessTokenData.accessToken];
            [onSuccess callSelfAsFunctionWithArgs:@[[[SMFJSObject alloc] initWithString:dataString]]];
            NSLog(@"Open Session Success");
        }
        else if (error)
        {
            NSString *dataString = [NSString stringWithFormat:@"{\"message\":\"%@\"}",error.description];
            [onError callSelfAsFunctionWithArgs:@[[[SMFJSObject alloc] initWithString:dataString]]];
            NSLog(@"Open Session Error");
        }
    }];
}

-(void)userDetailsOnSuccess:(SMFJSObject *)onSuccess onError:(SMFJSObject *)onError{
    if ([FBSession activeSession].isOpen) {
        [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
            NSDictionary *resultDictionary = nil;
            
            if (!error){
                resultDictionary = [FBClass userDictionaryForGraphUser:user];
            } else {
                resultDictionary = @{@"message" : [error description]};
            }
            
            if (error) {
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultDictionary options:0 error:nil];
                NSString *dataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [onError callSelfAsFunctionWithArgs:@[[[SMFJSObject alloc] initWithString:dataString]]];
            } else {
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultDictionary options:0 error:nil];
                NSString *dataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [onSuccess callSelfAsFunctionWithArgs:@[[[SMFJSObject alloc] initWithString:dataString]]];
            }
        }];
    } else {
        [onError callSelfAsFunctionWithArgs:@[[[SMFJSObject alloc] initWithString:@"Session is not open!"]]];
    }
}

-(void)closeSession {
    FBSession* session = FBSession.activeSession;
    [session close];
    [session closeAndClearTokenInformation];
    [FBSession setActiveSession:nil];
    
    NSLog(@"Session Closed");
}

-(void)postStatusUpdate:(NSString *)message onSuccess:(SMFJSObject *)onSuccess onError:(SMFJSObject *)onError{
    NSDictionary *params = [NSDictionary dictionaryWithObject:message forKey:@"message"];
    
    [FBRequestConnection startWithGraphPath:@"me/feed"
                                 parameters:params
                                 HTTPMethod:@"POST"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        NSDictionary *resultDictionary = nil;
        if (error) {
            resultDictionary = @{@"message" : [error description]};
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultDictionary options:0 error:nil];
            NSString *dataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [onError callSelfAsFunctionWithArgs:@[[[SMFJSObject alloc] initWithString:dataString]]];
            NSLog(@"Post Status Update Error");
        } else {
            [onSuccess callSelfAsFunctionWithArgs:nil];
            NSLog(@"Post Status Update Success");
        }
    }];
}

-(void)showFriendPicker:(bool)allowMultiSelect onSelected:(SMFJSObject *)onSelected onCancelled:(SMFJSObject *)onCancelled onError:(SMFJSObject *)onError{
    self.friendPickerOnSelectedHandler = onSelected;
    self.friendPickerOnCancelledHandler = onCancelled;
    self.friendPickerOnErrorHandler = onError;
    
    if (!self.fbFriendPicker) {
        FBFriendPickerViewController *pickerController = [[FBFriendPickerViewController alloc] init];
        pickerController.delegate = self;
        pickerController.title = @"Select Friend";
        pickerController.allowsMultipleSelection = allowMultiSelect;
        
        [pickerController loadData];
        [pickerController updateView];
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(facebookViewControllerDoneWasPressed:)];
        pickerController.navigationItem.rightBarButtonItem = doneButton;
        [doneButton release];
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(facebookViewControllerCancelWasPressed:)];
        pickerController.navigationItem.leftBarButtonItem = cancelButton;
        [cancelButton release];
        
        self.fbFriendPicker = [[UINavigationController alloc] initWithRootViewController:pickerController];
        [pickerController release];
    }
    
    if (!self.fbFriendPicker.isBeingPresented) {
        [self.fbFriendPicker setNavigationBarHidden:YES animated:YES];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        [[ESpratNavigationController SMFGetNavigationController] presentViewController:self.fbFriendPicker animated:YES completion:nil];
    }
}

-(void)sendPostToFriend:(NSString *)friendId message:(NSString *)message linkUrl:(NSString *)linkUrl onSuccess:(SMFJSObject *)onSuccess onCancel:(SMFJSObject *)onCancel onError:(SMFJSObject *)onError{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   friendId,@"description",
                                   linkUrl,@"link",
                                   friendId,@"to",
                                   nil];
    FBSession *session = FBSession.activeSession;
    [FBWebDialogs presentFeedDialogModallyWithSession:session parameters:params handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {

        if (error) {
            NSDictionary *resultDictionary = @{@"message" : [error description]};
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultDictionary options:0 error:nil];
            NSString *dataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [onError callSelfAsFunctionWithArgs:@[[[SMFJSObject alloc] initWithString:dataString]]];
        } else if( result == FBWebDialogResultDialogNotCompleted){
            [onCancel callSelfAsFunctionWithArgs:nil];
        } else {
            NSArray *pairs = [[resultURL query] componentsSeparatedByString:@"&"];
            NSMutableDictionary *urlParams = [[NSMutableDictionary alloc] init];
            for (NSString *pair in pairs) {
                NSArray *kv = [pair componentsSeparatedByString:@"="];
                NSString *val = [kv[1] stringByRemovingPercentEncoding];
                urlParams[kv[0]] = val;
            }
            
            if (![urlParams valueForKey:@"post_id"]) {
                [onCancel callSelfAsFunctionWithArgs:nil];
            } else {
                [onSuccess callSelfAsFunctionWithArgs:nil];
            }
            [urlParams release];
        }
    }];
}


-(void)getFriendsListOnSuccess:(SMFJSObject *)onSuccess onError:(SMFJSObject *)onError {
    if (FBSession.activeSession.isOpen) {
        FBRequest* friendsRequest = [FBRequest requestForMyFriends];
        [friendsRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            
            NSMutableArray *allContacts = nil;
            NSDictionary *errorDictionary = nil;
            
            if (!error) {
                NSArray *friends = [result objectForKey:@"data"];
                allContacts = [[NSMutableArray alloc] init];
                
                for (NSDictionary<FBGraphUser>* person in friends) {
                    NSDictionary *tempPerson = [FBClass userDictionaryForGraphUser:person];
                    [allContacts addObject: tempPerson];
                }
            } else {
                errorDictionary = [NSDictionary dictionaryWithObject:error.description forKey:@"message"];
            }

            if (allContacts) {
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:allContacts options:0 error:nil];
                NSString *dataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [onSuccess callSelfAsFunctionWithArgs:@[[[SMFJSObject alloc] initWithString:dataString]]];
            } else {
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:errorDictionary options:0 error:nil];
                NSString *dataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [onError callSelfAsFunctionWithArgs:@[[[SMFJSObject alloc] initWithString:dataString]]];
            }
            
            [allContacts release];
        }];
    } else {
        [onError callSelfAsFunctionWithArgs:@[[[SMFJSObject alloc] initWithString:@"{\"message\" : \"Session is not open!\"}"]]];
    }
}

-(NSString *)getKeyHash{
    return NULL;
}

-(void)requestWithPath:(NSString *)path params:(NSString *)params httpMethod:(NSString *)httpMethod onSuccess:(SMFJSObject *)onSuccess onError:(SMFJSObject *)onError{
    NSDictionary *queryParam = @{@"q":params};
    [FBRequestConnection startWithGraphPath:path
                                 parameters:queryParam
                                 HTTPMethod:httpMethod
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (error) {
                                  NSDictionary *errorDictionary = [NSDictionary dictionaryWithObject:error.description forKey:@"message"];
                                  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:errorDictionary options:0 error:nil];
                                  NSString *dataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                                  [onError callSelfAsFunctionWithArgs:@[[[SMFJSObject alloc] initWithString:dataString]]];
                              } else {
                                  NSDictionary *resultDictionary = [NSDictionary dictionaryWithObject:result forKey:@"result"];
                                  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultDictionary options:0 error:nil];
                                  NSString *dataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                                  [onSuccess callSelfAsFunctionWithArgs:@[[[SMFJSObject alloc] initWithString:dataString]]];
                              }
                          }];
}

//Helper Function

+ (NSDictionary *)userDictionaryForGraphUser:(NSDictionary<FBGraphUser> *)user
{
    NSMutableDictionary *userDetailsDictionary = [NSMutableDictionary dictionary];
    
    NSString *name = user.name ? [user.name copy] : nil;
    NSString *userid = user[@"id"] ? [user[@"id"] copy] : nil;
    NSString *firstname = user.first_name ? [user.first_name copy] : nil;
    NSString *middlename = user.middle_name ? [user.middle_name copy] : nil;
    NSString *lastname = user.last_name ? [user.last_name copy] : nil;
    NSString *username = user.username ? [user.username copy] : nil;
    NSString *birthday = user.birthday ? [user.birthday copy] : nil;
    
    if (name)
        [userDetailsDictionary setObject:name forKey:@"name"];
    if (userid)
        [userDetailsDictionary setObject:userid forKey:@"id"];
    if (firstname)
        [userDetailsDictionary setObject:firstname forKey:@"firstName"];
    if (middlename)
        [userDetailsDictionary setObject:middlename forKey:@"middleName"];
    if (lastname)
        [userDetailsDictionary setObject:lastname forKey:@"lastName"];
    if (username)
        [userDetailsDictionary setObject:username forKey:@"username"];
    if (birthday)
        [userDetailsDictionary setObject:birthday forKey:@"birthday"];
    
    return userDetailsDictionary;
}


#pragma mark FBFriendPickerDelegate

-(void)friendPickerViewController:(FBFriendPickerViewController *)friendPicker handleError:(NSError *)error {
     NSDictionary *errorDictionary = [NSDictionary dictionaryWithObject:error.description forKey:@"message"];
    if (_friendPickerOnErrorHandler) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:errorDictionary options:0 error:nil];
        NSString *dataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [_friendPickerOnErrorHandler callSelfAsFunctionWithArgs:@[[[SMFJSObject alloc] initWithString:dataString]]];
    }
}

-(void)facebookViewControllerCancelWasPressed:(id)sender {
    if (_friendPickerOnCancelledHandler) {
        [_friendPickerOnCancelledHandler callSelfAsFunctionWithArgs:nil];
        [[ESpratNavigationController SMFGetNavigationController] dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)facebookViewControllerDoneWasPressed:(id)sender {
    FBFriendPickerViewController *pickerController = (FBFriendPickerViewController *)self.fbFriendPicker.topViewController;
    
    [[ESpratNavigationController SMFGetNavigationController] dismissViewControllerAnimated:YES completion:nil];
    
    NSMutableArray* allContacts = [[[NSMutableArray alloc] init] autorelease];
    for (NSDictionary<FBGraphUser>* user in pickerController.selection) {
        NSDictionary* tempPerson = [FBClass userDictionaryForGraphUser:user];
        [allContacts addObject: tempPerson];
    }
    
    if (_friendPickerOnSelectedHandler) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:allContacts options:0 error:nil];
        NSString *dataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [_friendPickerOnSelectedHandler callSelfAsFunctionWithArgs:@[[[SMFJSObject alloc] initWithString:dataString]]];
    }
}

@end
