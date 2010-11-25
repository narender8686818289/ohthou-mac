//
//  Friend.h
//  OhThou
//
//  Created by Ulf Schwekendiek on 11/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Friend : NSObject {
    NSString *_avatarURL;
    NSString *_userID;
    NSString *_jabberName;
    NSString *_name;
    
    NSImage *_image;
}

- (id) initWithDictionary:(NSDictionary*)friend;
- (NSDictionary*) dictionaryValue;
@property (nonatomic, copy) NSString *avatarURL;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *jabberName;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, readonly) NSImage *image;

@end
