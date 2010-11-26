//
//  AcceptPartnerWindowController.m
//  OhThou
//
//  Created by Ulf Schwekendiek on 11/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AcceptPartnerWindowController.h"
#import "OhThouAppDelegate.h"

#import "JSON.h"
#import "ASIFormDataRequest.h"
#import "Friend.h"

@implementation AcceptPartnerWindowController

- (void)windowDidLoad
{
    _items = [[NSMutableArray alloc] init];
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
    
    [self refreshDatasource];
}

- (void) refreshDatasource
{
    [_items removeAllObjects];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/users/%@/match?api_version=1.0", SERVER_ROOT_URL, [[NSApp delegate] userID]]];
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [self setSaveChangesEnabled:YES];
    
    [request setCompletionBlock:^{
        // Use when fetching text data
        NSString *responseString = [request responseString];
        NSDictionary *response = [responseString JSONValue];
        
        for (NSDictionary *friend in [response objectForKey:@"possible_friends"])
        {
            Friend *possible_friend = [[Friend alloc] initWithDictionary:friend];
            
            [_items addObject:[possible_friend autorelease]];
        }
        [self setSaveChangesEnabled:NO];
        
        [_tableView reloadData];
        // [_tableView setNeedsDisplay];
    }];
    [request setFailedBlock:^{
        [self setSaveChangesEnabled:NO];
        
        NSError *error = [request error];
        [self.window presentError:error];
    }];
    [request startAsynchronous];
}


- (void) setSaveChangesEnabled:(BOOL)enabled
{
    if (enabled)
        [_spinner startAnimation:nil];
    else
        [_spinner stopAnimation:nil];
    
    [_spinner setHidden:!enabled];
    [_saveChangesLabel setHidden:!enabled];
}


#pragma mark -
#pragma mark TableView Delegate
//- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
//{
//    return 30.0;
//}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSCell *cell = nil;
    if ([[tableColumn identifier] isEqualToString:@"text"])
    {
        cell = [[NSCell alloc] initTextCell:@"Test"];
    }
    else if ([[tableColumn identifier] isEqualToString:@"image"])
    {
        cell = [[NSImageCell alloc] init];
    }
    else if ([[tableColumn identifier] isEqualToString:@"accept"])
    {
        cell = [[NSButtonCell alloc] initTextCell:@"Accept"];
        [cell setTag:row];
        [cell setTarget:self];
        [cell setAction:@selector(buttonclicked:)];
    }
    return [cell autorelease];
}

- (void) buttonclicked:(id)sender
{
    NSActionCell *cell = [_tableView selectedCell];
    Friend *fr = [_items objectAtIndex:[cell tag]];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/users/%@", SERVER_ROOT_URL, [[NSApp delegate] userID]]];
    __block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request addPostValue:@"1.0" forKey:@"api_version"];
    [request addPostValue:[NSString stringWithFormat:@"%@", [fr userID]] forKey:@"friend_id"];
    [request setRequestMethod:@"PUT"];
    [request setDelegate:self];
    [self setSaveChangesEnabled:YES];
    
    [request setCompletionBlock:^{
        // Use when fetching text data
        NSString *responseString = [request responseString];
        NSDictionary *response = [responseString JSONValue];
        
        if ([[response objectForKey:@"status_code"] intValue] == 0)
        {
            [[NSApp delegate] setMyfriend:[_items objectAtIndex:[cell tag]]];
            [[[NSApp delegate] manager] addBuddy:[fr.jabberName stringByAppendingString:@"@ohthou.com"] withNickname:fr.name];
            [[[NSApp delegate] manager] sendMessageToUser:[fr.jabberName stringByAppendingString:@"@ohthou.com"] message:@"accept"];
            [self close];
        } else {
            // TODO: show error
        }

        [self setSaveChangesEnabled:NO];
        
        [_tableView reloadData];
        [_tableView setNeedsDisplay];
    }];
    [request setFailedBlock:^{
        [self setSaveChangesEnabled:NO];
        
        NSError *error = [request error];
        [self.window presentError:error];
    }];
    [request startAsynchronous];
}

#pragma mark -
#pragma mark TableView Datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_items count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    Friend *f = (Friend*) [_items objectAtIndex:row];
    if ([[tableColumn identifier] isEqualToString:@"text"])
    {
        return f.name;
    }
    else if ([[tableColumn identifier] isEqualToString:@"image"])
    {
        return f.image;
    }
    return nil;
}

- (void) dealloc
{
    [_items release];
    [super dealloc];
}


@end
