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

#import "KGNoise.h"

#import "JKConfigurationHeaderRowView.h"
#import "JKConfigurationHeaderView.h"
#import "JKConfigurationGroup.h"
#import "JKConfiguration.h"
#import "JKOutlineView.h"

#import "NSView+MPExtensions.h"

#import "RegexKitLite.h"

#import "JSONKit.h"

@interface MPInspectorViewController ()
{
    NSString *_selectionType;
    MPManuscriptsPackageController *_packageController;
}

@property (strong) NSDictionary *palettesByEntityType;
@property (strong) NSMutableDictionary *configurationsByPaletteNibName;
@property (strong) NSDictionary *palettesBySelectionType;
@property (strong) NSDictionary *palettesForTabTitle;

@property (readwrite) BOOL hasAwoken;
@end

@implementation MPInspectorViewController

- (void)loadView
{
    [super loadView];
    
    NSURL *paletteConfigURL = [[NSBundle mainBundle] URLForResource:@"palettes" withExtension:@"json"];
    assert(paletteConfigURL);
    
    NSDictionary *dict = [[[NSData alloc] initWithContentsOfURL:paletteConfigURL] objectFromJSONData];
    self.palettesByEntityType = dict[@"palettes"];
    self.palettesBySelectionType = dict[@"selectionType"];
    
    _configurationsByPaletteNibName = [NSMutableDictionary dictionaryWithCapacity:20];
    
    _backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    
    assert(_palettesBySelectionType);
    
    assert(_backgroundView);
    
    self.selectionType = @"MPSection";
}

- (NSString *)selectionType
{
    return _selectionType;
}

- (void)setSelectionType:(NSString *)selectionType
{
    _selectionType = selectionType;
    [self setUpTabBarForSelectionType:selectionType];
    [self setUpPaletteSectionsForSelectionType:selectionType];
}

#pragma mark - Tab setup

- (void)setUpTabBarForSelectionType:(NSString *)selectionType
{
    NSArray *tabConfigurations = self.palettesBySelectionType[selectionType];
    
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:tabConfigurations.count];
    for (NSUInteger i = 0; i < tabConfigurations.count; i++)
    {
        [_tabView addTabViewItem:[[NSTabViewItem alloc] initWithIdentifier:[NSString stringWithFormat:@"tabView%lu", i+1]]];
        
        NSDictionary *tabConfiguration = tabConfigurations[i];
        NSString *iconName = tabConfiguration[@"icon"];
        NSString *tooltip = tabConfiguration[@"toolTip"];
        
        NSImage *itemIcon = [NSImage imageNamed:iconName]; assert(itemIcon);
        [itemIcon setTemplate:YES];
        DMTabBarItem *item = [DMTabBarItem tabBarItemWithIcon:itemIcon tag:0];
        item.toolTip = tooltip;
        item.keyEquivalent = [NSString stringWithFormat:@"%lu", i + 1];
        item.keyEquivalentModifierMask = NSCommandKeyMask;
        
        [items addObject:item];
    }
    
    // Load them
    assert(_tabBar);
    _tabBar.tabBarItems = items;
    
    /*
     _tabBar.gradientColorEnd = [NSColor manuscriptsPaletteSectionHeaderGradientEndColor];
     _tabBar.gradientColorStart = [NSColor manuscriptsPaletteSectionHeaderGradientStartColor];
     _tabBar.borderColor = [NSColor manuscriptsDividerColor];
     */
    _tabBar.gradientColorEnd = nil;
    _tabBar.gradientColorStart = nil;
    _tabBar.borderColor = nil;
    
    [_tabBar handleTabBarItemSelection:^(DMTabBarItemSelectionType selectionType,
                                         DMTabBarItem *targetTabBarItem,
                                         NSUInteger targetTabBarItemIndex)
     {
         if (selectionType == DMTabBarItemSelectionType_WillSelect)
         {
             assert(_tabView);
             [_tabView selectTabViewItem:[_tabView.tabViewItems objectAtIndex:targetTabBarItemIndex]];
         } else if (selectionType == DMTabBarItemSelectionType_DidSelect)
         {
             //NSLog(@"Did select %lu/%@",targetTabBarItemIndex,targetTabBarItem);
             //[[[[[[[_tabView selectedTabViewItem] view] subviews] firstObject] subviews] firstObject] reloadData];
         }
     }];
}

