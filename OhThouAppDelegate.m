//
//  OhThouAppDelegate.m
//  OhThou
//
//  Created by Ulf Schwekendiek on 11/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Collaboration/Collaboration.h>
#import "OhThouAppDelegate.h"
#import "TURNSocket.h"
#import "XMPPManager.h"
#import <Quartz/Quartz.h>
#import "ASIFormDataRequest.h"
#import "JSON.h"
#import "AcceptPartnerWindowController.h"
#import "Friend.h"
#import "XMPPJID.h"

@implementation OhThouAppDelegate

@synthesize window;

@synthesize manager = _manager;
@synthesize xmppStream = _xmppStream;
@synthesize xmppReconnect = _xmppReconnect;
@synthesize xmppRoster = _xmppRoster;
@synthesize xmppRosterStorage = _xmppRosterStorage;
@synthesize xmppCapabilities = _xmppCapabilities;
@synthesize xmppCapabilitiesStorage = _xmppCapabilitiesStorage;
@synthesize xmppPing = _xmppPing;
@synthesize userID = _userID;
@synthesize myfriend = _friend;

- (id) init
{
    self = [super init];
    if (self != nil) {
        counter = 10;
        repeat = 10;

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

- (IBAction) removeAllUserDefaults:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removePersistentDomainForName:@"com.ohthou.client.mac"];
	// com.yourcompany.appname is the Bundle Identifier for this app
	[defaults synchronize];
    
    NSFileManager *fileManager = [NSFileManager defaultManager]; 
    [fileManager removeItemAtPath:[self pathForAvatarFile] error:nil];
    [_xmppStream disconnect];
    
    [_name setStringValue:@""];
    [_sentence setStringValue:@""];
    [_name becomeFirstResponder];
    
    [_acceptPartner close];
    
    [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
    [_statusItem release];
    _statusItem = nil;
    
    [self prepareApplication];
}

- (void) setMyfriend:(Friend *)f
{
    _friend = [f retain];
    _xmppfriend = f.jabberName;
    [[NSUserDefaults standardUserDefaults] setObject:_xmppfriend forKey:@"kFriend"];
    [[NSUserDefaults standardUserDefaults] setObject:[_friend dictionaryValue] forKey:@"kFriendDict"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _manager.yourFriend = [f.jabberName stringByAppendingString:@"@ohthou.com"];
    
    if ([_xmppStream isAuthenticated] && _statusItem == nil)
    {
        [self addStatusBarIcon];      
    }
}

- (void) setMenu:(BOOL)online {
    NSMenu *menu = [[NSMenu alloc] init];

    NSMenuItem *usernameItem = [[NSMenuItem alloc] init];
    [usernameItem setTitle:[_friend.name stringByAppendingString:@" *wink*"]];
    if (online)
        [usernameItem setAction:@selector(sendmessage:)];
    [usernameItem setImage:_friend.thumbImage];
    NSMenuItem *logoutItem = [[[NSMenuItem alloc] initWithTitle:@"Disconnect" action:@selector(removeAllUserDefaults:) keyEquivalent:@""] autorelease];

                            
    [menu addItem:usernameItem];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:logoutItem];

    [_statusItem setMenu:[menu autorelease]];

}

- (void) addStatusBarIcon
{
    if (_statusItem != nil)
        return;
    
    _statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];

    [self setMenu:NO];

    [_statusItem setImage:[NSImage imageNamed:@"(h)_offline.png"]];
    [_statusItem setHighlightMode:YES];  
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self prepareApplication];
}

- (void)applicationWillTerminate:(NSNotification *)notification 
{
    if ([_xmppStream isConnected])
        [_xmppStream disconnect];
}

