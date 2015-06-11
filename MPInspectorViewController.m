//
//  MPInspectorViewController.m
//
//  Created by Matias Piipari on 17/09/2012.
//  Copyright (c) 2012 Matias Piipari. All rights reserved.
//

#import "MPInspectorViewController.h"

#import "MPPaletteViewController.h"

#import "DMTabBar.h"
#import "DMTabBarItem.h"

#import "JKConfigurationHeaderRowView.h"
#import "JKConfigurationHeaderView.h"
#import "JKConfigurationGroup.h"
#import "JKConfiguration.h"

#import "RegexKitLite.h"

#import <FeatherExtensions/FeatherExtensions.h>
#import <MPFoundation/MPFoundation.h>

@interface MPInspectorViewController ()
{
    NSString *_selectionType;
    MPManuscriptsPackageController *_packageController;
}

@property (strong) NSDictionary *palettesByEntityType;
@property (strong) NSDictionary *palettesBySelectionType;

@property (strong) NSMutableDictionary *configurationsByPaletteNibName;
@property (strong) NSDictionary *palettesForTabTitle;

@property (readwrite) BOOL hasAwoken;
@end

@implementation MPInspectorViewController

- (void)loadView
{
    [super loadView];
    
    NSURL *paletteConfigURL = [[NSBundle mainBundle] URLForResource:@"palettes" withExtension:@"json"];
    assert(paletteConfigURL);
    
    NSError *err = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:
                          [[NSData alloc] initWithContentsOfURL:paletteConfigURL]
                                    options:0 error:&err];
    NSAssert(!err, @"Unexpected error: %@", err);
    NSParameterAssert(dict);
    
    self.palettesByEntityType = dict[@"palettes"];
    self.palettesBySelectionType = dict[@"selectionType"];
    
    _configurationsByPaletteNibName = [NSMutableDictionary dictionaryWithCapacity:20];
    
    _backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    
    assert(_palettesBySelectionType);
    
    assert(_backgroundView);
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(preferredScrollerStyleDidChange:)
                                               name:NSPreferredScrollerStyleDidChangeNotification
                                             object:nil];
    
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (NSString *)selectionType
{
    return _selectionType;
}

- (void)setSelectionType:(NSString *)selectionType
{
    _selectionType = selectionType;
    [self.view.window invalidateRestorableState];
    [self setUpPaletteSectionsForSelectionType:selectionType];
}

#pragma mark - Palette container setup

- (NSOutlineView *)newPaletteContainerForTabViewIndex:(NSUInteger)viewIndex identifier:(NSString *)identifier
{
    NSSize superViewSize = self.view.frame.size;
    
    NSRect frame = NSMakeRect(0, 0, superViewSize.width, superViewSize.height);
    //JKOutlineView *paletteContainer = [[JKOutlineView alloc] initWithFrame:frame];
    NSOutlineView *paletteContainer = [[MPInspectorOutlineView alloc] initWithFrame:frame];
    paletteContainer.autoresizesSubviews = YES;
    //paletteContainer.autosaveTableColumns = NO;
    //paletteContainer.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    paletteContainer.headerView = nil;
    paletteContainer.floatsGroupRows = NO;
    
    [paletteContainer setIndentationMarkerFollowsCell:NO];
    [paletteContainer setIndentationPerLevel:0];
    [paletteContainer setBackgroundColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.0]];
    [paletteContainer setGridColor:[NSColor redColor]]; //clearColor]];
    [paletteContainer setGridStyleMask:NSTableViewGridNone];
    [paletteContainer setFocusRingType:NSFocusRingTypeNone];
    [paletteContainer setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    [paletteContainer setAutosaveTableColumns:NO];
    paletteContainer.columnAutoresizingStyle = NSTableViewReverseSequentialColumnAutoresizingStyle;
    
    paletteContainer.identifier = identifier;
    
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"MPInspectorColumn"];
    [column setEditable: NO];
    column.resizingMask = NSTableColumnAutoresizingMask;
    column.editable = NO;
    column.width = 320.0;
    [paletteContainer addTableColumn: column];
    //paletteContainer.wantsLayer = YES;
    
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];
    scrollView.documentView = paletteContainer;
    scrollView.autohidesScrollers = YES;
    scrollView.drawsBackground = YES;
    
    //scrollView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    scrollView.autoresizesSubviews = YES;
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.hasHorizontalScroller = NO;
    scrollView.horizontalScrollElasticity = NSScrollElasticityNone;
    scrollView.hasVerticalScroller = YES;
    scrollView.verticalScrollElasticity = NSScrollElasticityAllowed;

    scrollView.usesPredominantAxisScrolling = YES;
    scrollView.contentView.copiesOnScroll = YES;
    //scrollView.wantsLayer = YES;
    
    //    [paletteContainer setHeaderView:nil];
    
    [paletteContainer registerNib:[[NSNib alloc] initWithNibNamed:@"MPInspectorPaletteRowView" bundle:nil]
                    forIdentifier:@"MPInspectorPaletteRowView"];
    [paletteContainer registerNib:[[NSNib alloc] initWithNibNamed:@"MPInspectorPaletteHeaderView" bundle:nil]
                    forIdentifier:@"MPInspectorPaletteHeaderView"];
    [paletteContainer registerNib:[[NSNib alloc] initWithNibNamed:@"MPInspectorPaletteHeaderRowView" bundle:nil]
                    forIdentifier:@"MPInspectorPaletteHeaderRowView"];
    
    scrollView.hidden = NO;
    
    NSView *tabItemView = [_tabView tabViewItemAtIndex:viewIndex].view;
    [tabItemView addSubviewConstrainedToSuperViewEdges:scrollView
                                             topOffset:-2 rightOffset:0
                                          bottomOffset:0 leftOffset:0];
    [tabItemView layoutSubtreeIfNeeded];
    [self adjustColumnWidthsForPaletteContainer:paletteContainer];
    
    NSParameterAssert(paletteContainer);
    return paletteContainer;
}

