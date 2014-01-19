/*
 * Copyright (c) 2011 Metamotifs - Joost Verrijt <joost at metamotifs.nl>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
#import "PageViewController.h"
#import "TocViewController.h"
#import "TwitterViewController.h"
#import "MagazineStructure.h"

#import "ViewUtil.h"
#import "ContentOverlayViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

@implementation PageViewController

/**
*/
- (void) viewDidLoad
{
    _turnContainer.layer.zPosition = 1000;
    _turnContainer.hidden = YES;

    _menuView.layer.zPosition = 1001;
    _menuView.layer.cornerRadius = 5.0;

    // Reset origins set in IB.
    CGRect mainLayerFrame = _mainLayer.frame;
    mainLayerFrame.origin.y = 0;
    _mainLayer.frame = mainLayerFrame;

    // Setup the gesture recognizers that recoginize the page swipes
    UISwipeGestureRecognizer *leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                              action:@selector(nextPage)];
    leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;

    UISwipeGestureRecognizer *rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                               action:@selector(prevPage)];
    rightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;

    // For use when bottom container is showing.
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    _tapRecognizer.numberOfTapsRequired = 1;

    [_mainLayer addGestureRecognizer:leftSwipeRecognizer];
    [_mainLayer addGestureRecognizer:rightSwipeRecognizer];
}

/**
*/
- (void) viewDidAppear:(BOOL)animated
{
    [self browseToPage:[_pages objectAtIndex:0] animated:NO];
}

/**
*/
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        return YES;
    }
    return NO;
}

/**
  Close and clean up the side layer when tapped.
  */
- (void) tapped:(UISwipeGestureRecognizer *)recognizer
{
    if(_sideLayerVisible) {
        [self showSideContainerWithStopSelector:@selector(cleanupSideLayer:finished:context:)];
    }
}

/**
  Sets the next page and initiates the page turn effect.
  */
- (IBAction) nextPage
{
    if(_animating || _sideLayerVisible)
        return;

    Page *nextPage = [[MagazineStructure sharedInstance] pageAfter:_currentPage];

    // Set the current page to the new page.
    if(nextPage != nil) {
        self.currentPage = nextPage;
        [self turnPage:kPageTurnDirectionLeft animated:YES];
    } else {
        // Go back to the first page?
    }
}

/**
  Sets the previous page and initiates the page turn effect.
  */
- (IBAction) prevPage
{
    if(_animating || _sideLayerVisible)
        return;

    Page *prevPage = [[MagazineStructure sharedInstance] pageBefore:_currentPage];

    // Set the current page to the new page.
    if(prevPage != nil) {
        self.currentPage = prevPage;
        [self turnPage:kPageTurnDirectionRight animated:YES];
    } else {
        // Go to the last page?
    }
}

/**
  Browse to a given page.
  */
- (void) browseToPage:(Page *)page animated:(BOOL)animated
{
    MagazineStructure *structure = [MagazineStructure sharedInstance];

    int oldIdx = [structure.allPages indexOfObject:_currentPage];
    int newIdx = [structure.allPages indexOfObject:page];

    self.currentPage = page;
    kPageTurnDirection direction = (newIdx > oldIdx ? kPageTurnDirectionLeft : kPageTurnDirectionRight);

    [self turnPage:direction animated:animated];
}

/**
  Resets all transformations and perspectives.
  */
- (void) resetAnimationState
{
    _turnContainer.layer.transform = CATransform3DIdentity;
    CATransform3D matrix = _turnContainer.layer.transform;

    matrix.m34 = 1.0 / 1000;
    _turnContainer.layer.transform = matrix;

    _turnLeftPage.transform = CGAffineTransformIdentity;
    _turnRightPage.transform = CGAffineTransformIdentity;
}

/**
  Sets and possible blends the image buffer of a given page.
  */
- (void) setImageBufferForPage:(Page *)page
{
    // Set the imageBuffer to the new situation.
    NSString *img = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], page.image];
    self.currentPageImage = [UIImage imageWithContentsOfFile:img];

    _imageBuffer.image = _currentPageImage;

    // Load overlay and blend its layer into the imageBuffer.
    Overlay *overlay = page.overlay;

    if(overlay != nil) {
        [self loadOverlay:overlay];

        UIImage *blended = [self blendedImage];
        _imageBuffer.image = blended;
    }
}

/**
  Turn page in given direction.
  */