- (void) prepareApplication
{
    _friend = nil;
    _xmppusername = nil;
    _xmpppassword = nil;
    _xmppfriend = nil;
    _userID = nil;
    
    [_xmppStream addDelegate:self];
	[_xmppReconnect addDelegate:self];
	[_xmppCapabilities addDelegate:self];
	[_xmppPing addDelegate:self];
	[_xmppTime addDelegate:self];   
    [_xmppRoster addDelegate:self];
    
    [_manager startup];
    
    // set user image
    if (![self hasAvatar])
    {
        CBIdentity *identity = [self getUserInformation];
        _avatarImageView.image = [identity image];        
        [[[identity image] TIFFRepresentation] writeToFile:[self pathForAvatarFile] atomically:YES];
    }
    else 
    {
        _avatarImageView.image = [[[NSImage alloc] initByReferencingFile:[self pathForAvatarFile]] autorelease];
    }
    
    // friend dict
    NSDictionary *fd = [[NSUserDefaults standardUserDefaults] objectForKey:@"kFriendDict"];
    if (fd)
    {
        self.myfriend = [[[Friend alloc] initWithDictionary:fd] autorelease];
    }
    
    // set name and sentence
    NSString *name = [[NSUserDefaults standardUserDefaults] objectForKey:@"kName"];    
    if (name)
    {
        [_name setStringValue:name];
    }
    else 
    {
        CBIdentity *identity = [self getUserInformation];
        name = [identity fullName];
        [_name setStringValue:name];
    }

    
    NSString *sentence = [[NSUserDefaults standardUserDefaults] objectForKey:@"kSentence"];
    if (sentence)
        [_sentence setStringValue:sentence];
    
    if (!name || !sentence)
    {
        [self showPreferences:nil];
    }
    
    
    // retrieve username and password
    _xmppusername = [[NSUserDefaults standardUserDefaults] objectForKey:@"kUsername"];    
    _xmpppassword = [[NSUserDefaults standardUserDefaults] objectForKey:@"kPassword"];
    //    if (!_xmppusername || !_xmpppassword)
    //    {
    //        [self retrieveXMPPName];
    //    }
    
    _userID = [[NSUserDefaults standardUserDefaults] objectForKey:@"kUserID"];
    
    _xmppfriend = [[NSUserDefaults standardUserDefaults] objectForKey:@"kFriend"];
    if (_xmppfriend)
    {
        _manager.yourFriend = _xmppfriend;
    }
    
    if (_xmppusername && _xmpppassword && _userID)
    {
        [_manager loginWithUsername:_xmppusername password:_xmpppassword];
    }
    
    _acceptPartner = [[AcceptPartnerWindowController alloc] initWithWindowNibName:@"AcceptPartnerWindow"];        
}

- (IBAction) pickAvatar:(id)sender
{
    IKImagePicker *picker = [IKImagePicker imagePicker];

    /* set a default image to start */
    [picker setInputImage:_avatarImageView.image];
    [picker setValue:[NSNumber numberWithBool:YES] forKey:IKImagePickerShowEffectsKey];
    
    /* launch the imagePicker as a panel */
    [picker beginImagePickerWithDelegate:self didEndSelector:@selector(imagePickerValidated:code:contextInfo:) contextInfo:nil];
}

- (void) imagePickerValidated:(IKImagePicker*) imagePicker code:(int) returnCode contextInfo:(void*) ctxInf
{
    if(returnCode == NSOKButton){
        /* retrieve the output image */
        NSImage *outputImage = [imagePicker outputImage];
        
        // save the avatar to disk
        [[outputImage TIFFRepresentation] writeToFile:[self pathForAvatarFile] atomically:YES];
        
        /* change the displayed image */
        [_avatarImageView setImage:outputImage];
    }
    else{
        /* the user canceled => nothing to do here */
    }
}

- (IBAction) sendmessage:(id)sender
{
    [_manager sendMessageToUser:[_xmppfriend stringByAppendingString:@"@ohthou.com"]];
}

- (IBAction) showPreferences:(id)sender
{
    [window makeKeyAndOrderFront:sender];
}


- (NSString *) pathForAvatarFile { 
    NSFileManager *fileManager = [NSFileManager defaultManager]; 
    NSString *folder = @"~/Library/Application Support/OhThou/"; 
    folder = [folder stringByExpandingTildeInPath]; 
    if ([fileManager fileExistsAtPath: folder] == NO) 
    { 
        [fileManager createDirectoryAtPath: folder withIntermediateDirectories:YES attributes: nil error:nil]; 
    } 
    
    NSString *fileName = @"avatar.tiff"; 
    
    return [folder stringByAppendingPathComponent: fileName]; 
} 

