//
//  MPPaletteViewController.h
//  Manuscripts
//
//  Created by Matias Piipari on 21/12/2012.
//  Copyright (c) 2012 Manuscripts.app Limited. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MPInspectorViewController, JKConfiguration;

@interface MPPaletteViewController : NSViewController

@property (weak, nullable) IBOutlet NSButton *infoButton;

@property (weak, nullable) IBOutlet NSPopover *infoPopover;

@property (weak, nullable) IBOutlet MPInspectorViewController *inspectorController;
@property (weak, nullable) NSOutlineView *inspectorOutlineView;
@property (weak, nullable) JKConfiguration *configuration;

/** The set of allowed palette modes. */
+ (nonnull NSSet *)allowedConfigurationModes;

/** The name of the default string. Base class implementation returns 'normal', overloadable by subclasses. */
@property (readonly, copy, nonnull) NSString *defaultConfigurationMode;

@property (readwrite, copy, nonnull) NSString *configurationMode;
- (void)setConfigurationMode:(nonnull NSString *)configurationMode animated:(BOOL)animated;

- (IBAction)getInfo:(nullable id)sender;

@end


@protocol MPInspectorPaletteSizing <NSObject>
@optional
- (CGFloat)fittingPaletteHeight;

@end