- (void) turnPage:(kPageTurnDirection)direction animated:(BOOL)animated
{
    if(_animating) {
        return;
    }

    _leftPage.image = _imageBuffer.image;
    _rightPage.image = _imageBuffer.image;

    [self removeOverlay];
    // Set the image buffer.
    [self setImageBufferForPage:_currentPage];

    // Should animate?
    if(!animated) {
        [self pageAnimationComplete:@"turnPage" finished:YES context:nil];
        return;
    }

    // Animation in progress.
    _animating = YES;

    [self resetAnimationState];
    _turnContainer.hidden = NO;

    if(direction == kPageTurnDirectionLeft) {
        // Turnpage adopts current leaf image
        _turnRightPage.image = _rightPage.image;
        _turnRightPage.hidden = NO;
        _turnRightPage.contentMode = UIViewContentModeTopRight;

        _turnLeftPage.hidden = YES;
        _turnLeftPage.image = nil;

        // Page below turn page gets set to new situation.
        _rightPage.image = _imageBuffer.image;

        // Improve smoothness of animation.
        self.cachedTurnImage = _imageBuffer.image;
    } else {
        _turnLeftPage.image = _leftPage.image;
        _turnLeftPage.hidden = NO;
        _turnLeftPage.contentMode = UIViewContentModeTopLeft;

        _turnRightPage.hidden = YES;
        _turnRightPage.image = nil;

        _leftPage.image = _imageBuffer.image;
        self.cachedTurnImage = _imageBuffer.image;
    }

    [self animatePageTurn:direction];
}

/**
  Animates the page transition.
  */
- (void) animatePageTurn:(kPageTurnDirection)turnDirection
{
    _currentDirection = turnDirection;
    UIImageView *currentLeaf = _currentDirection == kPageTurnDirectionRight ? _turnLeftPage : _turnRightPage;

    _fxLeafShadow.frame = currentLeaf.frame;
    _fxLeafShadow.hidden = NO;

    float rad = degreesToRadians(90.0);
    rad = _currentDirection == kPageTurnDirectionRight ? -rad : rad;

    CATransform3D leftTransform = CATransform3DRotate(_turnContainer.layer.transform, rad, 0.0f, 1.0f, 0.0f);

    // Animate it.
    [UIView beginAnimations:@"pageTurn" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(pageTurnInMiddle:finished:context:)];

    currentLeaf.alpha  = 0.32;
    _fxBookShadow.alpha = 0.65;
    _turnContainer.layer.transform = leftTransform;

    [UIView commitAnimations];
}

/**
  Page turn animation 50% done.
  */
- (void) pageTurnInMiddle:(NSString *)animationID finished:(BOOL)finished context:(void *)context
{
    // Switch the page.
    UIImageView *currentLeaf = _currentDirection == kPageTurnDirectionRight ? _turnLeftPage : _turnRightPage;
    currentLeaf.contentMode = _currentDirection == kPageTurnDirectionRight ? UIViewContentModeTopRight : UIViewContentModeTopLeft;
    currentLeaf.image = _cachedTurnImage;

    // we'll need to flip it.
    CGAffineTransform flip = CGAffineTransformScale(currentLeaf.transform, -1, 1);
    currentLeaf.transform = flip;

    float rad = degreesToRadians(90.0);
    rad = _currentDirection == kPageTurnDirectionRight ? -rad : rad;
    CATransform3D transform = CATransform3DRotate(_turnContainer.layer.transform, rad, 0.0f, 1.0f, 0.0f);

    // Animate it.
    [UIView beginAnimations:@"pageTurn" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:0.5];

    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(pageAnimationComplete:finished:context:)];

    currentLeaf.alpha = 1.0;
    _fxBookShadow.alpha = 0.0;
    _turnContainer.layer.transform = transform;

    [UIView commitAnimations];
}

/**
  Animation complete. Restore original state.
  */
- (void) pageAnimationComplete:(NSString *)animationID finished:(BOOL)finished context:(void *)context
{
    _animating = NO;
    _fxLeafShadow.hidden = YES;

    // Restore status quo.
    _leftPage.image = _currentPageImage;
    _rightPage.image = _currentPageImage;

    _turnContainer.hidden = YES;

    // Bring overlay to front.
    Overlay *overlay = _currentPage.overlay;

    if(overlay != nil && _overlayController != nil) {
        [_mainLayer bringSubviewToFront:_overlayContainer];
        [_mainLayer bringSubviewToFront:_menuView];
    }
}

/**
  Blends the view for the overlay into the page and returns it as image.
  */
- (UIImage *) blendedImage
{
    UIGraphicsBeginImageContext(_imageBuffer.frame.size);

    [_imageBuffer.layer renderInContext:UIGraphicsGetCurrentContext()];
    [_overlayContainer.layer renderInContext:UIGraphicsGetCurrentContext()];

    UIImage *blended = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return blended;
}

