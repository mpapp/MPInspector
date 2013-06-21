//
//  MPPaletteViewController.m
//
//  Created by Matias Piipari on 21/12/2012.
//  Copyright (c) 2012 Manuscripts.app Limited. All rights reserved.

#import "MPPaletteViewController.h"
#import "MPInspectorViewController.h"

#import "JKConfiguration.h"

@interface MPPaletteViewController ()
@property (readonly) NSString *defaultNibName;
@end

@implementation MPPaletteViewController

- (instancetype)initWithDelegate:(id <MPPaletteViewControllerDelegate>)aDelegate
{
    return [self initWithDelegate:aDelegate nibName:self.defaultNibName];
}

- (instancetype)initWithDelegate:(id <MPPaletteViewControllerDelegate>)aDelegate nibName:(NSString *)aName
{
    if (self = [super initWithNibName:aName bundle:nil])
    {
        self.delegate = aDelegate;
        self.configuration.mode = [self defaultConfigurationMode];
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)defaultNibName
{
    // by default use the class name but strip the Controller part
    // MPPaletteViewController -> MPPaletteView.nib
    NSString *className = NSStringFromClass([self class]);
    
    NSRange r = [className rangeOfString:@"Controller" options:NSCaseInsensitiveSearch];
	return (r.location != NSNotFound ? [className substringToIndex:r.location] : className);
}


#pragma mark -
#pragma mark Configuration Modes

- (void)setConfigurationMode:(NSString *)configurationMode
{
    [self setConfigurationMode:configurationMode animated:NO];
}

- (void)setConfigurationMode:(NSString *)configurationMode animated:(BOOL)animated
{
    assert([self.allowedConfigurationModes containsObject:configurationMode]);
    
    if ([self.configuration.mode isEqualToString:configurationMode]) return;
    
    self.configuration.mode = configurationMode;
    [self.delegate noteHeightOfPaletteViewControllerChanged:self];
}

- (NSString *)configurationMode
{
    return _configuration.mode;
}

- (NSSet *)allowedConfigurationModes
{
    return [NSSet setWithArray:[_configuration.modes allKeys]];
}

- (NSString *)defaultConfigurationMode
{
    return @"normal";
}

@end
