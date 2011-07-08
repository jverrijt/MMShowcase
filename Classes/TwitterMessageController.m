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
#import "TwitterMessageController.h"
#import "TwitterMessageView.h"
#import <QuartzCore/QuartzCore.h>

@implementation TwitterMessageController

@synthesize username, message, profilePicUrl, receivedData, conn, textView; 

/*
 */
- (void) viewDidLoad { 
  
	usernameView.text = username;
	((TwitterMessageView *) self.view).username = username;
	
	// Disable scroll.
	UIScrollView *sc = ((UIScrollView *)[[textView valueForKey:@"_internal"] valueForKey:@"scroller"]);		
	if([sc respondsToSelector:@selector(setIndicatorStyle:)] && [sc respondsToSelector:@selector(setScrollEnabled:)]) {
		sc.scrollEnabled = NO;
	}
	
	textView.backgroundColor = [UIColor clearColor];
  
  NSString *fn = [[NSBundle mainBundle] pathForResource:@"twitter_message" ofType:@"html"]; 
  NSString *c  = [NSString stringWithContentsOfFile:fn encoding:NSUTF8StringEncoding error:nil];
	NSString *fmt = [NSString stringWithFormat:c, message];
	
  [textView loadHTMLString:fmt baseURL:[NSURL URLWithString:@"/"]];
  textView.delegate = (TwitterMessageView *) self.view;
  imageView.layer.cornerRadius = 5.0;
  
  [self loadImageAtUrl:profilePicUrl];
}

/*
 */
- (void) loadImageAtUrl:(NSString *)url {
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
	self.conn = [NSURLConnection connectionWithRequest:request delegate:self];
	
	if(conn) {
		self.receivedData = [NSMutableData data];
	}
}


#pragma mark - 
#pragma mark URLConnection delegate

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response {
	
	[receivedData setLength:0]; 
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {
	
	[receivedData appendData:data];
}

/*
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)_conn {
  
	UIImage *img = [UIImage imageWithData:receivedData];
	imageView.image = img;
	self.receivedData = [NSMutableData data];
}

/*
 */
- (void) dealloc {
	
	[receivedData release];
	[conn release];
	[imageView release];
	[profilePicUrl release];
	[username release];
	[message release];
	[textView release];
	[super dealloc];
}

@end
