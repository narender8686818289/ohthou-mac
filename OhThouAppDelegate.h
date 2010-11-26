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
#define SERVER_ROOT_URL @"http://10.0.1.17:3000"

@class CBIdentity;
@class Friend;
@class AcceptPartnerWindowController;

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
    
    // account view
    IBOutlet NSImageView *_avatarImageView;
    IBOutlet NSTextField *_name;
    IBOutlet NSTextField *_sentence;
    IBOutlet NSProgressIndicator *_spinner;
    IBOutlet NSTextField *_saveChangesLabel;
    IBOutlet NSButton *_connectButton;
    
    NSString *_xmppusername;
    NSString *_xmpppassword;
    NSString *_xmppfriend;
    NSString *_userID;
    
    Friend *_friend;
    
    NSStatusItem *_statusItem;
    
    int counter;
    int repeat;
    
    AcceptPartnerWindowController *_acceptPartner;
}

- (IBAction) sendmessage:(id)sender;
- (IBAction) pickAvatar:(id)sender;
- (IBAction) showPreferences:(id)sender;
- (IBAction) removeAllUserDefaults:(id)sender;
- (IBAction) done:(id)sender;

- (CBIdentity*)getUserInformation;
- (BOOL) hasAvatar;
- (NSString *) pathForAvatarFile;
- (void) closePreferencesWindow;
- (void) retrieveXMPPName;
- (void) signUp;
- (void) addStatusBarIcon;
- (void) prepareApplication;
- (void) setMenu:(BOOL)online;

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, readonly) XMPPStream *xmppStream;
@property (nonatomic, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, readonly) XMPPRoster *xmppRoster;
@property (nonatomic, readonly) XMPPRosterMemoryStorage *xmppRosterStorage;
@property (nonatomic, readonly) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, readonly) XMPPPing *xmppPing;

@property (nonatomic, readonly) NSString *userID;
@property (nonatomic, readonly) XMPPManager *manager;
@property (nonatomic, retain) Friend *myfriend;

@end
