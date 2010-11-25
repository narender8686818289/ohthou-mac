//
//  Friend.m
//  OhThou
//
//  Created by Ulf Schwekendiek on 11/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Friend.h"
#import "OhThouAppDelegate.h"

@implementation Friend

@synthesize avatarURL = _avatarURL;
@synthesize userID = _userID;
@synthesize jabberName = _jabberName;
@synthesize name = _name;
@synthesize image = _image;

- (id) initWithDictionary:(NSDictionary*)friend
{
    self = [super init];
    if (self != nil) {
        self.avatarURL = [friend objectForKey:@"avatar_url"];
        self.userID = [friend objectForKey:@"id"];
        self.jabberName = [friend objectForKey:@"jabber_name"];
        self.name = [friend objectForKey:@"name"];
    }
    return self;
}

- (NSDictionary*) dictionaryValue
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            self.avatarURL, @"avatar_url", 
            self.userID, @"id",
            self.jabberName, @"jabber_name",
            self.name, @"name", nil];
}


-(void)setAvatarURL:(NSString *)url
{
    _avatarURL = [url copy];
    
    NSURL *urlp = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", SERVER_ROOT_URL, url]];
    _image = [[NSImage alloc] initWithContentsOfURL:urlp];
    
}
@end