- (BOOL) hasAvatar {
    NSFileManager *fileManager = [NSFileManager defaultManager]; 
    return [fileManager fileExistsAtPath:[self pathForAvatarFile]];
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
#pragma mark XMPPManager delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) showAcceptWindow
{
    [_acceptPartner showWindow:self];
    NSRect mainScreenFrame = [[NSScreen mainScreen] frame];
    NSPoint newOrigin;
    newOrigin.x = mainScreenFrame.size.width - [[_acceptPartner window] frame].size.width;
    newOrigin.y = mainScreenFrame.size.height - [[_acceptPartner window] frame].size.height;
    [[_acceptPartner window] setFrameOrigin:newOrigin];
}

-(void)managerDidConnect
{
    NSLog(@"connected");
    
    if (_friend == nil)
    {
        [self showAcceptWindow];
    } else {
        [self addStatusBarIcon];  
    }

}

- (void)connectToServer
{
    [_manager loginWithUsername:_xmppusername password:_xmpppassword];
}

-(void)managerFailedToConnect
{
    NSLog(@"failedtoConnect");
    // could not connect, lets try again in a bit
    [self performSelector:@selector(connectToServer) withObject:nil afterDelay:15];
}

- (void) animate
{
    [_statusItem setImage:[NSImage imageNamed:[NSString stringWithFormat:@"(h)_%d", counter--]]];
    
    if (counter == 4)
    {
		[NSApp requestUserAttention: NSInformationalRequest];
        repeat -= 1;
        counter = 10;
    }
    
    if (repeat >= 0)
    {
        [self performSelector:@selector(animate) withObject:nil afterDelay:0.05];
    } else {
        [_statusItem setImage:[NSImage imageNamed:[NSString stringWithFormat:@"(h)_%d", counter]]];
        counter = 10;
        repeat = 10;
    }
  
}

- (void) animateStatusIcon
{
    counter = 10;
    repeat = 10;
    [self animate];
}

-(void)managerDidReceiveMessage:(NSString*)message fromUser:(NSString*)username
{
    NSLog(@"Message from %@:'%@'", username, message);
    if ([message isEqualToString:@"<3"])
    {
        if (repeat == 10)
        {
            [self animateStatusIcon];
        }
    }
}

-(void)managerDidReceiveSignonForUser:(NSString*)username
{
    NSLog(@"Signon: %@", username);
    if ([username isEqualToString:[[_xmppfriend stringByAppendingFormat:@"@ohthou.com"] lowercaseString]])
    {
        [_statusItem setImage:[NSImage imageNamed:@"(h).png"]];
        [self setMenu:YES];
    }
}

-(void)managerDidReceiveLogoffForUser:(NSString*)username
{
    NSLog(@"Signoff: %@", username);
    if ([username isEqualToString:[[_xmppfriend stringByAppendingFormat:@"@ohthou.com"] lowercaseString]])
    {
        [_statusItem setImage:[NSImage imageNamed:@"(h)_offline.png"]];
        [self setMenu:NO];
    }
}

-(void)managerDidReceiveBuddyRequestFrom:(XMPPJID*)jid
{
    if ([[jid bare] isEqualToString:[[_xmppfriend stringByAppendingFormat:@"@ohthou.com"] lowercaseString]])
    {
        [_xmppRoster acceptBuddyRequest:jid];
    }
}

#pragma mark -
#pragma mark Pref window methods

- (CBIdentity*)getUserInformation
{	
	CFErrorRef error;
	CSIdentityQueryRef query = CSIdentityQueryCreateForCurrentUser(kCFAllocatorDefault);
	CBIdentity *identity = nil;
	
	// execute the query	
	if (CSIdentityQueryExecute(query, kCSIdentityQueryGenerateUpdateEvents, &error))
	{
		// retrieve the results of the identity query
		NSArray *results = (NSArray*)CSIdentityQueryCopyResults(query);
		identity = [CBIdentity identityWithCSIdentity:(CSIdentityRef)[results objectAtIndex:0]];
	}
	
	CFRelease(query);
	
	return identity;
}

- (void) setSaveChangesEnabled:(BOOL)enabled
{
    if (enabled)
        [_spinner startAnimation:nil];
    else
        [_spinner stopAnimation:nil];
    
    [_connectButton setEnabled:!enabled];
    [_spinner setHidden:!enabled];
    [_saveChangesLabel setHidden:!enabled];
}

- (void) closePreferencesWindow
{
    // save data
    if ([[_name stringValue] length] > 0)
        [[NSUserDefaults standardUserDefaults] setObject:[_name stringValue] forKey:@"kName"];
    if ([[_sentence stringValue] length] > 0)
        [[NSUserDefaults standardUserDefaults] setObject:[_sentence stringValue] forKey:@"kSentence"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self setSaveChangesEnabled:NO];
    
    [window close];
}

#pragma mark -
#pragma mark CreateUserRequest

- (void) retrieveXMPPName
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/users/new?api_version=1.0", SERVER_ROOT_URL]];
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request setCompletionBlock:^{
        // Use when fetching text data
        NSString *responseString = [request responseString];
        NSDictionary *response = [responseString JSONValue];

        _xmppusername = [[response objectForKey:@"user"] objectForKey:@"jabber_name"];
        _xmpppassword = [[response objectForKey:@"user"] objectForKey:@"jabber_password"];    

        [[NSUserDefaults standardUserDefaults] setObject:_xmppusername forKey:@"kUsername"];
        [[NSUserDefaults standardUserDefaults] setObject:_xmpppassword forKey:@"kPassword"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self signUp];
    }];
    [request setFailedBlock:^{
        [self setSaveChangesEnabled:NO];
        
        NSError *error = [request error];
        [window presentError:error];
    }];
    [request startAsynchronous];
}