#pragma mark -
#pragma mark Overlay code.

/**
  Loads and manages a page overlay.
  */
- (void) loadOverlay:(Overlay *)overlay 
{
    NSString *overlayType = overlay.overlayType;

    if([overlayType isEqualToString:@"extraContent"]) {

        ContentOverlayViewController *overlayCtrl = [ContentOverlayViewController new];

        [_overlayContainer addSubview:overlayCtrl.view];
        [_mainLayer sendSubviewToBack:_overlayContainer];

        overlayCtrl.delegate = self;

        [overlayCtrl loadOverlay:overlay];
        _overlayController = overlayCtrl;
    }

    _overlayContainer.hidden = NO;
}


/**
  Remove overlay.
  */
- (void) removeOverlay
{
    // Clear exisiting overlays.
    _overlayContainer.hidden = YES;

    for(UIView *overlayView in _overlayContainer.subviews) {
        [overlayView removeFromSuperview];
    }
}

#pragma mark -
#pragma mark Actions.

/**
*/
- (IBAction) showSideController:(UIButton *)sender 
{
    Class c = (sender.tag == 0 ? [TwitterViewController class] : [TocViewController class]);
    SEL reopenSelector = nil;

    if(_sideLayerVisible) {

        // Bottom controller of different kind.
        if(_sideController != nil && ![_sideController isKindOfClass:c]) {

            [_sideController cleanUp];

            SideViewController *controller = [[c alloc] init];
            controller.selectedPage = _currentPage;
            controller.delegate = self;

            self.sideController = controller;

            reopenSelector = @selector(reopenSideLayer:finished:context:);
        } else {
            // Close and clean it up normally
            reopenSelector = @selector(cleanuSideLayer:finished:context:);
        }

    } else {

        // Bottom layer not visible. show it.
        SideViewController *controller = [[c alloc] init];
        controller.selectedPage = _currentPage;
        controller.delegate = self;

        self.sideController = controller;

        for(UIView *sv in _bottomLayer.subviews) {
            [sv removeFromSuperview];
        }

        // remove the tap recognizer
        [_mainLayer removeGestureRecognizer:_tapRecognizer];

        UIView *vw = _sideController.view;
        [_bottomLayer addSubview:vw];

        [_sideController viewDidAppear:NO];
    }

    [self showSideContainerWithStopSelector:reopenSelector];
}

/**
  Animates the side container into view.
  */
- (void) showSideContainerWithStopSelector:(SEL)selector 
{
    _sideLayerVisible = !_sideLayerVisible;

    if(_sideLayerVisible) {
        [_mainLayer addGestureRecognizer:_tapRecognizer];
    }

    [UIView beginAnimations:@"showBottomView" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:selector];

    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:0.5];

    CGRect mainLayerFrame = _mainLayer.frame;
    CGRect menuLayerFrame = _menuView.frame;

    mainLayerFrame.origin.y = _sideLayerVisible ? -155 : 0;
    menuLayerFrame.origin.y -= _sideLayerVisible ? 155 : -155;

    _mainLayer.frame = mainLayerFrame;
    _menuView.frame = menuLayerFrame;

    _menuView.alpha = _sideLayerVisible ? 1.0 : 0.45;

    [UIView commitAnimations];
}

/**
  Reopens side layer
  */
- (void) reopenSideLayer:(NSString *)animationID finished:(BOOL)finished context:(void *)context
{
    // Remove old views from bottom layer.
    for(UIView *sv in _bottomLayer.subviews) {
        [sv removeFromSuperview];
    }

    // remove the tap recognizer
    [_mainLayer removeGestureRecognizer:_tapRecognizer];

    UIView *vw = _sideController.view;
    [_bottomLayer addSubview:vw];
    [_sideController viewDidAppear:NO];

    [self showSideContainerWithStopSelector:nil];
}

/**
  Cleans up side layer
  */
- (void) cleanupSideLayer:(NSString *)animationID finished:(BOOL)finished context:(void *)context
{
    if(_sideLayerVisible == NO)  {
        [_sideController cleanUp];

        for(UIView *sv in _bottomLayer.subviews) {
            [sv removeFromSuperview];
        }

        // remove the tap recognizer
        [_mainLayer removeGestureRecognizer:_tapRecognizer];

        self.sideController = nil;
    }
}

#pragma mark - 
#pragma mark PageControllerDelegate

- (BOOL) isAnimating
{
    return _animating;
}


@end