- (void)preferredScrollerStyleDidChange:(NSNotification *)notification {
    for (NSString *key in [self.palettesForTabTitle allKeys])
    {
        NSOutlineView *paletteContainer = [self valueForKey:key];
        if (paletteContainer) {
            [self adjustColumnWidthsForPaletteContainer:paletteContainer];
        }
    }
    
    for (NSView *tabItemView in [[self.tabView tabViewItems] valueForKey:@"view"]) {
        [tabItemView setNeedsLayout:YES];
        [tabItemView setNeedsDisplay:YES];
    }
    
    [self.view setNeedsLayout:YES];
    [self.view setNeedsDisplay:YES];
}

/** Adjusts the column width and returns the scroller width that it was adjusted by. */
- (CGFloat)adjustColumnWidthsForPaletteContainer:(NSOutlineView *)paletteContainer {
    CGFloat preferredScrollerWidth = [NSScroller scrollerWidthForControlSize:NSRegularControlSize
                                                               scrollerStyle:NSScroller.preferredScrollerStyle];
    
    NSTableColumn *column = paletteContainer.tableColumns[0];
    
    //if (NSScroller.preferredScrollerStyle == NSScrollerStyleLegacy) {
        column.width = paletteContainer.frame.size.width - preferredScrollerWidth;
    //}
    //else {
    //    column.width = paletteContainer.frame.size.width - 15.0f;
    //}
    
    return preferredScrollerWidth;
}

- (NSString *)controllerKeyForPaletteNibName:(NSString *)nibName {
    // MPFoobarPaletteController => foobarPaletteController
    NSString *prefixlessControllerName = [nibName stringByReplacingOccurrencesOfRegex:@"^MP" withString:@""];
    NSMutableString *str = [NSMutableString stringWithString:prefixlessControllerName];
    [str replaceOccurrencesOfRegex:@"^(.)"
                        usingBlock:^NSString *(NSInteger captureCount,
                                                      NSString *const __unsafe_unretained *capturedStrings,
                                                      const NSRange *capturedRanges,
                                                      volatile BOOL *const stop)
    {
        assert(captureCount > 0);
        return [capturedStrings[0] lowercaseString];
    }];
    
    return [str copy];
}

- (NSOutlineView *)ensurePaletteContainerWithKeyExists:(NSString *)key {
    NSString *title = [key stringByReplacingOccurrencesOfRegex:@"PaletteContainer$" withString:@""];
    NSArray *tabs = self.palettesBySelectionType[self.selectionType]; assert(tabs);
    __block NSDictionary *configurationForKey = nil;
    __block NSUInteger tabIndex = NSNotFound;
    [tabs enumerateObjectsUsingBlock:^(NSDictionary *tabConfiguration, NSUInteger idx, BOOL *stop) {
        if ([tabConfiguration[@"title"] isEqualToString:title]) {
            tabIndex = idx;
            configurationForKey = tabConfiguration;
            *stop = YES;
        }
    }];
    NSParameterAssert(tabIndex != NSNotFound && configurationForKey);
    
    if (![self valueForKey:key]) {
        NSOutlineView *outlineView = [self newPaletteContainerForTabViewIndex:tabIndex identifier:key];
        [self setValue:outlineView forKey:key];
        
        return outlineView;
    }
    
    return [self valueForKey:key];
}

