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

@property (strong) NSString *identifier;
@property (assign) id <MPPaletteViewControllerDelegate> delegate;

@property (readonly) NSString *title;
@property (assign) CGFloat height;

// TODO: configuration
// TODO: displayedItems

@property (weak) JKConfiguration *configuration;

@property (readonly) NSSet *allowedConfigurationModes;
@property (readonly) NSString *defaultConfigurationMode;

@property (readwrite, copy) NSString *configurationMode;
- (void)setConfigurationMode:(NSString *)configurationMode animated:(BOOL)animated;

- (instancetype)initWithDelegate:(id <MPPaletteViewControllerDelegate>)aDelegate identifier:(NSString *)identifier;
- (instancetype)initWithDelegate:(id <MPPaletteViewControllerDelegate>)aDelegate identifier:(NSString *)identifier nibName:(NSString *)aName;

@end

@protocol MPPaletteViewControllerDelegate <NSObject>
@optional
- (void)noteHeightOfPaletteViewControllerChanged:(MPPaletteViewController *)paletteViewController;
@end