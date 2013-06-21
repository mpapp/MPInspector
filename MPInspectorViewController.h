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

@property (strong) NSString *entityType;


@property (readonly, strong) NSDictionary *paletteControllersByEntityType;

@end