- (JKConfigurationGroup *)configurationGroupForPaletteContainerKey:(NSString *)paletteContainerKey
                                                    paletteNibName:(NSString *)paletteNibName
                                                             modes:(NSDictionary *)dictionary {
    NSString *controllerKey = [self controllerKeyForPaletteNibName:paletteNibName];
    MPPaletteViewController *vc = [self valueForKey:controllerKey];
    assert(vc && [vc isKindOfClass:[MPPaletteViewController class]]);
    
    assert(vc.title);
    
    JKConfigurationGroup *group = [JKConfigurationGroup configurationWithTitle:vc.title];
    
    
    JKConfiguration *paletteConfig = _configurationsByPaletteNibName[paletteNibName];
    
    if (!paletteConfig)
    {
        paletteConfig = [JKConfiguration configurationWithNibName:paletteNibName modes:dictionary ];
        _configurationsByPaletteNibName[paletteNibName] = paletteConfig;
    }
    
    assert(dictionary);
    group.children = @[ paletteConfig ];
    
    NSOutlineView *outlineView = [self valueForKey:paletteContainerKey];
    [outlineView registerNib:[[NSNib alloc] initWithNibNamed:paletteNibName bundle:nil] forIdentifier:paletteNibName];
    
    return group;
}

- (void)setUpPaletteSectionsForSelectionType:(NSString *)selectionType
{
    NSArray *tabs = self.palettesBySelectionType[selectionType]; assert(tabs);
    NSMutableDictionary *palettesForTabs = [NSMutableDictionary dictionaryWithCapacity:tabs.count];
    
    for (NSUInteger i = 0; i < tabs.count; i++)
    {
        NSDictionary *tabConfiguration = self.palettesBySelectionType[selectionType][i];
        NSString *title = tabConfiguration[@"title"]; assert(title);
        NSArray *paletteNames = tabConfiguration[@"palettes"];
        
        NSString *paletteContainerKey = [title stringByAppendingFormat:@"PaletteContainer"];
        
        [self ensurePaletteContainerWithKeyExists:paletteContainerKey];
        
        NSMutableArray *groups = [NSMutableArray arrayWithCapacity:paletteNames.count];
        
        for (NSString *paletteName in paletteNames)
        {
            NSDictionary *palette = self.palettesByEntityType[paletteName];
            
            NSString *paletteName = palette[@"title"]; assert(paletteName);
            
            assert(palette[@"modes"]);
            
            NSString *paletteNibName = [paletteName stringByAppendingFormat:@"PaletteController"];
            
            JKConfigurationGroup *configGroup
            = [self configurationGroupForPaletteContainerKey:paletteContainerKey
                                              paletteNibName:paletteNibName modes:palette[@"modes"]];
            
            [groups addObject:configGroup];
        }
        
        palettesForTabs[paletteContainerKey] = groups;
    }
    self.palettesForTabTitle = palettesForTabs;
    
    for (NSString *key in [self.palettesForTabTitle allKeys])
    {
        NSOutlineView *paletteContainer = [self valueForKey:key];
        paletteContainer.delegate = self;
        paletteContainer.dataSource = self;
        [paletteContainer reloadData];
        [paletteContainer expandItem:nil expandChildren:YES];
    }
}

#pragma mark - Outline view configuration

- (BOOL) outlineView:(NSOutlineView *)outlineView
         isGroupItem:(id)item {
    return [item isKindOfClass:[JKConfigurationGroup class]];
}


- (NSView *)outlineView:(NSOutlineView *)outlineView
     viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    //
    // Palette header cell views
    //
    if ([self outlineView:outlineView isGroupItem:item])
    {
		JKConfigurationHeaderView *headerView = [outlineView makeViewWithIdentifier:@"MPInspectorPaletteHeaderView" owner:self];
        
        assert([headerView isKindOfClass:[JKConfigurationHeaderView class]]);
        headerView.textField.stringValue = [item title];
        
        // inverted
        //headerView.headerGradientStartColor = [NSColor manuscriptsPaletteSectionHeaderGradientStartColor];
        //headerView.headerGradientEndColor = [NSColor manuscriptsPaletteSectionHeaderGradientEndColor];
        
        return headerView;
	}
    
    //
    // Palette cell views
    //
    NSAssert([item isKindOfClass:[JKConfiguration class]], @"Unexpected item: %@ (%@)", item, [item class]);
	
	JKConfiguration *config = item;
    assert(config.nibName);
    
    assert([outlineView registeredNibsByIdentifier][config.nibName]);
    
    MPPaletteViewController *vc = [self valueForKey:[self controllerKeyForPaletteNibName:config.nibName]];
    assert(vc); // matching Nib & view controller name
    assert(vc.inspectorController == self);
    
    // MUST set before packageController.
    vc.inspectorOutlineView = outlineView;
    config.itemController = vc;
    
    assert (!vc.configuration || vc.configuration == config);
    
    vc.configuration = item;
    vc.configuration.modes = [item modes];
    vc.configuration.mode = [vc defaultConfigurationMode];
    assert(vc.configuration.mode);
    
    [self configurePaletteViewController:vc];
    
	NSTableCellView *view = (NSTableCellView *)vc.view;
    //view.wantsLayer = YES;
    
    assert ([view isKindOfClass:[NSTableCellView class]] && [view class] != [NSTableCellView class]);
    
    return view;
}

