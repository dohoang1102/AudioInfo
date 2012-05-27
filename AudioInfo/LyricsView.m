//
//  LyricsView.m
//  AudioInfo
//
//  Created by Rinat Abdrashitov on 12-05-25.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LyricsView.h"

@implementation LyricsView

- (id)initWithFrame:(CGRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
  //      self.backgroundColor = [UIColor blueColor];
        lyricsView_ = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        lyricsView_.editable = NO;
//        lyricsView_.backgroundColor = [UIColor blueColor];
        lyricsView_.userInteractionEnabled = NO;
        [self addSubview:lyricsView_];
        [lyricsView_ release];                
    }
    return self;
}

- (void) getLyricsForArtist:(NSString*)artist song:(NSString*)song {

    lyricsView_.text = @"Searching for lyrics at songlyrics.com";
    CGRect frame = lyricsView_.frame;
    frame.size.height = lyricsView_.contentSize.height;
    lyricsView_.frame = frame;
    
    CGRect superviewframe = self.frame;
    superviewframe.size.height = lyricsView_.contentSize.height;
    self.frame = superviewframe;
    
    artist = [artist stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    song = [song stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    
    artist = [artist stringByReplacingOccurrencesOfString:@"," withString:@"-"];
    song = [song stringByReplacingOccurrencesOfString:@"," withString:@"-"];
    
    artist = [artist stringByReplacingOccurrencesOfString:@"'" withString:@"-"];
    song = [song stringByReplacingOccurrencesOfString:@"'" withString:@"-"];
    
    artist = [artist stringByReplacingOccurrencesOfString:@"&" withString:@"-"];
    song = [song stringByReplacingOccurrencesOfString:@"&" withString:@"-"];
    
    artist = [artist stringByReplacingOccurrencesOfString:@"ft." withString:@"-"];
    song = [song stringByReplacingOccurrencesOfString:@"ft." withString:@"-"];
   
    artist = [artist stringByReplacingOccurrencesOfString:@"Ft." withString:@"-"];
    song = [song stringByReplacingOccurrencesOfString:@"Ft." withString:@"-"];
        
    artist = [artist stringByReplacingOccurrencesOfString:@"`" withString:@"-"];
    song = [song stringByReplacingOccurrencesOfString:@"`" withString:@"-"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LyricsReceived"  object:self];
    //Replace whitespace with '-'
    artist = [artist stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    song = [song stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    NSString* urlstring = [NSString stringWithFormat:@"http://www.songlyrics.com/%@/%@-lyrics/", artist, song]; 
    NSLog(@"Lyrics URL:%@", urlstring);
    NSURL *url = [NSURL URLWithString:urlstring];
    
    //Send http request to fethc lyrics
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request startAsynchronous];
    
}


#pragma mark - ASIHTTPRequest delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
    // Use when fetching text data
    NSString *responseString = [request responseString];
    // NSLog(@"%@", responseString);
    
    NSString *lyrics = [[NSString alloc] init];
    NSString *lyrics2 = [[NSString alloc] init];
    NSScanner *scanner = [NSScanner scannerWithString:responseString]; 
    [scanner scanUpToString:@"<p id=\"songLyricsDiv\"" intoString:nil];
    //[scanner scanUpToString:@"&#" intoString:nil];
    [scanner scanUpToString:@"</div>" intoString:&lyrics]; 
    NSRange range = [lyrics rangeOfString:@"&#"];
       
    if (range.length !=0) {
        scanner = [NSScanner scannerWithString:lyrics];
        [scanner scanUpToString:@"&#" intoString:nil];
        [scanner scanUpToString:@"</p>" intoString:&lyrics2];
        NSLog(@"%@", lyrics2);
  
        lyrics2 = [lyrics2 stringByReplacingOccurrencesOfString:@"<br />" withString:@""];
        lyrics2 = [lyrics2 stringByReplacingOccurrencesOfString:@"&#" withString:@""];
        NSArray* allsentences = [lyrics2 componentsSeparatedByString:@"\n"];
        NSMutableString* FINAL_LYRICS = [[NSMutableString alloc] initWithCapacity:[lyrics2 length]];
        for (int i = 0; i < [allsentences count]; i++){
            NSString* sentence = [allsentences objectAtIndex:i];
            NSArray * allchars = [sentence componentsSeparatedByString:@";"];
            NSMutableString* actual_sentence = [[NSMutableString alloc] initWithCapacity:[sentence length]];
            for (int j = 0; j <[allchars count] - 1; j++) {
                NSString* char_str = [allchars objectAtIndex:j];
                char char_char = [char_str intValue];
                [actual_sentence appendFormat:@"%c", char_char];
            }
            //NSLog(@"%@",  actual_sentence);
            [FINAL_LYRICS appendFormat:@"%@\n", actual_sentence]; 
            [actual_sentence release];
        }
        NSLog(@"%@", FINAL_LYRICS);
        lyricsView_.text = FINAL_LYRICS;
        CGRect frame = lyricsView_.frame;
        frame.size.height = lyricsView_.contentSize.height;
        lyricsView_.frame = frame;
        
        CGRect superviewframe = self.frame;
        superviewframe.size.height = lyricsView_.contentSize.height;
        self.frame = superviewframe;

        [[NSNotificationCenter defaultCenter] postNotificationName:@"LyricsReceived"  object:self];
    } else {
        lyricsView_.text =  @"Sorry...Couldn't find lyrics.";
        CGRect frame = lyricsView_.frame;
        frame.size.height = lyricsView_.contentSize.height;
        lyricsView_.frame = frame;
        
        CGRect superviewframe = self.frame;
        superviewframe.size.height = lyricsView_.contentSize.height;
        self.frame = superviewframe;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LyricsFailed"  object:self];
        
    }
     
}



- (void)requestFailed:(ASIHTTPRequest *)request {
    NSError *error = [request error];
    NSLog(@"ASI Error");
    lyricsView_.text = @"Sorry...Couldn't find lyrics.";
    CGRect frame = lyricsView_.frame;
    frame.size.height = lyricsView_.contentSize.height;
    lyricsView_.frame = frame;
    CGRect superviewframe = self.frame;
    superviewframe.size.height = lyricsView_.contentSize.height;
    self.frame = superviewframe;
    [[NSNotificationCenter defaultCenter]  postNotificationName:@"LyricsFailed"  object:self];
    
}







@end