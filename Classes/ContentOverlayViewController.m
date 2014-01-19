/*
 * Copyright (c) 2011 Metamotifs
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
#import "ContentOverlayViewController.h"
#import "TouchXML.h"
#import "MagazineStructure.h"
#import <QuartzCore/QuartzCore.h>

@implementation ContentOverlayViewController

/**
 */
- (void) loadOverlay:(Overlay *)overlay
{
	self.overlay = overlay;
    
	CGRect buttonFrame = _extraContentButton.frame;
	
	buttonFrame.origin.x = overlay.xPos;
	buttonFrame.origin.y = overlay.yPos;
    
    // Position the button that will show the item list.
	_extraContentButton.frame = buttonFrame;
}

/**
 */
- (IBAction) showContentList
{
	UITableViewController *controller = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
	
	controller.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	controller.tableView.dataSource = self;
	controller.tableView.delegate = self;
	
	UIImageView *bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"app_bg_wide.png"]];
	bgView.autoresizesSubviews = NO;
	bgView.contentMode = UIViewContentModeTopLeft;
    
	controller.tableView.backgroundView = bgView;
	controller.preferredContentSize = CGSizeMake(300.0, self.overlay.items.count * 44.0);
	
	UIPopoverController *popOver = [[UIPopoverController alloc] initWithContentViewController:controller];
	_currentPopOver = popOver;
	
	[_currentPopOver presentPopoverFromRect:_extraContentButton.frame inView:self.view
           permittedArrowDirections:(UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight) animated:YES];
}

#pragma mark -
#pragma mark TableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.overlay.items.count;
}

/**
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"extraContentCell"];
	
	if(cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"extraContentCell"];
		cell.textLabel.textColor = [UIColor whiteColor];
		cell.textLabel.shadowColor = [UIColor blackColor];
		cell.textLabel.shadowOffset = CGSizeMake(1, 1);
	}
	
	ContentItem *item = [self.overlay.items objectAtIndex:indexPath.row];
	
	cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:17.0];
	cell.textLabel.text = item.title;
	cell.backgroundColor = [UIColor clearColor];
	
	switch(item.type) {
		default:
            cell.imageView.image = [UIImage imageNamed:@"71-compass.png"];
			break;
	}
    
	// cell.imageView
	return cell;
}

/**
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(_currentPopOver != nil) {
		[_currentPopOver dismissPopoverAnimated:YES];
	}
	
	ContentItem *item = [self.overlay.items objectAtIndex:indexPath.row];
	[tableView cellForRowAtIndexPath:indexPath].selected = NO;
	
    // Based on item type, show the correct viewer.
    WebbrowserViewController *viewer = [[WebbrowserViewController alloc] init];
    viewer.type = item.type;
    viewer.barTitle = item.title;
	viewer.item = item;
	
	viewer.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	viewer.modalPresentationStyle = UIModalPresentationPageSheet;
	
	[self.delegate presentViewController:viewer animated:YES completion:nil];
    
    viewer.view.superview.frame = CGRectMake(0.0, 0.0, 780.0, 700.0);
    
	// Load the item. POST
	[viewer viewContentItem];
}


#pragma mark -
#pragma mark Utility to align button, uncomment to use.

/*
 - (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
 //
 }
 
 - (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
     NSLog(@"touchesBegan");
     
     for(UITouch *touch in [touches allObjects]) {
     
     CGPoint point = [touch locationInView:self.view];
     
     NSLog(@"x: %f, y: %f", point.x, point.y);
     
     CGRect buttonFrame = extraContentButton.frame;
     
     buttonFrame.origin.x = point.x - 20.0;
     buttonFrame.origin.y = point.y;
     
     extraContentButton.frame = buttonFrame;
     }
     
     [self touchesCancelled:touches withEvent:event];
 }
 */

@end
