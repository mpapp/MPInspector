//
//  MPPaletteViewController.h
//
//  Created by Alexander Griekspoor on 23/06/2013.
//  Copyright (c) 2013 Papersapp.com. All rights reserved.
//
//  Based on JKConfigurationHeaderRowView.h from cocoa-configurations by Joris Kluivers
//  Copyright (c) 2012 Tarento Software. All rights reserved.

#import "MPPaletteHeaderView.h"
#import "MTShadowTextField.h"
#import "NSColor_Extensions.h"

@implementation MPPaletteHeaderView
{
	BOOL _pressed;
}

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        // add the header label
        NSTextField *textField = [[MTShadowTextField alloc] initWithFrame:self.bounds];
        textField.frame = NSMakeRect(11.0, 8.0, 200.0, 17.0);
        textField.textColor = [NSColor colorWithCalibratedWhite:0.55 alpha:1.0];
        textField.font = [NSFont systemFontOfSize:12.0];
        textField.drawsBackground = NO;
        textField.editable = NO;
        textField.selectable = NO;
        textField.bordered = NO;
        [self addSubview:textField];
        
        self.textField = textField;
    }
    return self;
}

- (void)updateState
{
	self.textField.textColor = [NSColor colorWithCalibratedWhite:(_pressed ? 0.35 : 0.55) alpha:1.0];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	_pressed = YES;
	[self updateState];
    
    [super mouseDown:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	_pressed = NSMouseInRect(point, [self bounds], [self isFlipped]);
	[self updateState];
    
    [super mouseDragged:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    _pressed = NO;
    [self updateState];
    
    [super mouseUp:theEvent];
}

@end
