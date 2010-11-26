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
@synthesize thumbImage = _thumbImage;

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
    
    NSData *sourceData = [NSData dataWithContentsOfURL:urlp];
    float resizeWidth = 20.0;
    float resizeHeight = 20.0;
    
    NSImage *sourceImage = [[NSImage alloc] initWithData: sourceData];
    NSImage *resizedImage = [[NSImage alloc] initWithSize: NSMakeSize(resizeWidth, resizeHeight)];
    
    NSSize originalSize = [sourceImage size];
    
    [resizedImage lockFocus];
    [sourceImage drawInRect: NSMakeRect(0, 0, resizeWidth, resizeHeight) fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height) operation: NSCompositeSourceOver fraction: 1.0];
    [resizedImage unlockFocus];
        
    _image = [sourceImage retain];
    _thumbImage = [resizedImage retain];
    [sourceImage release];
    [resizedImage release];
    
    
}
@end
