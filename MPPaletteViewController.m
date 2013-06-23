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

@synthesize delegate = _delegate;
@synthesize height = _height;

- (instancetype)initWithDelegate:(id <MPPaletteViewControllerDelegate>)aDelegate identifier:(NSString *)identifier
{
    return [self initWithDelegate:aDelegate identifier:identifier nibName:self.defaultNibName];
}

- (instancetype)initWithDelegate:(id <MPPaletteViewControllerDelegate>)aDelegate identifier:(NSString *)identifier nibName:(NSString *)aName
{
    if (self = [super initWithNibName:aName bundle:nil])
    {
        self.delegate = aDelegate;
        self.identifier = identifier;
        self.configuration.mode = [self defaultConfigurationMode];
    }
    return self;
}

- (void)dealloc
{
    _delegate = nil;
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
#pragma mark Configuration

// TODO: set configuration

- (NSString *)title
{
    return @"Journal Article";
}

- (CGFloat)height
{
//    // if a modes dictionary is set, return the height from the currently selected mode
//    if (_modes)
//    {
//        return [_modes[_mode][@"height"] floatValue];
//    }
    
    return 200.f;//_height;
}

- (void)setHeight:(CGFloat)height
{
    _height = height;
}




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
