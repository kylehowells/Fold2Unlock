//
//  KHFoldView.m
//  Fold2Unlock
//
//  Created by Kyle Howells on 22/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "KHFoldView.h"

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface KHFoldView ()
// This is an array of the views which will be displayed.
// Each 'slice' is a UIImageView.
@property (nonatomic, retain) NSMutableArray *viewSlices;
-(void)updateAll;
-(void)updateSlicesFromImageArray:(NSArray*)array;

-(void)move:(UIPanGestureRecognizer*)gestureRecognizer;
-(void)layoutSlicesForPercentage:(CGFloat)percentage;
@end

@implementation KHFoldView
@synthesize viewSlices, slices = _slices, viewImage = _viewImage;

-(void)dealloc{
    self.viewSlices = nil;
    self.viewImage = nil;

    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.viewSlices = [NSMutableArray array];

        // Track the touches
        UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
        [self addGestureRecognizer:gestureRecognizer];
        [gestureRecognizer setMinimumNumberOfTouches:1];
        [gestureRecognizer setMaximumNumberOfTouches:1];
        [gestureRecognizer release];

        self.userInteractionEnabled = YES;
    }

    return self;
}


#pragma mark - slice the image up.
-(void)setSlices:(int)slices{
    _slices = slices;

    [self updateAll];
}

-(void)setViewImage:(UIImage *)viewImage{
    [_viewImage release], _viewImage = nil;
    _viewImage = [viewImage retain];

    [self updateAll];
}

-(NSArray*)slipImage:(UIImage*)image intoSlices:(int)slicesCount{
    // If we don't need to do anything to the image just save ourselves the trouble.
    if (!image || slicesCount < 2) {
        return (image ? [NSArray arrayWithObject:image] : nil);
    }

    // something to store the images in
    NSMutableArray *newArray = [NSMutableArray array];

    // Just for easy of access
    CGSize imageSize = image.size;
    CGFloat width = imageSize.width;

    // Dimensions per slice
    CGFloat widthPerSlice = (width / slicesCount);
    CGSize sizePerSlice = CGSizeMake(widthPerSlice, imageSize.height);

    // For each needed slice
    for (int i = 0; i < slicesCount; i++) {
        // How far along the image are we already
        CGPoint drawPoint = CGPointMake(-(widthPerSlice * i), 0);

        // Create a new context to draw to
        UIGraphicsBeginImageContextWithOptions(sizePerSlice, NO, image.scale);
        // Draw at an offset so only part of the image is visble, the rest is cropped.
        [image drawAtPoint:drawPoint];
        // Get the current contexts image
        UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
        // Finish up
        UIGraphicsEndImageContext();

        // Now save the resulting image.
        [newArray addObject:viewImage];
    }

    return newArray;
}

// Just refresh everything
-(void)updateAll{
    NSArray *imageArray = [self slipImage:self.viewImage intoSlices:self.slices];
    [self updateSlicesFromImageArray:imageArray];
}

// Just render the images into UIImageViews on screen.
-(void)updateSlicesFromImageArray:(NSArray*)array{
    // Remove all the old views.
    for (int i = 0; i < [self.viewSlices count]; i++) {
        UIView *view = (UIView*)[self.viewSlices objectAtIndex:i];
        [view removeFromSuperview];
        [self.viewSlices removeObject:view];
    }


    for (int i = 0; i < [array count]; i++) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[array objectAtIndex:i]];
        imageView.contentMode = UIViewContentModeScaleToFill;

        // Do you want it to be the size of the image or fill the screen?
        // Comment this out to be the size of the image
        CGFloat width = self.bounds.size.width/[array count];
        CGRect frame = imageView.frame;
        frame.size.width = width;
        frame.size.height = self.bounds.size.height;
        imageView.frame = frame;

        [self addSubview:imageView];
        [self.viewSlices addObject:imageView];
        [imageView release];
    }

    [self layoutSlicesForPercentage:0];
}

#pragma mark - Handle touches

-(void)move:(UIPanGestureRecognizer*)gestureRecognizer{
    CGPoint translation = [gestureRecognizer translationInView:self];
    CGFloat completition = (translation.x / (self.bounds.size.width * 0.8)); // 0-1

    // Stop anything weird from happening
    if (completition > 1) { completition = 1; }
    if (completition < 0 ) { completition = 0; }

    [self layoutSlicesForPercentage:completition];

    // As it's just a demo finish up, you'll want to add some code to check whether or not to actually consider it as "unlocked" here.
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
        // Animate it back into place.
        [UIView beginAnimations:nil context:nil];
        [self layoutSlicesForPercentage:0];
        [UIView commitAnimations];
    }
}

// percentage goes from 0 - 1
-(void)layoutSlicesForPercentage:(CGFloat)percentage{
    // For each view, rotate it
    for (int i = 0; i < [self.viewSlices count]; i++) {
        CGFloat degrees = 90 * percentage; // How far along are we?
        if ((i % 2) == 0) {
            degrees = 360-degrees; // rotate either forward or backwards.
        }
        // I think in degrees but iOS uses radians so I need to convert it.
        CGFloat rotation = DEGREES_TO_RADIANS(degrees);

        // Get the view
        UIView *view = [self.viewSlices objectAtIndex:i];
        // Set the transform as a standard one..
        CATransform3D rotate = CATransform3DIdentity;
        rotate.m34 = -1/500.0; // .. with a perspective
        // ...and rotate it.
        rotate = CATransform3DRotate(rotate, rotation, 0.0f, 1.0f, 0.0f);
        view.layer.transform = rotate;
    }

    // Replace this with modifying the translation above ^
    BOOL startPoint = NO;
    CGFloat currentX = self.bounds.size.width;

    // Now run backwards through the array to lay the views out end to end (so it shrinks rather then flies apart)
    for (int i = 0; i < [viewSlices count]; i++) {
        UIView *view = [viewSlices objectAtIndex:([viewSlices count] - 1 - i)];

        // This anchor point stuff is needed or there's a gap between the views forming as they rotate.
        // We start at the the right side for the last view and switch each time.
        CGFloat x = (startPoint ? 0.0 : 1.0);
        view.layer.anchorPoint = CGPointMake(x, view.layer.anchorPoint.y);

        // Set the view's position where we want it.
        if (view.layer.anchorPoint.x == 1) {
            view.layer.position = CGPointMake(currentX, view.layer.position.y);
        }
        else {
            currentX -= (view.frame.size.width * 2);
            view.layer.position = CGPointMake(currentX, view.layer.position.y);
        }

        startPoint = !startPoint;
    }
}

@end
