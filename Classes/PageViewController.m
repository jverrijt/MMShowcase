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

@synthesize animating, pages, currentPage;
@synthesize sideController, overlayController; 
@synthesize cachedTurnImage, currentPageImage;

/*
 */
- (void) viewDidLoad {

	turnContainer.layer.zPosition = 1000;
	turnContainer.hidden = YES;
	
	menuView.layer.zPosition = 1001;
	menuView.layer.cornerRadius = 5.0;

	// Reset origins set in IB.
	CGRect mainLayerFrame = mainLayer.frame;
	mainLayerFrame.origin.y = 0;
	mainLayer.frame = mainLayerFrame;

	// Setup the gesture recognizers that recoginize the page swipes
	UISwipeGestureRecognizer *leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextPage)];
	leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
	
	UISwipeGestureRecognizer *rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(prevPage)];
	rightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
	
	// For use when bottom container is showing.
	tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
	tapRecognizer.numberOfTapsRequired = 1;
	
	[mainLayer addGestureRecognizer:leftSwipeRecognizer];
	[mainLayer addGestureRecognizer:rightSwipeRecognizer];
	
	[leftSwipeRecognizer release];
	[rightSwipeRecognizer release];
}

/*
*/
- (void) viewDidAppear:(BOOL)animated { 
	[self browseToPage:[pages objectAtIndex:0] animated:NO];
}

/*
*/
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if(UIInterfaceOrientationIsLandscape(interfaceOrientation))
		return YES; 
	
	return NO;
}

/*
Close and clean up the side layer when tapped.
 */
- (void) tapped:(UISwipeGestureRecognizer *)recognizer {
	
	if(sideLayerVisible) {
		[self showSideContainerWithStopSelector:@selector(cleanupSideLayer:finished:context:)];
	}
}

/*
Sets the next page and initiates the page turn effect.
 */
- (IBAction) nextPage {

  if(animating || sideLayerVisible)
		return;
	
  Page *nextPage = [[MagazineStructure sharedInstance] pageAfter:currentPage];
  
  // Set the current page to the new page.
  if(nextPage != nil) {
    self.currentPage = nextPage;
    [self turnPage:kPageTurnDirectionLeft animated:YES];
  } else { 
    // Go back to the first page? 
  }
}

/*
Sets the previous page and initiates the page turn effect.
 */
- (IBAction) prevPage {

	if(animating || sideLayerVisible)
		return;
	
  Page *prevPage = [[MagazineStructure sharedInstance] pageBefore:currentPage];
  
  // Set the current page to the new page.
  if(prevPage != nil) {
    self.currentPage = prevPage;
    [self turnPage:kPageTurnDirectionRight animated:YES];
  } else { 
    // Go to the last page?
  }
}

/*
 Browse to a given page.
 */
- (void) browseToPage:(Page *)page animated:(BOOL)animated {
	
	MagazineStructure *structure = [MagazineStructure sharedInstance];
	
	int oldIdx = [structure.allPages indexOfObject:currentPage];
	int newIdx = [structure.allPages indexOfObject:page];
	
	self.currentPage = page;
	kPageTurnDirection direction = (newIdx > oldIdx ? kPageTurnDirectionLeft : kPageTurnDirectionRight);
	
	[self turnPage:direction animated:animated];
}	

/*
 Resets all transformations and perspectives.
 */
- (void) resetAnimationState {
	
	turnContainer.layer.transform = CATransform3DIdentity;
	CATransform3D matrix = turnContainer.layer.transform;
	
	matrix.m34 = 1.0 / 1000;
	turnContainer.layer.transform = matrix;			
	
	turnLeftPage.transform = CGAffineTransformIdentity;
	turnRightPage.transform = CGAffineTransformIdentity;
}

/*
 Sets and possible blends the image buffer of a given page.
 */
- (void) setImageBufferForPage:(Page *)page {

	// Set the imageBuffer to the new situation.
	NSString *img = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], page.image];
	self.currentPageImage = [UIImage imageWithContentsOfFile:img]; 
	
	imageBuffer.image = currentPageImage;
  
	// Load overlay and blend its layer into the imageBuffer.
	Overlay *overlay = page.overlay;	
  
	if(overlay != nil) {
		[self loadOverlay:overlay];
    
		UIImage *blended = [self blendedImage];
		imageBuffer.image = blended;
	}
}

/*
 Turn page in given direction.
 */
