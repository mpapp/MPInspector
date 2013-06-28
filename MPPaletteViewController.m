//
//  MPPaletteViewController.m
//
//  Created by Matias Piipari on 21/12/2012.
//  Copyright (c) 2012 Manuscripts.app Limited. All rights reserved.

#import "MPPaletteViewController.h"
#import "MPInspectorViewController.h"

#import "MTRefreshable.h"
    
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
        self.mode = MPPaletteViewModeNormal;
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
#pragma mark Refresh

- (NSArray *)displayedItems
{
    if ([self.delegate respondsToSelector:@selector(displayedItemsForPaletteViewController:)])
        return [self.delegate displayedItemsForPaletteViewController:self];
        
    return @[];
}

-(void)onRefresh
{
	[self refresh];
}

- (void)refresh
{
    [self refreshForced:NO];
}

- (void)refreshForced:(BOOL)forced
{
    // override in subclass and update view based on the displayedItems,
    // then call super to layout the subviews
    [self layoutSubviews];
}

- (void)layoutSubviews
{
    // override in subclass and update view layout based on the displayedItems
}

- (BOOL)shouldDisplayPalette
{
    // give the opportunity to subclasses to make clear that displaying the
    // palette with the current displayed items does not make sense
    return YES;
}


#pragma mark -
#pragma mark Configuration

- (NSString *)headerTitle
{
    // subclasses should override this method to provide a meaningful header title,
    // which is shown in the outlineview header
    return @"Journal Article";
}

- (CGFloat)height
{
    // subclasses can override this method to provide a different view height per mode
    // by default we return the height of the view provided by the view controller 
    
    if (_height < 1.0)
    {
        return NSHeight(self.view.frame);
    }
    
    return _height;
}

- (void)setHeight:(CGFloat)height
{
    _height = height;
}

- (void)setMode:(MPPaletteViewMode)mode animate:(BOOL)animate;
{    
    if (self.mode == mode) return;
    
    // subclasses can override setMode: to update or change the view layout 
    self.mode = mode;
    
    [self.delegate noteHeightOfPaletteViewControllerChanged:self animate:animate];
}

@end
