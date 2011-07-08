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
#import "TocViewController.h"
#import "MagazineStructure.h"
#import "PageViewController.h"
#import "TOCUIImage.h"

#import <QuartzCore/QuartzCore.h>

/*
*/
@implementation PageSelectButton

@synthesize chapterIdx, pageIdx, thumbURI;

- (void) dealloc {
	[super dealloc];
	[thumbURI release];
}

@end

/*
*/
@implementation TocViewController

@synthesize selectedButton, selectedPage;

/*
Draws the table of contents.
 */
- (void) viewDidLoad {
	
	scrollView.delegate = self;
  
	MagazineStructure *structure = [MagazineStructure sharedInstance];
  NSArray *chapters = structure.chapters;
	
	float thumbXpos = 0.0;
	int chapterIdx = 0;
	int pageIdx = 0;
  
	for(Chapter *chapter in chapters) {
		NSArray *pages =  chapter.pages;
		
		UILabel *l = [[[UILabel alloc] initWithFrame:CGRectMake(thumbXpos - 40.0, 65.0, 128.0, 25.0)] autorelease];
		
		l.backgroundColor = [UIColor clearColor];
		l.textColor = [UIColor whiteColor];
		l.textAlignment = UITextAlignmentCenter;
		l.text = chapter.title;
		l.font = [UIFont fontWithName:@"helvetica" size:17.0];
		
		l.shadowColor = [UIColor blackColor];
		l.shadowOffset = CGSizeMake(1.0, 1.0);
		
		l.transform = CGAffineTransformMakeRotation(degreesToRadians(270.0));
		
		[scrollView addSubview:l];
	
		if([l.text isEqualToString:@""]) {
			thumbXpos += 10.0;
		} else {
			thumbXpos += 60.0;
		}
	
    // Pages
		for(Page *page in pages) {
			// Load thumbnail.
			NSString *thumbName = [@"thumb_" stringByAppendingString:page.image];
      
			PageSelectButton *pageButton = [PageSelectButton buttonWithType:UIButtonTypeCustom];
			[pageButton addTarget:self action:@selector(selectPage:) forControlEvents:UIControlEventTouchUpInside];
      
			pageButton.frame = CGRectMake(thumbXpos, 15.0, 170.0, 128.0);
			
			pageButton.thumbURI = thumbName;
			pageButton.backgroundColor = [UIColor darkGrayColor];
	
			pageButton.highlighted = NO;
			pageButton.chapterIdx = chapterIdx; 
			pageButton.pageIdx = pageIdx;
    
			[scrollView addSubview:pageButton];
      
      pageButton.layer.masksToBounds = NO;
      pageButton.layer.shadowOffset = CGSizeMake(-5, 10);
      pageButton.layer.shadowRadius = 5;
      pageButton.layer.shadowOpacity = 0.4;
      
      pageButton.layer.shadowPath = [UIBezierPath bezierPathWithRect:pageButton.bounds].CGPath;
			
			// [pageButton addSubview:shade];
			thumbXpos += pageButton.frame.size.width + 10.0;
			
			pageIdx++;
		}
		
		chapterIdx++;
	}
	// Height 10px higher as content.
	[scrollView setContentSize:CGSizeMake(thumbXpos, 140.0)];
}

/*
Find the button that is active, highlight it and scroll to it.
 */
- (void) viewDidAppear:(BOOL)animated {
	
	if(selectedPage != nil) { 
    MagazineStructure *structure = [MagazineStructure sharedInstance];
    int pIdx = [structure.allPages indexOfObject:selectedPage];
    
    PageSelectButton *button = nil;
    
    for(UIView *vw in scrollView.subviews) { 
      if([vw isKindOfClass:PageSelectButton.class]) {
        PageSelectButton *b = (PageSelectButton *) vw;
        if(b.pageIdx == pIdx) 
          button = b;
      }
    }	
    if(button != nil) {
      [self highlightPageButton:button animated:NO];
    }
	}
}

/*
Highlights the selected TOC item and scrolls to it.
 */
- (void) highlightPageButton:(PageSelectButton *)button animated:(BOOL)animated {
	
	if(selectedButton != nil)
		selectedButton.layer.borderWidth = 0.0;
  
	self.selectedButton = button;
	
	selectedButton.layer.borderWidth = 2.0;
  UIColor *p = [UIColor whiteColor];
	selectedButton.layer.borderColor = p.CGColor;
		
	CGRect scrollFrame = button.frame;
	
	if(scrollFrame.origin.x > scrollView.contentSize.width - 1024.0) {
		// FIXME
		// scrollFrame.origin.x = scrollView.contentSize.width - 512.0;
	}
	else if(scrollFrame.origin.x > scrollView.contentOffset.x + 512.0) {
		scrollFrame.origin.x += scrollView.frame.size.width / 2  - (button.frame.size.width / 2);
	} 
	else {
		scrollFrame.origin.x -= scrollView.frame.size.width / 2  - (button.frame.size.width / 2);
	}
	
	[scrollView scrollRectToVisible:scrollFrame animated:animated];
	
	if(scrollView.contentOffset.x == 0.0) {
		[self scrollViewDidScroll:scrollView];
	}	
}

/*
 */
- (void) selectPage:(PageSelectButton *)button { 
	
	if([self.delegate isAnimating]) 
		return;
	
	if(button == selectedButton) 
		return;
	
	[self highlightPageButton:button animated:YES];
	
	MagazineStructure *structure = [MagazineStructure sharedInstance];
	Page *page = [structure.allPages objectAtIndex:button.pageIdx];
	
	[self.delegate browseToPage:page animated:YES];
}

#pragma mark -
#pragma mark Scrollview delegate

/*
Only load the buttons that are currently visible.
*/
- (void)scrollViewDidScroll:(UIScrollView *)_scrollView {
	
	float xOffset = _scrollView.contentOffset.x;
	
	// Which buttons to load?
	for(UIView *sv in [scrollView subviews]) {
		if([sv isKindOfClass:PageSelectButton.class]) {
			
			PageSelectButton *pageButton = (PageSelectButton *) sv;
			
			if(pageButton.frame.origin.x > (xOffset - 170.0)
				 && pageButton.frame.origin.x < xOffset + (_scrollView.frame.size.width + 170.0)) {
				
				UIImage *pageThumbImage = [UIImage imageNamed:pageButton.thumbURI];
				[pageButton setImage:pageThumbImage forState:UIControlStateNormal];

			} else {
				[pageButton setImage:nil forState:UIControlStateNormal];
			}
		}
	}
}

/*
 */
- (void) cleanUp {
	
	scrollView.delegate = nil;	
}

- (void)dealloc {
	
	[super dealloc];
	[selectedButton release];
}


@end
