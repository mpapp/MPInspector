//

//  MPInspectorViewController.h
//
//  Created by Matias Piipari on 17/09/2012.
//  Copyright (c) 2012 Matias Piipari. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PARViewController.h"

@class DMTabBar; //, JKOutlineView;
@class MPPaletteViewController;
@class MPManuscriptsPackageController;

/** A view controller for the Manuscripts.app main window's inspector. */
@interface MPInspectorViewController : PARViewController <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (weak) IBOutlet NSView *backgroundView;
@property (weak) IBOutlet NSTabView *tabView;

@property (strong) NSString *selectionType;
@property (readonly, strong) NSDictionary *palettesBySelectionType;

- (CGFloat)heightForPaletteViewController:(MPPaletteViewController *)paletteViewController;
- (void)noteHeightOfPaletteViewControllerChanged:(MPPaletteViewController *)paletteViewController;

- (NSOutlineView *)ensurePaletteContainerWithKeyExists:(NSString *)key;

- (void)configurePaletteViewController:(MPPaletteViewController *)vc;

@end

#pragma mark - 

@interface MPInspectorOutlineView : NSOutlineView
@end