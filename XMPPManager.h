//
//  XMPPManager.h
//  OhThou
//
//  Created by Ulf Schwekendiek on 11/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XMPPJID.h"

@class XMPPRoster;

@protocol XMPPManagerDelegate

-(void)managerDidConnect;
-(void)managerFailedToConnect;
-(void)managerDidReceiveMessage:(NSString*)message fromUser:(NSString*)username;
-(void)managerDidReceiveSignonForUser:(NSString*)username;
-(void)managerDidReceiveLogoffForUser:(NSString*)username;
-(void)managerDidReceiveBuddyRequestFrom:(XMPPJID*)jid;

@end


@interface XMPPManager : NSObject {
    BOOL _isAuthenticating;
    BOOL _isOpen;
    
    NSString *_username;
    NSString *_password;
    NSString *_yourFriend;
    
    NSObject<XMPPManagerDelegate> *_delegate;
    
    NSMutableDictionary *_lastPresenceUpdateForUser;
}

- (id) initWithDelegate:(NSObject<XMPPManagerDelegate> *)delegate;
- (void) startup;
- (void) loginWithUsername:(NSString*)username password:(NSString*)password;
- (void) sendMessageToUser:(NSString*)username;
- (void) sendMessageToUser:(NSString*)username message:(NSString*)msg;
- (void) addBuddy:(NSString*)buddy withNickname:(NSString*)nickname;
- (void) removeBuddy:(NSString*)buddy;
- (XMPPRoster *)xmppRoster;

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *yourFriend;
@property (nonatomic, retain) NSObject<XMPPManagerDelegate> *delegate;
@end
