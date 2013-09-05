//
//  MPPaletteViewController.h
//
//  Created by Matias Piipari on 21/12/2012.
//  Copyright (c) 2012 Manuscripts.app Limited. All rights reserved.

#import <Cocoa/Cocoa.h>

#import "PARViewController.h"
#import "MPPaletteViewController.h"

@class DMTabBar, JKOutlineView;
@class MPPaletteViewController;

@interface MPInspectorViewController : PARViewController <NSOutlineViewDataSource, NSOutlineViewDelegate, MPPaletteViewControllerDelegate>

@property (weak) IBOutlet DMTabBar *tabBar;
@property (weak) IBOutlet NSTabView *tabView;

@property (readonly, getter=isEditing) BOOL editing;
@property (strong) NSString *entityType;

@property (readonly) NSArray *displayedItems;

@property (readwrite) NSInteger selectedTabIndex;
@property (readwrite) NSString *selectedTabIdentifier;

- (void)endEditing;
- (void)loadConfiguration;
- (void)refresh;
- (void)refreshForced:(BOOL)forced;

- (IBAction)selectNextInspectorTab:(id)sender;
- (IBAction)selectPreviousInspectorTab:(id)sender;
- (IBAction)selectFirstInspectorTab:(id)sender;
@end


@protocol MTDoubleClickableItem <NSObject>

- (IBAction)doubleClickAction:(id)sender;

@end