- (void) turnPage:(kPageTurnDirection)direction animated:(BOOL)animated { 
	
	if(animating) 
		return;
	
	leftPage.image = imageBuffer.image;
	rightPage.image = imageBuffer.image;
	
	[self removeOverlay];
	// Set the image buffer.
	[self setImageBufferForPage:currentPage];
	
	// Should animate?
	if(!animated) {
		[self pageAnimationComplete:@"turnPage" finished:YES context:nil];
		return;
	} 
	
	// Animation in progress.
	animating = YES;
	
	[self resetAnimationState];
	turnContainer.hidden = NO;
	
	if(direction == kPageTurnDirectionLeft) {
		// Turnpage adopts current leaf image
		turnRightPage.image = rightPage.image;
		turnRightPage.hidden = NO;
		turnRightPage.contentMode = UIViewContentModeTopRight;

		turnLeftPage.hidden = YES;
		turnLeftPage.image = nil;
		
		// Page below turn page gets set to new situation.
		rightPage.image = imageBuffer.image;	
		
		// Improve smoothness of animation.
		self.cachedTurnImage = imageBuffer.image;
    
	} else {
		turnLeftPage.image = leftPage.image;
		turnLeftPage.hidden = NO;
		turnLeftPage.contentMode = UIViewContentModeTopLeft;
		
		turnRightPage.hidden = YES;
		turnRightPage.image = nil;
		
		leftPage.image = imageBuffer.image;		
		self.cachedTurnImage = imageBuffer.image;
	}
	
	[self animatePageTurn:direction];
}

/*
 Animates the page transition.
 */
- (void) animatePageTurn:(kPageTurnDirection)turnDirection { 
	
	currentDirection = turnDirection;
	UIImageView *currentLeaf = currentDirection == kPageTurnDirectionRight ? turnLeftPage : turnRightPage;
	
	fxLeafShadow.frame = currentLeaf.frame;
	fxLeafShadow.hidden = NO;
	
	float rad = degreesToRadians(90.0);	
	rad = currentDirection == kPageTurnDirectionRight ? -rad : rad;
	
	CATransform3D leftTransform = CATransform3DRotate(turnContainer.layer.transform, rad, 0.0f, 1.0f, 0.0f);
	
  // Animate it.
	[UIView beginAnimations:@"pageTurn" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(pageTurnInMiddle:finished:context:)];
	
	currentLeaf.alpha  = 0.32;
	fxBookShadow.alpha = 0.65;
	turnContainer.layer.transform = leftTransform;
	
	[UIView commitAnimations];	
}

/*
Page turn animation 50% done.
 */
- (void) pageTurnInMiddle:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
	
	// Switch the page.
	UIImageView *currentLeaf = currentDirection == kPageTurnDirectionRight ? turnLeftPage : turnRightPage;
	currentLeaf.contentMode = currentDirection == kPageTurnDirectionRight ? UIViewContentModeTopRight : UIViewContentModeTopLeft;
	currentLeaf.image = cachedTurnImage;
	
	// we'll need to flip it. 	
	CGAffineTransform flip = CGAffineTransformScale(currentLeaf.transform, -1, 1);
	currentLeaf.transform = flip;
	
	float rad = degreesToRadians(90.0);
	rad = currentDirection == kPageTurnDirectionRight ? -rad : rad;
	CATransform3D transform = CATransform3DRotate(turnContainer.layer.transform, rad, 0.0f, 1.0f, 0.0f);
  
  // Animate it.	
	[UIView beginAnimations:@"pageTurn" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:0.5];
	
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(pageAnimationComplete:finished:context:)];
	
	currentLeaf.alpha = 1.0;
	fxBookShadow.alpha = 0.0;
	turnContainer.layer.transform = transform;
	
	[UIView commitAnimations];
}

/*
 Animation complete. Restore original state.
 */
- (void) pageAnimationComplete:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
	
	animating = NO;
	fxLeafShadow.hidden = YES;
	
	// Restore status quo.
	leftPage.image = currentPageImage;
	rightPage.image = currentPageImage;

	turnContainer.hidden = YES;
	
	// Bring overlay to front.
	Overlay *overlay = currentPage.overlay;
	
	if(overlay != nil && overlayController != nil) {
		[mainLayer bringSubviewToFront:overlayContainer];
		[mainLayer bringSubviewToFront:menuView];
	}	
}

/*
Blends the view for the overlay into the page and returns it as image.
 */
- (UIImage *) blendedImage { 
  
	UIGraphicsBeginImageContext(imageBuffer.frame.size);
	
	[imageBuffer.layer renderInContext:UIGraphicsGetCurrentContext()];
	[overlayContainer.layer renderInContext:UIGraphicsGetCurrentContext()];
	
	UIImage *blended = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
  
	return blended;
}

#pragma mark - 
#pragma mark Overlay code.

/*
Loads and manages a page overlay.
 */
