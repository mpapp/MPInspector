//
//  MPPaletteViewController.h
//
//  Created by Alexander Griekspoor on 23/06/2013.
//  Copyright (c) 2013 Papersapp.com. All rights reserved.
//
//  Based on JKConfigurationHeaderRowView.h from cocoa-configurations by Joris Kluivers
//  Copyright (c) 2012 Tarento Software. All rights reserved.

#import "MPPaletteHeaderRowView.h"
#import "MTShadowTextField.h"
#import "NSColor_Extensions.h"

@interface MPPaletteHeaderRowView ()
@property (weak) NSTextField *showHideTextField;
@end

@implementation MPPaletteHeaderRowView
{
	BOOL _pressed;
    BOOL _highlight;
    NSTrackingArea *_area;
}

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        // add the show/hide label
        NSTextField *textField = [[MTShadowTextField alloc] initWithFrame:self.bounds];
        textField.frame = NSMakeRect(NSWidth(self.bounds) - 65.0, 8.0, 50.0, 18.0);
        textField.autoresizingMask = (NSViewMinXMargin | NSViewMinYMargin);
        textField.alignment = NSRightTextAlignment;
        textField.textColor = [NSColor colorWithCalibratedWhite:0.55 alpha:1.0];
        textField.font = [NSFont systemFontOfSize:11.0];
        textField.drawsBackground = NO;
        textField.editable = NO;
        textField.selectable = NO;
        textField.bordered = NO;
        textField.stringValue = MTLocalizedString(@"Hide");
        textField.hidden = YES;
        [self addSubview:textField];
        
        self.showHideTextField = textField;
    }
    return self;
}

- (void)dealloc
{
    if (_area)
    {
        [self removeTrackingArea:_area];
    }
}

- (NSButton *)disclosureButton
{
	NSButton *disclosureButton = nil;
	for (NSView *view in [self subviews])
    {
		if ([view isKindOfClass:[NSButton class]])
        {
			disclosureButton = (NSButton *) view;
			break;
		}
	}
	return disclosureButton;
}

- (void)updateButtonState
{
	[[self disclosureButton] highlight:_pressed];
}


#pragma mark -
#pragma mark Tracking

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    if (_area) [self removeTrackingArea:_area];
	
	NSTrackingAreaOptions options =  NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways;
	_area = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                         options:options
                                           owner:self
                                        userInfo:nil];
	[self addTrackingArea:_area];
    
}

- (void)updateShowHideState
{
    self.showHideTextField.stringValue = MTLocalizedString((self.disclosureButton.state ? @"Hide" : @"Show"));
    self.showHideTextField.hidden = !_highlight;
}


#pragma mark -
#pragma mark Mouse Events

- (void)mouseEntered:(NSEvent *)event
{
	_highlight = YES;
	[self updateShowHideState];
}

- (void)mouseExited:(NSEvent *)event
{
	_highlight = NO;
	[self updateShowHideState];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	_pressed = YES;
	[self updateButtonState];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	_pressed = NSMouseInRect(point, [self bounds], [self isFlipped]);
	[self updateButtonState];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (_pressed)
    {
		[[self disclosureButton] performClick:theEvent];
        [self updateShowHideState];
	}
	_pressed = NO;
}


#pragma mark -
#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    // hide our disclosure button
    self.disclosureButton.hidden = YES;

    // draw our favorite background color
    [[NSColor viewForegroundColor] set];
    NSRectFill(dirtyRect);
    
    // draw a 1px border if we're closed, also set a height check to prevent weird lines
    // being drawn during the animation
    if (!self.disclosureButton.state && NSHeight(dirtyRect) > 30.0)
    {
        [NSGraphicsContext saveGraphicsState];
        {
            [[NSGraphicsContext currentContext] setShouldAntialias:NO];
            
            NSBezierPath *bezier = [NSBezierPath bezierPath];
            [bezier moveToPoint:NSMakePoint(NSMinX(dirtyRect), (self.isFlipped ? NSMaxY(dirtyRect) : NSMinY(dirtyRect)))    ];
            [bezier lineToPoint:NSMakePoint(NSWidth(dirtyRect), (self.isFlipped ? NSMaxY(dirtyRect) : NSMinY(dirtyRect)))];
        
            [[NSColor tableViewBorderColor] set];
            [bezier setLineWidth:1.0];
            [bezier stroke];
        }
        [NSGraphicsContext restoreGraphicsState];
    }
}

@end