#pragma mark - Palette container setup

- (JKOutlineView *)newPaletteContainerForTabViewIndex:(NSUInteger)viewIndex identifier:(NSString *)identifier
{
    NSSize superViewSize = self.view.frame.size;
    
    NSRect frame = NSMakeRect(0, 0, superViewSize.width, superViewSize.height);
    JKOutlineView *paletteContainer = [[JKOutlineView alloc] initWithFrame:frame];
    [paletteContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
    [paletteContainer setIndentationMarkerFollowsCell:NO];
    [paletteContainer setIndentationPerLevel:0];
    [paletteContainer setBackgroundColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.0]];
    [paletteContainer setGridColor:[NSColor clearColor]];
    [paletteContainer setGridStyleMask:NSTableViewGridNone];
    [paletteContainer setFocusRingType:NSFocusRingTypeNone];
    [paletteContainer setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    [paletteContainer setAutosaveTableColumns:NO];
    
    paletteContainer.identifier = identifier;
    
    NSTableColumn *c = [[NSTableColumn alloc] initWithIdentifier:@"MPInspectorColumn"];
    [c setEditable: NO];
    [paletteContainer addTableColumn: c];
    
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];
    scrollView.documentView = paletteContainer;
    scrollView.drawsBackground = NO;
    
    [paletteContainer setHeaderView:nil];
    
    [paletteContainer registerNib:[[NSNib alloc] initWithNibNamed:@"MPInspectorPaletteRowView" bundle:nil]
                    forIdentifier:@"MPInspectorPaletteRowView"];
    [paletteContainer registerNib:[[NSNib alloc] initWithNibNamed:@"MPInspectorPaletteHeaderView" bundle:nil]
                    forIdentifier:@"MPInspectorPaletteHeaderView"];
    [paletteContainer registerNib:[[NSNib alloc] initWithNibNamed:@"MPInspectorPaletteHeaderRowView" bundle:nil]
                    forIdentifier:@"MPInspectorPaletteHeaderRowView"];
    
    [[[_tabView tabViewItemAtIndex:viewIndex] view] addSubviewConstrainedToSuperViewEdges:scrollView
                                                                                topOffset:0 rightOffset:0 bottomOffset:0 leftOffset:0];
    
    assert(paletteContainer);
    return paletteContainer;
}

- (NSString *)controllerKeyForPaletteNibName:(NSString *)nibName
{
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

- (void)setPaletteContainerWithKey:(NSString *)key
{
    NSString *title = [key stringByReplacingOccurrencesOfRegex:@"PaletteContainer$" withString:@""];
    NSArray *tabs = self.palettesBySelectionType[self.selectionType]; assert(tabs);
    __block NSDictionary *configurationForKey = nil;
    __block NSUInteger tabIndex = NSNotFound;
    [tabs enumerateObjectsUsingBlock:^(NSDictionary *tabConfiguration, NSUInteger idx, BOOL *stop) {
        if ([tabConfiguration[@"title"] isEqualToString:title])
        {
            tabIndex = idx;
            configurationForKey = tabConfiguration;
            *stop = YES;
        }
    }];
    assert(tabIndex != NSNotFound && configurationForKey);
    
    JKOutlineView *outlineView = [self newPaletteContainerForTabViewIndex:tabIndex identifier:key];
    [self setValue:outlineView forKey:key];
}

- (JKConfigurationGroup *)configurationGroupForPaletteContainerKey:(NSString *)paletteContainerKey
                                                    paletteNibName:(NSString *)paletteNibName
                                                             modes:(NSDictionary *)dictionary
{
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
    
    JKOutlineView *outlineView = [self valueForKey:paletteContainerKey];
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
        
        [self setPaletteContainerWithKey:paletteContainerKey];
        
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
        JKOutlineView *paletteContainer = [self valueForKey:key];
        paletteContainer.delegate = self;
        paletteContainer.dataSource = self;
        [paletteContainer reloadData];
        [paletteContainer expandItem:nil expandChildren:YES];
    }
}

