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
#import "TwitterViewController.h"
#import "NSString+encoding.h"
#import "MagazineStructure.h"
#import "TwitterMessageController.h"
#import "NSString+HTML.h"
#import <QuartzCore/QuartzCore.h>
#import "JSON.h"

@implementation TwitterViewController

/**
 */
- (void) viewDidAppear:(BOOL)animated {
	
	[_indicator startAnimating];
	
	MagazineStructure *structure = [MagazineStructure sharedInstance];
    
	Chapter *chapter = [structure.chapters objectAtIndex:self.selectedPage.chapterIdx];
	self.keywords = [chapter.twitterKeywords componentsSeparatedByString:@","];
	_twitterCatLabel.text = [_twitterCatLabel.text stringByAppendingFormat:@" %@", chapter.twitterCat];
	
	NSString *keywordStr = [_keywords componentsJoinedByString:@"\"+OR+\""];
    NSString *url = [NSString stringWithFormat:@"https://api.twitter.com/1.1/search/tweets.json?rpp=15&q=%%22%@%%22",
                     [keywordStr urlEncode]];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
        cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
    
	_conn = [NSURLConnection connectionWithRequest:request delegate:self];
    
	if(_conn) {
		self.receivedData = [NSMutableData data];
	}
}

#pragma mark -
#pragma mark URLConnection delegate

/**
 */
- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
{
	[_receivedData setLength:0];
}

/**
 */
- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
	[_receivedData appendData:data];
}

/**
 */
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	UIAlertView *vw = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not connect to Twitter. Try again later."
        delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
	[_indicator stopAnimating];
	[vw show];
}

/**
 */
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

/*
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
	NSString *json = [[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", json);
	
	NSDictionary *dict = [json JSONValue];
	NSArray *results = [[dict valueForKeyPath:@"results"] allObjects];
	
	float xPos = 10.0;
	for(NSDictionary *result in results) {
		TwitterMessageController *controller = [TwitterMessageController new];
		
		controller.username = [[[result objectForKey:@"from_user"] urlDecode] stringByDecodingHTMLEntities];
		controller.message = [[[result objectForKey:@"text"] urlDecode] stringByDecodingHTMLEntities];
		controller.profilePicUrl = [result objectForKey:@"profile_image_url"];
		
		// Don't include empty messages.
		if(controller.message == nil || [controller.message isEqualToString:@""]) {
			continue;
        }
		
		UIView *msgView = controller.view;
		msgView.frame = CGRectMake(xPos, 10.0, 300.0, 135.0);
		msgView.alpha = 0.75;
		
		msgView.layer.cornerRadius = 8.0f;
		msgView.clipsToBounds = NO;
		
        // Draw a drop shadow.
        msgView.layer.masksToBounds = NO;
        msgView.layer.shadowOffset = CGSizeMake(-5, 10);
        msgView.layer.shadowRadius = 5;
        msgView.layer.shadowOpacity = 0.4;
        msgView.layer.shadowPath = [UIBezierPath bezierPathWithRect:msgView.bounds].CGPath;
        
		[_scrollView addSubview:msgView];
		
		xPos += msgView.frame.size.width + 10.0;
	}
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:1.0];
	_indicator.alpha = 0.0;
	
	if(results.count == 0) {
		_noTweetsLabel.alpha = 1.0;
	}
	
	[UIView commitAnimations];
	
	[_scrollView setContentSize:CGSizeMake(xPos, 155.0)];
	self.receivedData = [NSMutableData data];
}

/**
 */
- (void) cleanUp
{
	_scrollView.delegate = nil;
}

/*
 Opens twitter profile.
 
 TODO: make configurable.
 */
- (IBAction) openTwitterPage
{
    // TODO make configurable. Replace with your own url
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.twitter.com/username/"]];
}

@end
