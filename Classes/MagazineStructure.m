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
#import "MagazineStructure.h"

/*
*/
@implementation Chapter

@synthesize title, twitterCat, twitterKeywords, pages;

- (void) dealloc {
  [title release];
  [pages release];
  [twitterCat release];
  [twitterKeywords release];
  [super dealloc];
}

@end

/*
*/
@implementation Page

@synthesize title, image, overlay, chapterIdx;

- (void) dealloc { 
  [title release];
  [image release];
  [overlay release];
  [super dealloc];
}

@end

/*
An overlay is a ViewController that is overlayed over a content page.
*/
@implementation Overlay

@synthesize xPos, yPos, overlayType, items;

- (void) dealloc { 
  [overlayType release];
  [super dealloc];
}

@end

/*
*/
@implementation ContentItem

@synthesize type, item, title;

- (void) dealloc {
	[item release];
	[title release];
	
	[super dealloc];
}

@end

/*
*/
static MagazineStructure *sharedInstance = nil;

@implementation MagazineStructure

@synthesize doc, chapters, allPages, selectedPage;

+ (id)allocWithZone:(NSZone *)zone {
	
	@synchronized(self) {
		if (sharedInstance == nil) {
			sharedInstance = [super allocWithZone:zone];
			return sharedInstance;  // assignment and return on first allocation
		}
	}
	
	return nil;
}

/*
 */
+ (MagazineStructure *)sharedInstance {
	
	return sharedInstance;
}

/*
 */
+ (MagazineStructure *) magazineStructureWithXML:(NSString *)xml {
	
	@synchronized(self) {
		if (sharedInstance == nil) {
			sharedInstance = [[MagazineStructure alloc] initMagazineStructureWithXML:xml];
		}
	}
	return sharedInstance;
}

/*
 */
- (id) initMagazineStructureWithXML:(NSString *)xml {
	
	self = [super init];
	
	if(self) { 
		
		NSError *err = nil;
		self.doc = [[[CXMLDocument alloc] initWithXMLString:xml options:0 error:&err] autorelease];

		if(err != nil) {
			NSLog(@"Error: %@", [err userInfo]);
			return nil;		
		}
		// Parse magazine.
		[self parseMagazine];
	}
	
	return self;
}

/*
Parses the main magazine structure.
 */
- (NSArray *) parseMagazine { 
	
	CXMLElement *rootEl = [doc rootElement];
	
	self.allPages = [NSMutableArray array];
	self.chapters = [NSMutableArray array];
	
	NSArray *chapterNodes = [rootEl nodesForXPath:@"//chapter" error:nil];
	
	for(int i = 0; i < chapterNodes.count; i++) {
		
    Chapter *chapter = [[Chapter new] autorelease];
		CXMLNode *chapterNode = [chapterNodes objectAtIndex:i];
		// Assign the values from the XML to the chapter
		chapter.title = [chapterNode nodeForXPath:@"title" error:nil].stringValue;
    
		// Keywords for Twitter. 
		CXMLElement *keywordNode = (CXMLElement *) [chapterNode nodeForXPath:@"keywords" error:nil];
		chapter.twitterKeywords = keywordNode.stringValue;
		chapter.twitterCat = [keywordNode attributeForName:@"twitterCat"].stringValue;
		
		// Get the chapter pages.
		NSArray *pageNodes = [chapterNode nodesForXPath:@"pages/page" error:nil];
		NSMutableArray *pages = [NSMutableArray array];
		
		for(CXMLNode *pageNode in pageNodes) {
			
      Page *page = [[Page new] autorelease];
      
      page.title = [pageNode nodeForXPath:@"title" error:nil].stringValue;
      page.image = [pageNode nodeForXPath:@"image" error:nil].stringValue;
      page.chapterIdx = i;
      
			CXMLElement *overlayNode = (CXMLElement *) [pageNode nodeForXPath:@"overlay" error:nil];
			
			// Overlay configured. parse it.
			if(overlayNode != nil) {
        page.overlay = [self parseOverlayProperties:overlayNode];
      }
			
			[pages addObject:page];
		}
		
		[allPages addObjectsFromArray:pages];
		
    chapter.pages = pages; 
		[chapters addObject:chapter];
	}
	
	// don't need it any longer
	
	self.doc = nil;
	
	return chapters;
}

/*
 Returns page after given page.
 */
- (Page *) pageAfter:(Page *)page {

  int pIdx = [allPages indexOfObject:page];
  
  if(pIdx + 1 < allPages.count) { 
    return [allPages objectAtIndex:pIdx + 1];
  }
  
  return nil;
}

/*
 Returns page before given page.
 */
- (Page *) pageBefore:(Page *)page {

  int pIdx = [allPages indexOfObject:page];
  
  if(pIdx - 1 >= 0) { 
    return [allPages objectAtIndex:pIdx - 1];
  }
  return nil;
}

/*
 */
- (Overlay *) parseOverlayProperties:(CXMLElement *)overlayNode {
	
  NSError *err = nil;
  
  Overlay *overlay = [[Overlay new] autorelease];  

  overlay.overlayType = [overlayNode attributeForName:@"type"].stringValue;	
	overlay.xPos = [[[overlayNode nodeForXPath:@"properties/xPos" error:&err] stringValue] doubleValue];
  overlay.yPos = [[[overlayNode nodeForXPath:@"properties/yPos" error:&err] stringValue] doubleValue];
	
	NSArray *itemNodes = [overlayNode nodesForXPath:@"items/item" error:&err];
	
	if(err != nil) {
		NSLog(@"Unable to parse overlay properties for %@", overlayNode);
		return nil; 
	}
	
	NSMutableArray *items = [NSMutableArray array];
	
	for(CXMLElement *itemNode in itemNodes) {
  
		ContentItem *item = [[ContentItem new] autorelease];
    item.type = kExtraContentItemTypeLink;
    
		item.item = itemNode.stringValue;
		item.title = [itemNode attributeForName:@"title"].stringValue;
		
		[items addObject:item];
	}
  overlay.items = items;
	return overlay;
}

#pragma mark -
#pragma mark ...

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)retain {
	return self;
}

- (unsigned)retainCount {
	return UINT_MAX;
}

- (void)release {
	//do nothing
}

- (id)autorelease {
	return self;
}

- (void) dealloc {
	
	[super dealloc];
	[doc release];
	[chapters release];
	[allPages release];
	[selectedPage release];
}

@end
