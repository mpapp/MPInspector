//
//  MPInspectorViewController.h
//
//  Created by Matias Piipari on 17/09/2012.
//  Copyright (c) 2012 Matias Piipari. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PARViewController.h"

@class KGNoiseView, DMTabBar, JKOutlineView;
@class MPPaletteViewController;
@class MPManuscriptsPackageController;

/** A view controller for the Manuscripts.app main window's inspector. */
@interface MPInspectorViewController : PARViewController <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (weak) IBOutlet KGNoiseView *backgroundView;
@property (weak) IBOutlet DMTabBar *tabBar;
@property (weak) IBOutlet NSTabView *tabView;

@property (strong) NSString *selectionType;
@property (readonly, strong) NSDictionary *palettesBySelectionType;

- (CGFloat)heightForPaletteViewController:(MPPaletteViewController *)paletteViewController;
- (void)noteHeightOfPaletteViewControllerChanged:(MPPaletteViewController *)paletteViewController;

- (void)setPaletteContainerWithKey:(NSString *)key;

- (void)configurePaletteViewController:(MPPaletteViewController *)vc;

@end