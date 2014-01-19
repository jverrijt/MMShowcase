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

//
//
//
@implementation Chapter
@end

//
//
//
@implementation Page
@end

//
// An overlay is a ViewController that is overlayed over a content page.
//
@implementation Overlay
@end

//
//
//
@implementation ContentItem
@end

//
//
//
@implementation MagazineStructure

/**
 */
+ (MagazineStructure *) sharedInstance
{
    static MagazineStructure *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MagazineStructure alloc] init];

    });
    return sharedInstance;
}

/**
 */
- (NSError *) loadMagazineStructure:(NSString *)xml;
{
	NSError *err = nil;
    self.doc = [[CXMLDocument alloc] initWithXMLString:xml options:0 error:&err];
    
    if(err == nil) {
        [self parseMagazine];
    }
    return err;
}

/**
 Parse magazine structure.
 */
- (NSArray *) parseMagazine
{
	CXMLElement *rootEl = [_doc rootElement];
	
	self.allPages = [NSMutableArray array];
	self.chapters = [NSMutableArray array];
	
	NSArray *chapterNodes = [rootEl nodesForXPath:@"//chapter" error:nil];
	
	for(int i = 0; i < chapterNodes.count; i++) {
		
        Chapter *chapter = [Chapter new];
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
			
            Page *page = [Page new];
            
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
		
		[_allPages addObjectsFromArray:pages];
		
        chapter.pages = pages;
		[_chapters addObject:chapter];
	}
	
	// don't need it any longer
	
	self.doc = nil;
	
	return _chapters;
}

/*
 Returns page after given page.
 */
- (Page *) pageAfter:(Page *)page {
    
    int pIdx = [_allPages indexOfObject:page];
    
    if(pIdx + 1 < _allPages.count) {
        return [_allPages objectAtIndex:pIdx + 1];
    }
    
    return nil;
}

/*
 Returns page before given page.
 */
- (Page *) pageBefore:(Page *)page
{
    int pIdx = [_allPages indexOfObject:page];
    
    if(pIdx - 1 >= 0) {
        return [_allPages objectAtIndex:pIdx - 1];
    }
    return nil;
}

/*
 */
- (Overlay *) parseOverlayProperties:(CXMLElement *)overlayNode
{
    NSError *err = nil;
    
    Overlay *overlay = [Overlay new];
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
		ContentItem *item = [ContentItem new];
        item.type = kExtraContentItemTypeLink;
        
		item.item = itemNode.stringValue;
		item.title = [itemNode attributeForName:@"title"].stringValue;
		
		[items addObject:item];
	}
    overlay.items = items;
	return overlay;
}

@end
