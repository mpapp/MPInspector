//
//  MPPaletteViewController.h
//
//  Created by Matias Piipari on 21/12/2012.
//  Copyright (c) 2012 Manuscripts.app Limited. All rights reserved.

#import "MPInspectorViewController.h"
#import "MPPaletteViewController.h"

#import "DMTabBar.h"
#import "DMTabBarItem.h"

#import "JKConfigurationHeaderRowView.h"
#import "JKConfigurationHeaderView.h"
#import "JKConfiguration.h"

//#import "NSView+MPExtensions.h"
//#import "RegexKitLite.h"

#import "NSColor_Extensions.h"

#import "MTInspectorOverviewSummaryController.h"

@interface MPInspectorViewController ()
{

}

@property (strong) NSDictionary *paletteConfigurations;
@property (strong) NSDictionary *tabConfigurations;

// outlineviews and arrays of palette controllers stored under the tab identifier
@property (strong) NSMutableDictionary *paletteContainers;
@property (strong) NSMutableDictionary *paletteControllers;

- (void)setUpTabsForEntityType:(NSString *)entityType;
- (void)setUpTabViewItem:(NSTabViewItem *)tabViewItem tabConfiguration:(NSDictionary *)tabConfiguration;

- (NSOutlineView *)paletteContainerForTabViewItem:(NSTabViewItem *)tabViewItem;




- (void)setUpTabViewForEntityType:(NSString *)entityType;
- (void)setUpPalletesForTabWithIdentifier:(NSString *)tabIdentifier;





@property (strong) NSMutableDictionary *configurationsByPaletteNibName;
@property (strong) NSDictionary *palettesForTabTitle;

- (void)setPaletteContainerWithKey:(NSString *)key;
- (CGFloat)heightForPaletteViewController:(MPPaletteViewController *)paletteViewController;
@end



@implementation MPInspectorViewController

@synthesize entityType = _entityType;

- (NSString *)configurationFilename
{
    return @"Inspector_Palettes";
}

- (NSDictionary *)configurationDictionary
{
    NSURL *paletteConfigURL = [[NSBundle mainBundle] URLForResource:self.configurationFilename
                                                      withExtension:@"json"
                                                       subdirectory:@"Configuration"];
    
    NSData *data = [[NSData alloc] initWithContentsOfURL:paletteConfigURL];
    NSError *err = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (!dict)
    {
        NSLog(@"Failed to load pallete configuration from JSON file at %@ (%@)", paletteConfigURL, err);
    }
    
    assert(dict);
    return dict;
}

- (NSString *)defaultEntityType
{
    return @"MTPublication";
}

- (void)loadView
{
    [super loadView];
    
    NSDictionary *dict = [self configurationDictionary];
    self.paletteConfigurations = dict[@"palettes"];
    self.tabConfigurations = dict[@"tabs"];
    
    self.paletteContainers = [NSMutableDictionary dictionaryWithCapacity:[self.tabConfigurations count]];
    self.paletteControllers = [NSMutableDictionary dictionaryWithCapacity:[self.tabConfigurations count]];
    
    self.entityType = self.defaultEntityType;
}


#pragma mark -
#pragma mark EntityType

- (NSString *)entityType
{
    return _entityType;
}

- (void)setEntityType:(NSString *)entityType
{
    _entityType = entityType;
    
    [self setUpTabsForEntityType:entityType];
}



#pragma mark -
#pragma mark Refresh

- (void)refresh
{
    [self refreshForced:NO];
}

- (void)refreshForced:(BOOL)forced
{
    if (forced)
    {
        [self setUpTabViewForEntityType:self.entityType];
    }
    
    NSString *identifier = [[self.tabView selectedTabViewItem] identifier];
    [self.paletteContainers[identifier] reloadData];
}



#pragma mark -
#pragma mark Tab setup

