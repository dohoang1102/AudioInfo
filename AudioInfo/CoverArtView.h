//
//  CoverArtView.h
//  AudioInfo
//
//  Created by Rinat Abdrashitov on 12-05-25.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASIHTTPRequest.h"

@interface CoverArtView : UIView <ASIHTTPRequestDelegate> {
    UIImageView* imageView_;

}
- (void) getCoverArtForArtist:(NSString*)artist album:(NSString*)album;
@end
