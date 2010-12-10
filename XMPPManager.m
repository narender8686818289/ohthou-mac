//
//  XMPPManager.m
//  OhThou
//
//  Created by Ulf Schwekendiek on 11/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XMPPManager.h"
#import "OhThouAppDelegate.h"


@implementation XMPPManager

@synthesize username = _username;
@synthesize password = _password;
@synthesize delegate = _delegate;
@synthesize yourFriend = _yourFriend;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Setup:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (XMPPStream *)xmppStream
{
	return [[NSApp delegate] xmppStream];
}

- (XMPPRoster *)xmppRoster
{
	return [[NSApp delegate] xmppRoster];
}

- (XMPPRosterMemoryStorage *)xmppRosterStorage
{
	return [[NSApp delegate] xmppRosterStorage];
}

- (id) initWithDelegate:(NSObject<XMPPManagerDelegate> *)delegate
{
    self = [super init];
    if (self != nil) {
        _isAuthenticating = NO;
        _isOpen = NO;
        self.delegate = delegate;
        
        _lastPresenceUpdateForUser = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) startup
{
    [[self xmppRoster] setAutoRoster:YES];
    [[self xmppStream] addDelegate:self];
    [[self xmppRoster] addDelegate:self];            
}

- (void) loginWithUsername:(NSString*)username password:(NSString*)password
{
    self.username = username;
    self.password = password;
    
    [[self xmppStream] setHostName:@"ohthou.com"];
    [[self xmppStream] setHostPort:5222];
    
    XMPPJID *jid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@", [username stringByAppendingString:@"@ohthou.com"]] 
                                 resource:@"OhThou Client"];
	
	[[self xmppStream] setMyJID:jid];
    
    NSError *error = nil;
	BOOL success;

    if(![[self xmppStream] isConnected])
	{
        success = [[self xmppStream] connect:&error];
	}
	else
	{
		success = [[self xmppStream] authenticateWithPassword:password error:&error];
	}
    
    if (success)
	{
		_isAuthenticating = YES;
    } else {
        [self.delegate managerFailedToConnect];
    }
}
- (void)sendMessageToUser:(NSString*)username
{
    [self sendMessageToUser:username message:@"<3"];
}

- (void)sendMessageToUser:(NSString*)username message:(NSString*)msg
{
    XMPPJID *jid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@", username]];
    
//    id <XMPPUser> user = [[self xmppRoster] userForJID:jid];
//    if (!user)
//    {
//        // user is not in our roster, add him
//        [self addBuddy:username withNickname:nil];
//    } 
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:msg];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:[jid full]];
    [message addChild:body];
    
    [[self xmppStream] sendElement:message];
}

- (void)goOnline
{
	NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
	
	[[self xmppStream] sendElement:presence];
}

- (void)goOffline
{
	NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
	[presence addAttributeWithName:@"type" stringValue:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Buddy Management
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)addBuddy:(NSString*)buddy withNickname:(NSString*)nickname
{
	XMPPJID *jid = [XMPPJID jidWithString:buddy];
	
	[[self xmppRoster] addBuddy:jid withNickname:nickname];
}

- (void)removeBuddy:(NSString*)buddy
{
	XMPPJID *jid = [XMPPJID jidWithString:buddy];
	
	[[self xmppRoster] removeBuddy:jid];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPClient Delegate Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	// NSLog(@"---------- xmppStream:willSecureWithSettings: ----------");
	
	// allowSelfSignedCertificates
    [settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	
	// allowSSLHostNameMismatch
    [settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	// NSLog(@"---------- xmppStreamDidSecure ----------");
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	
	_isOpen = YES;
	
	NSError *error = nil;
	BOOL success;
	
    success = [[self xmppStream] authenticateWithPassword:self.password error:&error];
	
	if (!success)
	{
		[self.delegate managerFailedToConnect];
	}
}


- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	// NSLog(@"---------- xmppStreamDidAuthenticate ----------");
	
	// Update tracking variables
	_isAuthenticating = NO;
		
	// Send presence
	[self goOnline];
    
    [self.delegate managerDidConnect];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	// NSLog(@"---------- xmppStream:didNotAuthenticate: ----------");
	
	// Update tracking variables
	_isAuthenticating = NO;
    
    [self.delegate managerFailedToConnect];
}

- (void)xmppRosterUserDidChangePresence:(XMPPPresence *)presence
{
    if ([[[presence from] bare] isEqualToString:[[_username stringByAppendingString:@"@ohthou.com"] lowercaseString]])
        return;
    
    NSString *key = [NSString stringWithFormat:@"%@%@", [[presence from] bare], [presence type]];
    
    NSDate *lastDate = [_lastPresenceUpdateForUser objectForKey:key];
    if (lastDate)
    {
        
        NSTimeInterval t = [lastDate timeIntervalSinceNow];
        if (abs(t) < 0.01)
            return;
    } 

    if ([[presence type] isEqualToString:@"unavailable"])
    {
        [self.delegate managerDidReceiveLogoffForUser:[[presence from] bare]];
    }  
    else
    {
        [self.delegate managerDidReceiveSignonForUser:[[presence from] bare]];
    }
 
    [_lastPresenceUpdateForUser setObject:[NSDate date] forKey:key];
}

- (void)xmppRosterDidChange:(XMPPRosterMemoryStorage *)sender
{
    NSLog(@"---------- xmppRosterDidChange ----------");

}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    if ([message isChatMessage] && [[message elementForName:@"body"] stringValue])
    {
        //NSString *messageStr = [[message elementForName:@"body"] stringValue];
        
        // NSLog(@"---------- xmppStream:didReceiveMessage: ----------");
        // NSLog(@"Body: %@", messageStr);
        [self.delegate managerDidReceiveMessage:[[message elementForName:@"body"] stringValue] 
                                       fromUser:[[message from] bare]];        
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	// NSLog(@"---------- xmppStream:didReceiveError: ----------");
	// NSLog(@"%@", error);
    [self.delegate managerFailedToConnect];
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender
{
	// NSLog(@"---------- xmppStreamDidDisconnect ----------");
	
	if (!_isOpen)
	{
		[self.delegate managerFailedToConnect];
	}
	
	// Update tracking variables
	_isOpen = NO;
	_isAuthenticating = NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPClient Delegate Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Sent when a buddy request is received.
 * 
 * The entire presence packet is provided for proper extensibility.
 * You can use [presence from] to get the JID of the buddy who sent the request.
 **/
- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence
{
    [self.delegate managerDidReceiveBuddyRequestFrom:[presence from]];
}



@end
