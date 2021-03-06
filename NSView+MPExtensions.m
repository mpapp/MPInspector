//
//  NSView+MPExtensions.m
//  Manuscripts
//
//  Created by Matias Piipari on 21/12/2012.
//  Copyright (c) 2012 Manuscripts.app Limited. All rights reserved.
//


#import "NSView+MPExtensions.h"


inline id MPAnimatorOrView(NSView *view, BOOL animate)
{
    return (animate ? view.animator : view);
}

inline id MPAnimatorOrConstraint(NSLayoutConstraint *constraint, BOOL animate)
{
    return (animate ? constraint.animator : constraint);
}

inline NSInteger MPBooleanToState(BOOL b)
{
    return b ? NSOnState : NSOffState;
}

inline BOOL MPStateToBoolean(NSInteger state)
{
    return state != NSOffState;
}


static inline BOOL MPLayoutAttributeIsHorizontal(NSLayoutAttribute attribute) {
    return ((attribute == NSLayoutAttributeLeft) || (attribute == NSLayoutAttributeRight) || (attribute == NSLayoutAttributeLeading) || (attribute == NSLayoutAttributeTrailing) || (attribute == NSLayoutAttributeCenterX));
}

static inline BOOL MPLayoutAttributeIsVertical(NSLayoutAttribute attribute) {
    return ((attribute == NSLayoutAttributeTop) || (attribute == NSLayoutAttributeBottom) || (attribute == NSLayoutAttributeCenterY) || (attribute == NSLayoutAttributeBaseline));
}


typedef NS_ENUM(NSUInteger, MPViewDimension)
{
    MPViewDimensionWidth = 1,
    MPViewDimensionHeight = 2
};


@implementation NSView (MPViewExtensions)

// From
// http://stackoverflow.com/questions/8156799/how-to-make-a-custom-view-resize-with-the-window-with-cocoa-auto-layout

- (void)addEdgeConstraint:(NSLayoutAttribute)edge subview:(NSView *)subview
{
    [self addEdgeConstraint:edge constantOffset:0 subview:subview];
}

- (void)addEdgeConstraint:(NSLayoutAttribute)edge constantOffset:(CGFloat)value subview:(NSView *)subview
{
    [self addConstraint:
     [NSLayoutConstraint constraintWithItem:subview attribute:edge
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self attribute:edge
                                 multiplier:1 constant:value]];
}

- (void)addSubviewConstrainedToSuperViewEdges:(NSView *)aView
{
    return [self addSubviewConstrainedToSuperViewEdges:aView
                                             topOffset:0 rightOffset:0 bottomOffset:0 leftOffset:0];
}

- (void)addSubviewConstrainedToSuperViewEdges:(NSView *)aView
                                    topOffset:(CGFloat)topOffset
                                  rightOffset:(CGFloat)rightOffset
                                 bottomOffset:(CGFloat)bottomOffset
                                   leftOffset:(CGFloat)leftOffset
{
    NSAssert(aView, @"Subview is nil when attempting to add subview constrained to superview %@", self);
    
    [aView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self addSubview:aView];
    
    [self addEdgeConstraint:NSLayoutAttributeLeft constantOffset:leftOffset subview:aView];
    [self addEdgeConstraint:NSLayoutAttributeRight constantOffset:rightOffset subview:aView];
    [self addEdgeConstraint:NSLayoutAttributeTop constantOffset:topOffset subview:aView];
    [self addEdgeConstraint:NSLayoutAttributeBottom constantOffset:bottomOffset subview:aView];
}

- (BOOL) hasSubview:(NSView *)subview
{
    return [self.subviews containsObject:subview];
}


#pragma mark - Layout constraint queries

- (NSLayoutConstraint *) constraintWithSelfAsFirstItemAndFirstAttribute:(NSLayoutAttribute)firstAttribute
{
    NSLayoutConstraint *constraint = nil;
    
    for (NSLayoutConstraint *c in [self constraints])
    {
        if (([c firstItem] == self) && ([c firstAttribute] == firstAttribute))
        {
            constraint = c;
            break;
        }
    }
    
    return constraint;
}

- (NSLayoutConstraint *) heightConstraint
{
    return [self constraintWithSelfAsFirstItemAndFirstAttribute:NSLayoutAttributeHeight];
}

- (NSLayoutConstraint *) widthConstraint
{
    return [self constraintWithSelfAsFirstItemAndFirstAttribute:NSLayoutAttributeWidth];
}

