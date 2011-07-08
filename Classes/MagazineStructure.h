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
#import "Const.h"
#import "TouchXML.h"

/*
*/
@interface Chapter : NSObject {}

@property (retain) NSString *title;
@property (retain) NSString *twitterCat;
@property (retain) NSString *twitterKeywords;
@property (retain) NSArray *pages;

@end

/*
 */
@interface Overlay : NSObject {}

@property (retain) NSString *overlayType;
@property (retain) NSArray *items;
@property double xPos; 
@property double yPos;

@end

/*
*/
@interface Page : NSObject {}

@property (retain) NSString *title; 
@property (retain) NSString *image;
@property (retain) Overlay *overlay; 
@property int chapterIdx;

@end


// Different types for Contentitems.
typedef enum {
	kExtraContentItemTypeLink
} kExtraContentItemType;


/*
*/
@interface ContentItem : NSObject {}

@property kExtraContentItemType type;
@property (retain) NSString *item;
@property (retain) NSString *title;

@end

/*
*/
@interface MagazineStructure : NSObject {
	id sharedInstance;
}

@property (nonatomic, retain) CXMLDocument *doc;
@property (nonatomic, retain) NSMutableArray *chapters;
@property (nonatomic, retain) NSMutableArray *allPages;
@property (nonatomic, retain) Page *selectedPage;

+ (MagazineStructure *)sharedInstance;
+ (MagazineStructure *) magazineStructureWithXML:(NSString *)xml;

- (id) initMagazineStructureWithXML:(NSString *)xml;

- (Page *) pageAfter:(Page *)page;
- (Page *) pageBefore:(Page *)page;

- (NSArray *) parseMagazine;
- (Overlay *) parseOverlayProperties:(CXMLElement *)overlayNode;

@end