#pragma mark - Outline view configuration

- (BOOL) outlineView:(NSOutlineView *)outlineView
         isGroupItem:(id)item
{
    return [item isKindOfClass:[JKConfigurationGroup class]];
}


- (NSView *)outlineView:(NSOutlineView *)outlineView
     viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([self outlineView:outlineView isGroupItem:item])
    {
		JKConfigurationHeaderView *headerView
        = [outlineView makeViewWithIdentifier:@"MPInspectorPaletteHeaderView" owner:self];
        
        assert([headerView isKindOfClass:[JKConfigurationHeaderView class]]);
        headerView.textField.stringValue = [item title];
        
        // inverted
        headerView.headerGradientStartColor = [NSColor manuscriptsPaletteSectionHeaderGradientStartColor];
        headerView.headerGradientEndColor = [NSColor manuscriptsPaletteSectionHeaderGradientEndColor];
        
        return headerView;
	}
    
    assert([item isKindOfClass:[JKConfiguration class]]);
	
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
    
    assert ([view isKindOfClass:[NSTableCellView class]] && [view class] != [NSTableCellView class]);
    
    return view;
}

- (void)configurePaletteViewController:(MPPaletteViewController *)vc
{
    // Overload in subclass.
}

- (CGFloat) outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	if ([self outlineView:outlineView isGroupItem:item])
    {
		return 15.f;
	}
	
	JKConfiguration *config = item;
	if (config.nibName)
    {
        CGFloat h = [config.modes[config.mode][@"height"] floatValue];
        
        NSLog(@"%@ %@:%@ = %f", config.nibName, config.mode, config.modes[config.mode], h);
        
        assert(h > 0);
        return h;
	}
	
	return 20.0f;
}

- (CGFloat)heightForPaletteViewController:(MPPaletteViewController *)paletteViewController
{
    NSNumber *h = paletteViewController.configuration.modes[paletteViewController.configuration.mode][@"height"];
    assert(h);
    return [h floatValue];
}

- (void)noteHeightOfPaletteViewControllerChanged:(MPPaletteViewController *)paletteViewController
{
    assert(paletteViewController.inspectorOutlineView);
    NSInteger rowIndex = [paletteViewController.inspectorOutlineView rowForView:paletteViewController.view.superview];
    
    if (rowIndex < 0) return;
    
    assert(rowIndex >= 0);
    [paletteViewController.inspectorOutlineView noteHeightOfRowsWithIndexesChanged:
     [[NSIndexSet alloc] initWithIndex:rowIndex]];
}

- (NSTableRowView *) outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
	if (![self outlineView:outlineView isGroupItem:item])
    {
        // FIXME: is non-group item suppsoed to have a JKConfiguration*Header*RowView
        JKConfigurationHeaderRowView *rowView = [outlineView makeViewWithIdentifier:@"MPInspectorPaletteRowView" owner:nil];
        if (!rowView) {
            rowView = [[JKConfigurationHeaderRowView alloc] initWithFrame:CGRectZero];
            rowView.identifier = @"MPInspectorPaletteRowView";
        }
	}
	
	JKConfigurationHeaderRowView *rowView = [outlineView makeViewWithIdentifier:@"MPInspectorPaletteHeaderRowView" owner:nil];
	if (!rowView) {
		rowView = [[JKConfigurationHeaderRowView alloc] initWithFrame:CGRectZero];
		rowView.identifier = @"MPInspectorPaletteHeaderRowView";
	}
	
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
    return [self outlineView:outlineView isGroupItem:item];
}

@end