- (void)setUpTabsForEntityType:(NSString *)entityType
{
    // make sure we have the outlets set up
    assert(self.tabBar && self.tabView);

    while ([self.tabView numberOfTabViewItems] > 0)
        [self.tabView removeTabViewItem:[self.tabView tabViewItemAtIndex:0]];
    
    NSArray *tabs = self.tabConfigurations[entityType];
    
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:tabs.count];
    for (NSUInteger i = 0; i < tabs.count; i++)
    {
        // add the tabs to the tabview
        NSDictionary *tabConfiguration = tabs[i];
        NSTabViewItem *tabViewItem = [[NSTabViewItem alloc] initWithIdentifier:tabConfiguration[@"identifier"]];
        [self.tabView addTabViewItem:tabViewItem];
        [self setUpTabViewItem:tabViewItem tabConfiguration:tabConfiguration];
        
        // set up the DMTabBarItems
        NSString *iconName = tabConfiguration[@"icon"];
        NSString *alternateIconName = tabConfiguration[@"selectedIcon"];
        NSString *title = tabConfiguration[@"title"];
        NSString *tooltip = tabConfiguration[@"toolTip"];
                
        NSImage *itemIcon = [NSImage imageNamed:iconName];        
        DMTabBarItem *item = [DMTabBarItem tabBarItemWithIcon:itemIcon tag:0];
        item.toolTip = (tooltip ? tooltip : title);
        item.keyEquivalent = [NSString stringWithFormat:@"%lu", i + 1];
        item.keyEquivalentModifierMask = NSCommandKeyMask;
        
        if (alternateIconName)
            item.alternateIcon = [NSImage imageNamed:alternateIconName];

        [items addObject:item];
    }
    // load the items on the tabbar
    self.tabBar.tabBarItems = items;
    
    // handle tabBar selection
    [self.tabBar handleTabBarItemSelection:^(DMTabBarItemSelectionType itemSelectionType,
                                             DMTabBarItem *targetTabBarItem,
                                             NSUInteger targetTabBarItemIndex)
     {
         if (itemSelectionType == DMTabBarItemSelectionType_WillSelect)
         {
             // FUTURE: send current tab palettes a will hide and new tab palettes a will show message
             NSTabViewItem *tabViewItem = self.tabView.tabViewItems[targetTabBarItemIndex];
             [self.tabView selectTabViewItem:tabViewItem];
         }
     }];
}

- (void)setUpTabViewItem:(NSTabViewItem *)tabViewItem tabConfiguration:(NSDictionary *)tabConfiguration
{    
    // set up the container outlineView
    NSOutlineView *paletteContainer = [self paletteContainerForTabViewItem:tabViewItem];
    self.paletteContainers[tabViewItem.identifier] = paletteContainer;
    
    // populate the palettes
    NSArray *paletteIdentifiers = tabConfiguration[@"palettes"];
    NSMutableArray *palettes = [NSMutableArray arrayWithCapacity:[paletteIdentifiers count]];
    
    for (NSString *paletteIdentifier in paletteIdentifiers)
    {
        MPPaletteViewController *viewController = [self paletteViewControllerForIdentifier:paletteIdentifier];
        
        
        [palettes addObject:viewController];
    }
    
    self.paletteControllers[tabViewItem.identifier] = palettes;
    
    // hook up and reload the outlineview
    paletteContainer.delegate = self;
    paletteContainer.dataSource = self;
    
    [paletteContainer reloadData];
    [paletteContainer expandItem:nil expandChildren:YES];
}

- (NSOutlineView *)paletteContainerForTabViewItem:(NSTabViewItem *)tabViewItem
{
    // set up a new outline view as the palette container
    NSOutlineView *paletteContainer = [[NSOutlineView alloc] initWithFrame:self.view.bounds];
    paletteContainer.translatesAutoresizingMaskIntoConstraints = NO;
    paletteContainer.indentationMarkerFollowsCell = NO;
    paletteContainer.indentationPerLevel = 0;
    paletteContainer.backgroundColor = [NSColor viewForegroundColor];
    paletteContainer.gridStyleMask = NSTableViewGridNone;
    paletteContainer.focusRingType = NSFocusRingTypeNone;
    paletteContainer.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    paletteContainer.autosaveTableColumns = NO;
    paletteContainer.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    
    // set the identifier to be that of the tab (same as tabviewitem)
    paletteContainer.identifier = tabViewItem.identifier;
    
    // add a tablecolumn
    NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:@"MPInspectorColumn"];
    [tableColumn setEditable: NO];
    [paletteContainer addTableColumn:tableColumn];
    
    // embed the outlineview in a scrollview
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];
    scrollView.documentView = paletteContainer;
    scrollView.drawsBackground = YES;
    scrollView.backgroundColor = [NSColor viewBackgroundColor];
    scrollView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);

    [paletteContainer setHeaderView:nil];
    
    // set the scrollview as the view for the tabviewitem
    tabViewItem.view = scrollView;
    
    assert(paletteContainer);
    return paletteContainer;
}

- (MPPaletteViewController *)paletteViewControllerForIdentifier:(NSString *)identifier
{
    // TODO setup the correct palette based on the identifier
    return [[MTInspectorOverviewSummaryController alloc] initWithDelegate:self];
}


// TODO: correctly hook up to the JKOutlineGroup system for getting the hide/unhide functionality
// each palette controller should have a corresponding Configuration Group item with the title 

