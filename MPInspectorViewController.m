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

// for easy lookup we also store the palette controllers under their own identifier
@property (strong) NSMutableDictionary *paletteControllersByIdentifier;

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
    self.paletteControllersByIdentifier = [NSMutableDictionary dictionaryWithCapacity:[self.tabConfigurations count] * 10];
    
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
        // FUTURE: in order to support the same palette in multiple tabs we could
        // concatenate the tab identifier and palette identifier, not done for simplicity right now
        // NSString *uniqueIdentifier = [NSString stringWithFormat:@"%@.%@", tabViewItem.identifier, paletteIdentifier];
        
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
    paletteContainer.indentationMarkerFollowsCell = NO;
    paletteContainer.indentationPerLevel = 0;
    paletteContainer.backgroundColor = [NSColor viewForegroundColor];
    paletteContainer.gridStyleMask = NSTableViewGridNone;
    paletteContainer.focusRingType = NSFocusRingTypeNone;
    paletteContainer.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    paletteContainer.autosaveTableColumns = NO;
    paletteContainer.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    paletteContainer.translatesAutoresizingMaskIntoConstraints = NO;

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
    // importantly we assume there will only be one instance of a palette per inspector
    MPPaletteViewController *paletteController = self.paletteControllersByIdentifier[identifier];
    if (!paletteController)
    {
        // MTInspectorOverviewSummary -> MTInspectorOverviewSummaryController
        NSString *className = identifier;
        if (![className hasSuffix:@"Controller"])
            className = [identifier stringByAppendingString:@"Controller"];
        
        Class controllerClass = NSClassFromString(className);
        assert ([controllerClass isSubclassOfClass:[MPPaletteViewController class]]);
        
        paletteController = [(MPPaletteViewController *)[controllerClass alloc] initWithDelegate:self identifier:identifier];
                             
        self.paletteControllersByIdentifier[identifier] = paletteController;
    }
    
    return paletteController;
}


#pragma mark -
#pragma mark OutlineView Delegate

// we always assume a 1:1 relationship between a group row and palette, where each palette
// has a header row. When the row content for the group row is requested we return the
// palette's identifier. For the child of the group we simple return the palette controller
// for that identifier.

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{    
    if (!item)
    {
        return [self.paletteControllers[outlineView.identifier] count];
    }
    
    if ([self outlineView:outlineView isGroupItem:item])
    {
        // we assume a 1:1 relationship between groups and palettes
        return 1;
    }
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item)
    {
        MPPaletteViewController *paletteController = self.paletteControllers[outlineView.identifier][index];
        return paletteController.identifier;
    }
    
    if ([self outlineView:outlineView isGroupItem:item])
    {
        NSString *paletteIdentifier = (NSString *)item;
        return [self paletteViewControllerForIdentifier:paletteIdentifier];
    }
    
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    return [item isKindOfClass:[NSString class]];
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
	if ([self outlineView:outlineView isGroupItem:item])
    {
        JKConfigurationHeaderRowView *rowView = [outlineView makeViewWithIdentifier:@"MPGroupRowView" owner:nil];
        if (!rowView)
        {
            rowView = [[JKConfigurationHeaderRowView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 300.0, 33.0)];
            rowView.identifier = @"MPGroupRowView";
        }
        return rowView;
	}
	
	// otherwise get a regular rowview
    return nil;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([self outlineView:outlineView isGroupItem:item])
    {
		JKConfigurationHeaderView *headerView = [outlineView makeViewWithIdentifier:@"MPGroupHeaderView" owner:self];
        if (!headerView)
        {
            headerView = [[JKConfigurationHeaderView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 300.0, 33.0)];
            headerView.identifier = @"MPGroupHeaderView";
        }

        assert([headerView isKindOfClass:[JKConfigurationHeaderView class]]);
        
        NSString *paletteIdentifier = (NSString *)item;
        MPPaletteViewController *paletteController = [self paletteViewControllerForIdentifier:paletteIdentifier];
        headerView.labelTextField.stringValue = [paletteController title];

        // FUTURE:give a chance to the palette controller to change the content of the headerview
        // if ([paletteController respondsToSelector:(inspectorViewController:willDisplayHeaderView:)])
        //  [paletteController inspectorViewController:self willDisplayHeaderView: headerView];
        
        return headerView;
	}
    
    if ([item isKindOfClass:[MPPaletteViewController class]])
    {
        MPPaletteViewController *paletteController = (MPPaletteViewController *)item;

        // TODO: set displayed items on row
        
        return paletteController.view;
    }
    
    return nil;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	if ([self outlineView:outlineView isGroupItem:item])
    {
		return 33.f;
	}
    
    if ([item isKindOfClass:[MPPaletteViewController class]])
    {
        MPPaletteViewController *paletteController = (MPPaletteViewController *)item;
        return paletteController.height;
    }
    
	return 0.0f;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return [self outlineView:outlineView isGroupItem:item];
}


#pragma mark -
#pragma mark MPPaletteViewControllerDelegate

- (void)noteHeightOfPaletteViewControllerChanged:(MPPaletteViewController *)paletteViewController
{
    // we simply iterate over each container for now
    for (NSOutlineView *container in [self.paletteContainers allValues])
    {
        NSInteger rowIndex = [container rowForView:paletteViewController.view];
        if (rowIndex < 0) continue;
        
        [container noteHeightOfRowsWithIndexesChanged:[[NSIndexSet alloc] initWithIndex:rowIndex]];
    }
}

@end