- (void) loadOverlay:(Overlay *)overlay { 
	
	NSString *overlayType = overlay.overlayType;

	if([overlayType isEqualToString:@"extraContent"]) {
		
		if(overlayController != nil) 
			[overlayController release];
		
		ContentOverlayViewController *overlayCtrl = [ContentOverlayViewController new];
		
		[overlayContainer addSubview:overlayCtrl.view];	
		[mainLayer sendSubviewToBack:overlayContainer];

		overlayCtrl.delegate = self;
		
		[overlayCtrl loadOverlay:overlay];

		// This is an assign. not retained.
		self.overlayController = overlayCtrl; 
	}
	
	overlayContainer.hidden = NO;
}


/*
 Removing overlay.
 */
- (void) removeOverlay {
	
	// Clear exisiting overlays.
	overlayContainer.hidden = YES;
	
	for(UIView *overlayView in overlayContainer.subviews) {
		[overlayView removeFromSuperview];
	}
	
	if(overlayController != nil) {
		[overlayController release];
		self.overlayController = nil;
	}
}

#pragma mark -
#pragma mark Actions.

/*
 */
- (IBAction) showSideController:(UIButton *)sender {
	
	Class c = (sender.tag == 0 ? [TwitterViewController class] : [TocViewController class]);
	SEL reopenSelector = nil;
	
	if(sideLayerVisible) {
		
		// Bottom controller of different kind.
		if(sideController != nil && ![sideController isKindOfClass:c]) {
			
			[sideController cleanUp];
			
			SideViewController *controller = [[c alloc] init];
			controller.selectedPage = currentPage;
			controller.delegate = self;
			
			self.sideController = controller;
			[controller release];
			
			reopenSelector = @selector(reopenSideLayer:finished:context:);
		} else {
			// Close and clean it up normally
			reopenSelector = @selector(cleanuSideLayer:finished:context:);
		}
		
	} else {
		
		// Bottom layer not visible. show it.
		SideViewController *controller = [[c alloc] init];
		controller.selectedPage = currentPage;
		controller.delegate = self;
		
		self.sideController = controller;
		[controller release];
		
		for(UIView *sv in bottomLayer.subviews) {
			[sv removeFromSuperview];
		}
		
		// remove the tap recognizer
		[mainLayer removeGestureRecognizer:tapRecognizer];
		
		UIView *vw = sideController.view;
		[bottomLayer addSubview:vw];
		
		[sideController viewDidAppear:NO];
	}
	
	[self showSideContainerWithStopSelector:reopenSelector];
}

/*
 Animates the side container into view.
 */
- (void) showSideContainerWithStopSelector:(SEL)selector {
	
	sideLayerVisible = !sideLayerVisible;
	
	if(sideLayerVisible) {
		[mainLayer addGestureRecognizer:tapRecognizer];
	}
	
	[UIView beginAnimations:@"showBottomView" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:selector];
	
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:0.5];
	
	CGRect mainLayerFrame = mainLayer.frame;
	CGRect menuLayerFrame = menuView.frame;
	
	mainLayerFrame.origin.y = sideLayerVisible ? -155 : 0;	
	menuLayerFrame.origin.y -= sideLayerVisible ? 155 : -155;	
	
	mainLayer.frame = mainLayerFrame;
	menuView.frame = menuLayerFrame;
	
	menuView.alpha = sideLayerVisible ? 1.0 : 0.45;
	
	[UIView commitAnimations];
}
		 
/*
 Reopens side layer
 */
- (void) reopenSideLayer:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
	
	// Remove old views from bottom layer.	
	for(UIView *sv in bottomLayer.subviews) {
		[sv removeFromSuperview];
	}
	
	// remove the tap recognizer
	[mainLayer removeGestureRecognizer:tapRecognizer];
	
	UIView *vw = sideController.view;
	[bottomLayer addSubview:vw];
	[sideController viewDidAppear:NO];
	
	[self showSideContainerWithStopSelector:nil];
}
																	 
/*
 Cleans up side layer
 */
- (void) cleanupSideLayer:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
		
	if(sideLayerVisible == NO)  {
		[sideController cleanUp];
		
		for(UIView *sv in bottomLayer.subviews) {
			[sv removeFromSuperview];
		}
		
		// remove the tap recognizer
		[mainLayer removeGestureRecognizer:tapRecognizer];
		
		self.sideController = nil;
	}
}

#pragma mark - 
#pragma mark PageControllerDelegate

- (BOOL) isAnimating { 
  return animating;
}

/*
 */
- (void)dealloc {

	[pages release];
	[currentPage release];
	[currentPageImage release];
	[sideController release];
	[overlayContainer release];
	[overlayController release];
	[tapRecognizer release];
	[cachedTurnImage release];	
	[imageBuffer release];
	[leftPage release];
	
	[super dealloc];
}


@end
