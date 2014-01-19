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
#import "SideViewController.h"
#import "OverlayViewController.h"
#import "PageControllerDelegate.h"

#define VIEW_TAG_BOTTOM_LAYER 100
#define VIEW_TAG_MAIN_LAYER 101
#define VIEW_TAG_OVERLAY_LAYER 102

#define degreesToRadians(x) (M_PI * x / 180.0)
#define radiansToDegrees(x) (x * 180.0 / M_PI)

typedef enum {
	kPageTurnDirectionRight = 0,
	kPageTurnDirectionLeft = 1
} kPageTurnDirection;

//
//
//
@interface PageViewController : UIViewController <PageControllerDelegate>
{
	BOOL _sideLayerVisible;
	kPageTurnDirection _currentDirection;
	
	IBOutlet UIView *_mainLayer;
	IBOutlet UIView *_bottomLayer;
	IBOutlet UIImageView *_imageBuffer;
	IBOutlet UIView *_pageContainer;
	IBOutlet UIImageView *_leftPage;
	IBOutlet UIImageView *_rightPage;
	IBOutlet UIView *_turnContainer;
	IBOutlet UIImageView *_turnLeftPage;
	IBOutlet UIImageView *_turnRightPage;
	IBOutlet UIView *_overlayContainer;
	IBOutlet UIView *_menuView;
	
	// Effect layers.
	IBOutlet UIImageView *_fxBookShadow;
	IBOutlet UIView *_fxLeafShadow;
    
    UITapGestureRecognizer *_tapRecognizer;
}

@property BOOL animating;
@property (nonatomic, strong) UIImage *cachedTurnImage;
@property (nonatomic, strong) UIImage *currentPageImage;
@property (nonatomic, strong) NSArray *pages;
@property (nonatomic, strong) Page *currentPage;

// Side controllers open up from the bottom or the side (twitter, toc)
// Overlay controllers oare overlayed over the current page (webbrowser, map, etc)
@property (nonatomic, strong) SideViewController *sideController;
@property (nonatomic) OverlayViewController *overlayController;

- (IBAction) showSideController:(UIButton *)sender;

- (void) turnPage:(kPageTurnDirection)direction animated:(BOOL)animated;
- (void) animatePageTurn:(kPageTurnDirection) turnDirection;
- (void) browseToPage:(Page *)page animated:(BOOL)animated;
- (UIImage *) blendedImage;
- (void) loadOverlay:(Overlay *)overlay;
- (void) removeOverlay;
- (void) showSideContainerWithStopSelector:(SEL)selector;
- (void) cleanupSideLayer:(NSString *)animationID finished:(BOOL)finished context:(void *)context;
- (void) pageAnimationComplete:(NSString *)animationID finished:(BOOL)finished context:(void *)context;

@end
