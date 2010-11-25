//
//  OhThouAppDelegate.h
//  OhThou
//
//  Created by Ulf Schwekendiek on 11/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPRoster.h"
#import "XMPPRosterMemoryStorage.h"
#import "XMPPCapabilities.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPPing.h"
#import "XMPPTime.h"
#import "XMPPManager.h"

@interface OhThouAppDelegate : NSObject <NSApplicationDelegate,XMPPManagerDelegate> {
	XMPPStream *_xmppStream;
	XMPPReconnect *_xmppReconnect;
	XMPPRoster *_xmppRoster;
	XMPPRosterMemoryStorage *_xmppRosterStorage;
	XMPPCapabilities *_xmppCapabilities;
	XMPPCapabilitiesCoreDataStorage *_xmppCapabilitiesStorage;
	XMPPPing *_xmppPing;
	XMPPTime *_xmppTime;
	    
    NSWindow *window;
    
    XMPPManager *_manager;
    
    IBOutlet NSTextField *_username;
    IBOutlet NSTextField *_password;
    IBOutlet NSTextField *_friend;
    IBOutlet NSTextField *_connectedTo;
    IBOutlet NSTextField *_heart;
}

- (IBAction) connect:(id)sender;
- (IBAction) sendmessage:(id)sender;

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, readonly) XMPPStream *xmppStream;
@property (nonatomic, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, readonly) XMPPRoster *xmppRoster;
@property (nonatomic, readonly) XMPPRosterMemoryStorage *xmppRosterStorage;
@property (nonatomic, readonly) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, readonly) XMPPPing *xmppPing;

@end
