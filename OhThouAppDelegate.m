//
//  OhThouAppDelegate.m
//  OhThou
//
//  Created by Ulf Schwekendiek on 11/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OhThouAppDelegate.h"
#import "TURNSocket.h"
#import "XMPPManager.h"

@implementation OhThouAppDelegate

@synthesize window;

@synthesize xmppStream = _xmppStream;
@synthesize xmppReconnect = _xmppReconnect;
@synthesize xmppRoster = _xmppRoster;
@synthesize xmppRosterStorage = _xmppRosterStorage;
@synthesize xmppCapabilities = _xmppCapabilities;
@synthesize xmppCapabilitiesStorage = _xmppCapabilitiesStorage;
@synthesize xmppPing = _xmppPing;

- (id) init
{
    self = [super init];
    if (self != nil) {
        _xmppStream = [[XMPPStream alloc] init];
		
		_xmppRosterStorage = [[XMPPRosterMemoryStorage alloc] init];
		_xmppRoster = [[XMPPRoster alloc] initWithStream:_xmppStream
		                                  rosterStorage:_xmppRosterStorage];
		
		_xmppCapabilitiesStorage = [[XMPPCapabilitiesCoreDataStorage alloc] init];
		_xmppCapabilities = [[XMPPCapabilities alloc] initWithStream:_xmppStream
		                                        capabilitiesStorage:_xmppCapabilitiesStorage];
		
		_xmppCapabilities.autoFetchHashedCapabilities = YES;
		_xmppCapabilities.autoFetchNonHashedCapabilities = NO;
		
		_xmppPing = [[XMPPPing alloc] initWithStream:_xmppStream];
		_xmppTime = [[XMPPTime alloc] initWithStream:_xmppStream];
		        
        _manager = [[XMPPManager alloc] initWithDelegate:self];
    }
    return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[_xmppStream addDelegate:self];
	[_xmppReconnect addDelegate:self];
	[_xmppCapabilities addDelegate:self];
	[_xmppPing addDelegate:self];
	[_xmppTime addDelegate:self];   
    [_xmppRoster addDelegate:self];
    
    [_manager startup];
    [_connectedTo setStringValue:@""];
}

- (IBAction) connect:(id)sender
{
    [_manager loginWithUsername:[_username stringValue] password:[_password stringValue]];
    _manager.yourFriend = [_friend stringValue];
}

- (IBAction) sendmessage:(id)sender
{
    [_manager sendMessageToUser:@"bob@ohthou.com"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Auto Reconnect
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
//	NSLog(@"xmppStream:didReceiveError: %@", error);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender
{
//	NSLog(@"xmppStreamDidDisconnect:");
	
	// If we weren't using auto reconnect, we could take this opportunity to display the sign in sheet.
}

- (BOOL)xmppReconnect:(XMPPReconnect *)sender shouldAttemptAutoReconnect:(SCNetworkReachabilityFlags)reachabilityFlags
{
//	NSLog(@"---------- xmppReconnect:shouldAttemptAutoReconnect: ----------");
	
	return YES;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Capabilities
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppCapabilities:(XMPPCapabilities *)sender didDiscoverCapabilities:(NSXMLElement *)caps forJID:(XMPPJID *)jid
{
//	NSLog(@"---------- xmppCapabilities:didDiscoverCapabilities:forJID: ----------");
//	NSLog(@"jid: %@", jid);
//	NSLog(@"capabilities:\n%@", [caps XMLStringWithOptions:(NSXMLNodeCompactEmptyElement | NSXMLNodePrettyPrint)]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma XMPPManager delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void)managerDidConnect
{
    NSLog(@"connected");
}

-(void)managerFailedToConnect
{
    NSLog(@"failedtoConnect");
}

-(void)managerDidReceiveMessage:(NSString*)message fromUser:(NSString*)username
{
    NSLog(@"Message from %@:'%@'", username, message);
    [_heart setHidden:NO];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(removeHeart) withObject:nil afterDelay:3.0];
}

- (void) removeHeart
{
    [_heart setHidden:YES];
}

-(void)managerDidReceiveSignonForUser:(NSString*)username
{
    NSLog(@"Signon: %@", username);
    [_connectedTo setStringValue:username];
}

-(void)managerDidReceiveLogoffForUser:(NSString*)username
{
    NSLog(@"Signoff: %@", username);
    [_connectedTo setStringValue:@""];
}

@end
