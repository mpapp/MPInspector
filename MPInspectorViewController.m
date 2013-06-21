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
#import "JKOutlineView.h"

#import "NSView+MPExtensions.h"
#import "RegexKitLite.h"

@interface MPInspectorViewController ()
{

}

@property (strong) NSDictionary *paletteConfigurations;
@property (strong) NSDictionary *tabConfigurations;

@property (strong) NSDictionary *paletteControllersByEntityType;

- (void)setUpTabBarForEntityType:(NSString *)entityType;






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

    self.entityType = self.defaultEntityType;
}

- (NSString *)entityType
{
    return _entityType;
}

- (void)setEntityType:(NSString *)entityType
{
    _entityType = entityType;
    
    [self setUpTabBarForEntityType:entityType];
    //[self setUpTabViewForEntityType:entityType];
}


#pragma mark -
#pragma mark - Tab setup

- (void)setUpTabBarForEntityType:(NSString *)entityType
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


/*     [self setUpPalettesForEntityType:entityType]; */
/*
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
    
    NSTabViewItem *tabViewItem = [_tabView tabViewItemAtIndex:viewIndex];
    [[tabViewItem view] addSubviewConstrainedToSuperViewEdges:scrollView
                                                    topOffset:0
                                                  rightOffset:0
                                                 bottomOffset:0
                                                   leftOffset:0];
    assert(paletteContainer);
    return paletteContainer;
}

- (NSString *)controllerKeyForPaletteNibName:(NSString *)nibName
{
    // MPFoobarPaletteController => foobarPaletteController
    // assuming a capitalized prefix followed by a capitalized name
    NSRange lcr = [nibName rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]];
    assert(lcr.location != NSNotFound && lcr.location > 0);
    
    NSString *firstLetter = [[nibName substringWithRange:NSMakeRange(lcr.location - 1, 1)] lowercaseString];
    return [NSString stringWithFormat:@"%@%@", firstLetter, [nibName substringFromIndex:lcr.location]];
}

- (void)setPaletteContainerWithKey:(NSString *)key
{
    NSString *title = [key stringByReplacingOccurrencesOfRegex:@"PaletteContainer$" withString:@""];
    NSArray *tabs = self.palettesBySelectionType[self.selectionType];
    assert(tabs);
    
    __block NSDictionary *configurationForKey = nil;
    __block NSUInteger tabIndex = NSNotFound;
    [tabs enumerateObjectsUsingBlock:^(NSDictionary *tabConfiguration, NSUInteger idx, BOOL *stop)
    {
        if ([tabConfiguration[@"title"] isEqualToString:title])
        {
            tabIndex = idx;
            configurationForKey = tabConfiguration;
            *stop = YES;
        }
    }];
    assert(tabIndex != NSNotFound && configurationForKey);
    
    // this requires a read-write property with an IBOutlet named according to the title of the tab
    // added to your MPInspectorViewController subclass
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
@end