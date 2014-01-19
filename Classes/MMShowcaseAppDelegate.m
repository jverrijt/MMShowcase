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
#import "MMShowcaseAppDelegate.h"
#import "MagazineStructure.h"

@implementation MMShowcaseAppDelegate

#pragma mark -
#pragma mark Application lifecycle

/**
 */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	NSString *magazineXml = [[NSBundle mainBundle].resourcePath stringByAppendingString:@"/magazine.xml"];
	NSString *xml  = [NSString stringWithContentsOfFile:magazineXml encoding:NSUTF8StringEncoding error:nil];
	
	MagazineStructure *magazine = [MagazineStructure sharedInstance];
    
    NSError *err = [magazine loadMagazineStructure:xml];
    
    if(err == nil) {
        NSLog(@"Magazine initialized with %d chapters and %d pages.", magazine.chapters.count, magazine.allPages.count);
        _viewController.pages = magazine.allPages;
        
        [self.window addSubview:_viewController.view];
        [self.window makeKeyAndVisible];
    } else {
        NSLog(@"Error loading magazine: %@", [err localizedDescription]);
    }
	return YES;
}

/*
 */


@end
