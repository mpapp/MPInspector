//
//  MPPaletteViewController.m
//  Manuscripts
//
//  Created by Matias Piipari on 21/12/2012.
//  Copyright (c) 2012 Manuscripts.app Limited. All rights reserved.
//

#import "MPManuscriptsPaletteViewController.h"
#import "MPInspectorViewController.h"

#import "JKConfiguration.h"

@interface MPPaletteViewController ()
@end

@implementation MPPaletteViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.configuration.mode = [self defaultConfigurationMode];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)getInfo:(id)sender
{
    [self.infoPopover showRelativeToRect:[self.infoButton bounds] ofView:self.infoButton preferredEdge:NSMaxYEdge];
}

- (void)setConfigurationMode:(NSString *)configurationMode
{
    [self setConfigurationMode:configurationMode animated:NO];
}

- (void)setConfigurationMode:(NSString *)configurationMode animated:(BOOL)animated
{
    assert([self.class.allowedConfigurationModes containsObject:configurationMode]);
    if ([self.configuration.mode isEqualToString:configurationMode]) return;
    
    self.configuration.mode = configurationMode;
    [self.inspectorController noteHeightOfPaletteViewControllerChanged:self];
}

- (NSString *)configurationMode
{
    return _configuration.mode;
}

+ (NSSet *)allowedConfigurationModes
{
    static NSSet *_allowedConfigurationModes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _allowedConfigurationModes = [NSSet setWithArray:@[ @"normal" ]];
    });
    
    return _allowedConfigurationModes;
}

- (NSString *)defaultConfigurationMode { return @"normal"; }

@end
