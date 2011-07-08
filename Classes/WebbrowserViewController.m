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
#import "WebbrowserViewController.h"
#import "ViewUtil.h"

#import <QuartzCore/QuartzCore.h>

@implementation WebbrowserViewController

@synthesize barTitle, type, url;

- (void) viewDidLoad {
	
	webview.allowsInlineMediaPlayback = YES;
	webview.delegate = self;
  
	loadingIndicator.alpha = 0.0;
	loadingIndicator.layer.cornerRadius = 10.0;
  
  webview.scalesPageToFit = YES;
}


/*
FIXME Rotation is hardcoded to either portrait or landscape.
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if(UIInterfaceOrientationIsLandscape(interfaceOrientation))
		return YES; 
	
	return NO;
}

- (void) viewWillAppear:(BOOL)animated {
	
	bar.topItem.title = barTitle;	
}


/*
 */
- (void) viewContentItem { 
	[self loadRequestInWebview:self.item.item];
}


/*
 */
- (void) loadRequestInWebview:(NSString *)_url { 
  
	self.url = _url;
	NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
	[webview loadRequest:req];
}

/*
 */
- (IBAction) close {
	
	[webview stopLoading];	
	[webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
	
	webview.delegate = nil;
	webview = nil;
	
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark UIWebView delegate method. 

/*
 */
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
  return nil;
}


/*
 */
- (void)webViewDidStartLoad:(UIWebView *)webView {
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:1.0];
	
	loadingIndicator.alpha = 0.70;
	
	[UIView commitAnimations];
}

/*
 */
- (void)webViewDidFinishLoad:(UIWebView *)webView {
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:1.0];
	
	loadingIndicator.alpha = 0.0;
	
	[UIView commitAnimations];
}

/*
 */
- (IBAction) openInExternal {
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}


- (void) didReceiveMemoryWarning {
	
	[super didReceiveMemoryWarning];
}

- (void)dealloc {
	
	[webview release];
	[barTitle release];
	[url release];
	
	[super dealloc];
}


@end
