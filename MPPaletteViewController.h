//
//  MPPaletteViewController.h
//
//  Created by Matias Piipari on 21/12/2012.
//  Copyright (c) 2012 Manuscripts.app Limited. All rights reserved.

#import "PARViewController.h"

@protocol MPPaletteViewControllerDelegate;

@class MPInspectorViewController, JKConfiguration;

@interface MPPaletteViewController : PARViewController
{
    __unsafe_unretained id <MPPaletteViewControllerDelegate> delegate;
}

@property (assign) id <MPPaletteViewControllerDelegate> delegate;
@property (weak) JKConfiguration *configuration;

@property (readonly) NSSet *allowedConfigurationModes;
@property (readonly) NSString *defaultConfigurationMode;

@property (readwrite, copy) NSString *configurationMode;
- (void)setConfigurationMode:(NSString *)configurationMode animated:(BOOL)animated;

- (instancetype)initWithDelegate:(id <MPPaletteViewControllerDelegate>)aDelegate;
- (instancetype)initWithDelegate:(id <MPPaletteViewControllerDelegate>)aDelegate nibName:(NSString *)aName;

@end

@protocol MPPaletteViewControllerDelegate <NSObject>
@optional
- (void)noteHeightOfPaletteViewControllerChanged:(MPPaletteViewController *)paletteViewController;
@end