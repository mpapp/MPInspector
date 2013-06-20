//
//  MPInspectorViewController.h
//
//  Created by Matias Piipari on 17/09/2012.
//  Copyright (c) 2012 Matias Piipari. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PARViewController.h"

@class DMTabBar, JKOutlineView;
@class MPPaletteViewController;

@interface MPInspectorViewController : PARViewController <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (weak) IBOutlet NSView *backgroundView;
@property (weak) IBOutlet DMTabBar *tabBar;
@property (weak) IBOutlet NSTabView *tabView;

@property (strong) NSString *selectionType;
@property (readonly, strong) NSDictionary *palettesBySelectionType;

- (CGFloat)heightForPaletteViewController:(MPPaletteViewController *)paletteViewController;
- (void)noteHeightOfPaletteViewControllerChanged:(MPPaletteViewController *)paletteViewController;

- (void)setPaletteContainerWithKey:(NSString *)key;

- (void)configurePaletteViewController:(MPPaletteViewController *)vc;

@end