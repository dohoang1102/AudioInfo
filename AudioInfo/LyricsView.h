//
//  LyricsView.h
//  AudioInfo
//
//  Created by Rinat Abdrashitov on 12-05-25.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASIHTTPRequest.h"

@interface LyricsView : UIView <ASIHTTPRequestDelegate> {
    UITextView* lyricsView_;
}

- (void) getLyricsForArtist:(NSString*)artist song:(NSString*)song;


@end