- (void) signUp
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/users/", SERVER_ROOT_URL]];
    __block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:@"1.0" forKey:@"api_version"];
    [request setPostValue:[_name stringValue] forKey:@"name"];
    [request setPostValue:[_sentence stringValue] forKey:@"phrase"];
    [request setPostValue:_xmppusername forKey:@"jabber_name"];
    [request setPostValue:_xmpppassword forKey:@"jabber_password"];
    [request setFile:[self pathForAvatarFile] forKey:@"avatar"];
    
    [request setDelegate:self];
    [request setCompletionBlock:^{
        // Use when fetching text data
        NSString *responseString = [request responseString];
        NSDictionary *response = [responseString JSONValue];
        
        NSNumber *statuscode = [response objectForKey:@"status_code"];
        if ([statuscode intValue] == 0)
        {
            // everything's good
            _userID = [[response objectForKey:@"user"] objectForKey:@"id"];
            [[NSUserDefaults standardUserDefaults] setObject:_userID forKey:@"kUserID"];
            [self closePreferencesWindow];
            
            // sign in
            [_manager loginWithUsername:_xmppusername password:_xmpppassword];
        } 
        else 
        {
            [self setSaveChangesEnabled:NO];
            
            NSError *e = [NSError errorWithDomain:@"Server Connection Error" 
                                             code:[statuscode intValue] 
                                         userInfo:[NSDictionary dictionaryWithObject:[[response objectForKey:@"errors"] description] 
                                                                              forKey:NSLocalizedDescriptionKey]];
            [window presentError:e];
        }
        
        
    }];
    [request setFailedBlock:^{
        NSError *error = [request error];
        [window presentError:error];
        [self setSaveChangesEnabled:NO];
    }];
    [request startAsynchronous];
}

- (IBAction) done:(id)sender
{
    // Create a new backend user only if fields change
    if ([[_name stringValue] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"kName"]] &&
        [[_sentence stringValue] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"kSentence"]])
    {
        return;
    } 
    
    [self setSaveChangesEnabled:YES];
    [self retrieveXMPPName];
}

#pragma mark -
#pragma mark Window Delegate
- (BOOL)windowShouldClose:(id)sender
{
    // Create a new backend user only if fields change
    if ([[_name stringValue] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"kName"]] &&
        [[_sentence stringValue] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"kSentence"]])
    {
        return YES;
    }
    
    [self setSaveChangesEnabled:YES];
    [self retrieveXMPPName];
    
    return NO;
}

@end
