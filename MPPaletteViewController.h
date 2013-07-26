//
//  MPPaletteViewController.h
//
//  Created by Matias Piipari on 21/12/2012.
//  Copyright (c) 2012 Manuscripts.app Limited. All rights reserved.

#import "PARViewController.h"

typedef NS_ENUM(NSInteger, MPPaletteViewMode)
{
	MPPaletteViewModeNormal   = 0,
    MPPaletteViewModeEdit     = 1,
    MPPaletteViewModeExpanded = 2
};

@protocol MPPaletteViewControllerDelegate;

@class MPInspectorViewController, JKConfiguration;

@interface MPPaletteViewController : PARViewController
{    
    __unsafe_unretained id <MPPaletteViewControllerDelegate> delegate;
}

@property (strong) NSString *identifier;
@property (assign) id <MPPaletteViewControllerDelegate> delegate;

@property (readonly) NSArray *displayedItems;
@property (readonly) NSString *headerTitle;
@property (readonly) BOOL shouldDisplayPalette;

@property (assign) CGFloat height;

@property (assign) MPPaletteViewMode mode;
- (void)setMode:(MPPaletteViewMode)mode animate:(BOOL)animate;

- (instancetype)initWithDelegate:(id <MPPaletteViewControllerDelegate>)aDelegate identifier:(NSString *)identifier;
- (instancetype)initWithDelegate:(id <MPPaletteViewControllerDelegate>)aDelegate identifier:(NSString *)identifier nibName:(NSString *)aName;

- (void)refresh;
- (void)refreshForced:(BOOL)forced;
- (void)layoutSubviews;

@end

@protocol MPPaletteViewControllerDelegate <NSObject>
@required
- (NSArray *)displayedItemsForPaletteViewController:(MPPaletteViewController *)paletteViewController;
@optional
- (void)noteHeightOfPaletteViewControllerChanged:(MPPaletteViewController *)paletteViewController animate:(BOOL)animate;
@end


#define MTLogCaller(maxLines)\
NSArray *allSymbols = [NSThread callStackSymbols], *symbols;\
if (maxLines > 0) symbols = [allSymbols subarrayWithRange:NSMakeRange(0, MIN((allSymbols.count), maxLines))];\
else symbols = [allSymbols subarrayWithRange:NSMakeRange(0, allSymbols.count)];\
NSLog(@"Current call stack:\n%@", [symbols componentsJoinedByString:@"\n"]);