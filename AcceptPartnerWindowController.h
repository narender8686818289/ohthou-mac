//
//  AcceptPartnerWindowController.h
//  OhThou
//
//  Created by Ulf Schwekendiek on 11/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AcceptPartnerWindowController : NSWindowController<NSTableViewDataSource, NSTableViewDelegate> {
    IBOutlet NSTableView *_tableView;
    IBOutlet NSProgressIndicator *_spinner;
    IBOutlet NSTextField *_saveChangesLabel;

    
    NSMutableArray *_items;
}

- (void) setSaveChangesEnabled:(BOOL)enabled;
- (void) refreshDatasource;
- (void) runRefreshDatasourceInterval;
@end