- (void)configurePaletteViewController:(MPPaletteViewController *)vc
{
    // Overload in subclass.
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	if ([self outlineView:outlineView isGroupItem:item])
    {
		return 25.f;
	}
	
	JKConfiguration *config = item;
    
    if (config.itemController && [config.itemController isKindOfClass:MPPaletteViewController.class])
    {
        CGFloat h = [self heightForPaletteViewController:config.itemController];
        MPAssertTrue(h >= 1.0);
        if (h >= 1.0) // Outline view throws a fit for row heights less than 1.0
            return h;
    }
    
    // If palette view controller hasn't yet been set up, or returned a weird value above, use static height value from configuration
	if (config.nibName)
    {
        CGFloat h = [config.modes[config.mode][@"height"] floatValue];
        MPAssertTrue(h >= 1.0);
        if (h >= 1.0) // Outline view throws a fit for row heights less than 1.0
            return h;
	}
	
	return 28.0f;
}

- (CGFloat)heightForPaletteViewController:(MPPaletteViewController *)paletteViewController
{
    if ([paletteViewController respondsToSelector:@selector(fittingPaletteHeight)])
    {
        CGFloat h = [(id)paletteViewController fittingPaletteHeight];
        if (h >= 1.0)
            return h;
    }
    
    NSNumber *h = paletteViewController.configuration.modes[paletteViewController.configuration.mode][@"height"];
    MPAssertNotNil(h);
    return [h doubleValue];
}

- (void)noteHeightOfPaletteViewControllerChanged:(MPPaletteViewController *)paletteViewController
{
    MPAssertNotNil(paletteViewController.inspectorOutlineView);
    NSInteger rowIndex = [paletteViewController.inspectorOutlineView rowForView:paletteViewController.view.superview];
    
    if (rowIndex < 0)
        return;
    MPAssertTrue(rowIndex >= 0);
    
    [paletteViewController.inspectorOutlineView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:rowIndex]];
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
    BOOL isHeader = [self outlineView:outlineView isGroupItem:item];
    NSTableRowView *rowView = nil;
    
	if (isHeader)
    {
        rowView = [outlineView makeViewWithIdentifier:@"MPInspectorPaletteHeaderRowView" owner:nil];
        if (!rowView) {
            rowView = [[JKConfigurationHeaderRowView alloc] initWithFrame:CGRectZero];
            rowView.identifier = @"MPInspectorPaletteHeaderRowView";
        }
    }
    else
    {
        rowView = [outlineView makeViewWithIdentifier:@"MPInspectorPaletteRowView" owner:nil];
        if (!rowView) {
            rowView = [[JKConfigurationRowView alloc] initWithFrame:CGRectZero];
            rowView.identifier = @"MPInspectorPaletteRowView";
        }
	}
	
    assert(rowView);
	return rowView;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!outlineView.dataSource) return 0;
    
    if (!item)
    {
        NSArray *palettes = self.palettesForTabTitle[outlineView.identifier]; assert(palettes);
        //assert(palettes.count > 0);
        return palettes.count;
    }
    
    if ([self outlineView:outlineView isGroupItem:item]) return 1;
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item)
    {
        NSArray *palettes = self.palettesForTabTitle[outlineView.identifier];
        assert(palettes && palettes.count > index);
        return palettes[index];
    }
    
    if ([self outlineView:outlineView isGroupItem:item])
    {
        assert([[item children] count] == 1 && index == 0);
        JKConfigurationGroup *group = (JKConfigurationGroup *)item;
        return group.children[index];
    }
    
    assert([item children] == 0);
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return YES; //return [self outlineView:outlineView isGroupItem:item];
}

@end

#pragma mark -

@implementation MPInspectorOutlineView

// comment this out to make the outline view behave as if convertAutoresizeMasktoConstrints is not on.
//- (void)resizeWithOldSuperviewSize:(NSSize)oldSize {
    // nop..
//}

- (void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
}

@end