// TODO: complete the proper outline view delegate and datasource methods
/*

- (void)setUpTabViewForEntityType:(NSString *)entityType
{

    for (NSUInteger i = 0; i < tabs.count; i++)
    {
        NSString *title = tabConfiguration[@"title"]; assert(title);
        NSArray *paletteNames = tabConfiguration[@"palettes"];

        NSString *paletteContainerKey = [title stringByAppendingFormat:@"PaletteContainer"];

        [self setPaletteContainerWithKey:paletteContainerKey];

        NSMutableArray *groups = [NSMutableArray arrayWithCapacity:paletteNames.count];

        for (NSString *paletteName in paletteNames)
        {
            NSDictionary *palette = self.palettesByEntityType[paletteName];

            NSString *name = palette[@"title"]; assert(paletteName);

            assert(palette[@"modes"]);

            NSString *paletteNibName = [name stringByAppendingFormat:@"PaletteController"];

            JKConfigurationGroup *configGroup = [self configurationGroupForPaletteContainerKey:paletteContainerKey
                                                                                paletteNibName:paletteNibName modes:palette[@"modes"]];

            [groups addObject:configGroup];
        }

        palettesForTabs[paletteContainerKey] = groups;
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
    NSArray *tabs = self.palettesBySelectionType[selectionType];
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
            
            NSString *name = palette[@"title"]; assert(paletteName);
            
            assert(palette[@"modes"]);
            
            NSString *paletteNibName = [name stringByAppendingFormat:@"PaletteController"];
            
            JKConfigurationGroup *configGroup = [self configurationGroupForPaletteContainerKey:paletteContainerKey
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
        headerView.headerGradientStartColor = [NSColor colorWithDeviceWhite:0.81 alpha:1.0];
        headerView.headerGradientEndColor = [NSColor colorWithDeviceWhite:0.91 alpha:1.0];

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
        assert(palettes.count > 0);
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
*/


#pragma mark -
#pragma mark OutlineView Delegate

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!outlineView.dataSource) return 0;
    
    if (!item)
    {
        NSString *identifier = [[self.tabView selectedTabViewItem] identifier];
        return [self.paletteControllers[identifier] count];
    }
    
    //if ([self outlineView:outlineView isGroupItem:item]) return 1;
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item)
    {
        NSString *identifier = [[self.tabView selectedTabViewItem] identifier];
        return self.paletteControllers[identifier][index];
    }
    
//    if ([self outlineView:outlineView isGroupItem:item])
//    {
//        assert([[item children] count] == 1 && index == 0);
//        JKConfigurationGroup *group = (JKConfigurationGroup *)item;
//        return group.children[index];
//    }
//    
//    assert([item children] == 0);
    return 0;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([item isKindOfClass:[MPPaletteViewController class]])
    {
        return [item valueForKey:@"view"];
    }
    
    return nil;
//    if ([self outlineView:outlineView isGroupItem:item])
//    {
//		JKConfigurationHeaderView *headerView
//        = [outlineView makeViewWithIdentifier:@"MPInspectorPaletteHeaderView" owner:self];
//        
//        assert([headerView isKindOfClass:[JKConfigurationHeaderView class]]);
//        headerView.textField.stringValue = [item title];
//        
//        // inverted
//        headerView.headerGradientStartColor = [NSColor colorWithDeviceWhite:0.81 alpha:1.0];
//        headerView.headerGradientEndColor = [NSColor colorWithDeviceWhite:0.91 alpha:1.0];
//        
//        return headerView;
//	}
//    
//    assert([item isKindOfClass:[JKConfiguration class]]);
//	
//	JKConfiguration *config = item;
//    assert(config.nibName);
//    
//    assert([outlineView registeredNibsByIdentifier][config.nibName]);
//    
//    MPPaletteViewController *vc = [self valueForKey:[self controllerKeyForPaletteNibName:config.nibName]];
//    assert(vc); // matching Nib & view controller name
//    assert(vc.inspectorController == self);
//    
//    // MUST set before packageController.
//    vc.inspectorOutlineView = outlineView;
//    config.itemController = vc;
//    
//    assert (!vc.configuration || vc.configuration == config);
//    
//    vc.configuration = item;
//    vc.configuration.modes = [item modes];
//    vc.configuration.mode = [vc defaultConfigurationMode];
//    assert(vc.configuration.mode);
//    
//    [self configurePaletteViewController:vc];
//    
//	NSTableCellView *view = (NSTableCellView *)vc.view;
//    
//    assert ([view isKindOfClass:[NSTableCellView class]] && [view class] != [NSTableCellView class]);
//    
//    return view;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
//	if ([self outlineView:outlineView isGroupItem:item])
//    {
//		return 15.f;
//	}
//	
//	JKConfiguration *config = item;
//	if (config.nibName)
//    {
//        CGFloat h = [config.modes[config.mode][@"height"] floatValue];
//        
//        NSLog(@"%@ %@:%@ = %f", config.nibName, config.mode, config.modes[config.mode], h);
//        
//        assert(h > 0);
//        return h;
//	}
	
	return 200.0f;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return NO;//[self outlineView:outlineView isGroupItem:item];
}


@end