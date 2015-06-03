//
//  MPPaletteViewController.h
//  Manuscripts
//
//  Created by Matias Piipari on 21/12/2012.
//  Copyright (c) 2012 Manuscripts.app Limited. All rights reserved.
//

#import "PARViewController.h"


@class MPInspectorViewController, JKConfiguration;


@interface MPPaletteViewController : PARViewController

@property (weak) IBOutlet NSButton *infoButton;

@property (weak) IBOutlet NSPopover *infoPopover;

@property (weak) IBOutlet MPInspectorViewController *inspectorController;
@property (weak) NSOutlineView *inspectorOutlineView;
@property (weak) JKConfiguration *configuration;

/** The set of allowed palette modes. */
+ (NSSet *)allowedConfigurationModes;

/** The name of the default string. Base class implementation returns 'normal', overloadable by subclasses. */
@property (readonly, copy) NSString *defaultConfigurationMode;

@property (readwrite, copy) NSString *configurationMode;
- (void)setConfigurationMode:(NSString *)configurationMode animated:(BOOL)animated;

- (IBAction)getInfo:(id)sender;

@end


@protocol MPInspectorPaletteSizing <NSObject>
@optional
- (CGFloat)fittingPaletteHeight;

@end