- (NSLayoutConstraint *) horizontalConstraintWithView:(NSView *)anotherView
{
    id superview = [self ancestorSharedWithView:anotherView];
    if (superview == nil) return nil;
    
    NSLayoutConstraint *constraint = nil;
    
    while (superview != nil) {
        for (NSLayoutConstraint *lc in [superview constraints])
        {
            id firstItem = [lc firstItem];
            id secondItem = [lc secondItem];
            
            if (((firstItem == self) && (secondItem == anotherView)) || ((firstItem == anotherView) && (secondItem == self)))
            {
                NSLayoutAttribute firstAttribute = [lc firstAttribute];
                NSLayoutAttribute secondAttribute = [lc secondAttribute];
                
                if (MPLayoutAttributeIsHorizontal(firstAttribute) && MPLayoutAttributeIsHorizontal(secondAttribute))
                {
                    constraint = lc;
                    break;
                }
            }
        }
        
        if (constraint == nil) {
            superview = [superview superview]; // The while loop helps handling cases such as NSBox containing the constraints, while the subviews in fact have a content view as their superview
        } else {
            break;
        }
    }
    
    return constraint;
}

- (NSLayoutConstraint *) verticalConstraintWithView:(NSView *)anotherView
{
    id superview = [self ancestorSharedWithView:anotherView];
    if (superview == nil) return nil;
    
    NSLayoutConstraint *constraint = nil;
    
    while (superview != nil)
    {
        for (NSLayoutConstraint *lc in [superview constraints]) {
            id firstItem = [lc firstItem];
            id secondItem = [lc secondItem];
            
            if (((firstItem == self) && (secondItem == anotherView)) || ((firstItem == anotherView) && (secondItem == self))) {
                NSLayoutAttribute firstAttribute = [lc firstAttribute];
                NSLayoutAttribute secondAttribute = [lc secondAttribute];
                
                if (MPLayoutAttributeIsVertical(firstAttribute) && MPLayoutAttributeIsVertical(secondAttribute)) {
                    constraint = lc;
                    break;
                }
            }
        }
        
        if (constraint == nil) {
            superview = [superview superview]; // The while loop helps handling cases such as NSBox containing the constraints, while the subviews in fact have a content view as their superview
        } else {
            break;
        }
    }
    
    return constraint;
}

- (void) hideWithZeroWidth
{
    self.widthConstraint.constant = 0.0;
    self.hidden = YES;
}

- (void)hideWithZeroHeight
{
    self.heightConstraint.constant = 0.0;
    self.hidden = YES;
}

- (void)hideWithZeroWidthAndAnimate:(BOOL)animate
{
    [self hideWithZeroDimension:MPViewDimensionWidth andAnimate:animate];
}

- (void)hideWithZeroHeightAndAnimate:(BOOL)animate
{
    [self hideWithZeroDimension:MPViewDimensionHeight andAnimate:animate];
}

- (void) hideWithZeroDimension:(MPViewDimension)dimension andAnimate:(BOOL)animate
{
    if (animate)
    {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [((dimension == MPViewDimensionWidth) ? self.widthConstraint : self.heightConstraint).animator setConstant:0.0];
        } completionHandler:^{
            self.hidden = YES;
        }];
    }
    else
    {
        ((dimension == MPViewDimensionWidth) ? self.widthConstraint : self.heightConstraint).constant = 0.0;
        self.hidden = YES;
    }
}

+ (void)hideViews:(NSArray *)views withZeroWidthAndAnimate:(BOOL)animate
{
    [self hideViews:views withZeroDimension:MPViewDimensionWidth andAnimate:animate];
}

+ (void)hideViews:(NSArray *)views withZeroHeightAndAnimate:(BOOL)animate
{
    [self hideViews:views withZeroDimension:MPViewDimensionHeight andAnimate:animate];
}

+ (void)hideViews:(NSArray *)views withZeroDimension:(MPViewDimension)dimension andAnimate:(BOOL)animate
{
    if (animate)
    {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            for (NSView *view in views)
            {
                [((dimension == MPViewDimensionWidth) ? view.widthConstraint : view.heightConstraint).animator setConstant:0.0];
            }
        } completionHandler:^{
            for (NSView *view in views)
            {
                view.hidden = YES;
            }
        }];
    }
    else
    {
        for (NSView *view in views)
        {
            [view hideWithZeroWidth];
        }
    }
}

- (void) showWithWidth:(CGFloat)width
{
    self.hidden = NO;
    self.widthConstraint.constant = width;
}

- (void) showWithWidth:(CGFloat)width andAnimate:(BOOL)animate
{
    self.hidden = NO;
    [MPAnimatorOrConstraint(self.widthConstraint, animate) setConstant:width];
}

- (void) showWithHeight:(CGFloat)height
{
    self.hidden = NO;
    self.heightConstraint.constant = height;
}

- (void)showWithHeight:(CGFloat)height andAnimate:(BOOL)animate
{
    self.hidden = NO;
    [MPAnimatorOrConstraint(self.heightConstraint, animate) setConstant:height];
}

@end
