//
//  MainViewController.m
//  AudioInfo
//
//  Created by Rinat Abdrashitov on 12-05-10.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TFHpple.h"

#import "MainViewController.h"

@interface MainViewController()

- (NSData *) renderPNGAudioPictogramForAssett:(AVURLAsset *)songAsset;
- (UIImage *) audioImageGraph:(SInt16*)samples normalizeMax:(SInt16)normalizeMax sampleCount:(NSInteger)sampleCount 
              channelCount:(NSInteger)channelCount imageHeight:(float)imageHeight;
-(CGFloat) getBottomY: (UIView*) view;
-(void) createWaveForm:(AVURLAsset*) songAsset;
@end


@implementation MainViewController

- (id)init {
    self = [super init];
    if (self) {
        // Custom initialization
        self.view.backgroundColor = [UIColor whiteColor];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(lyricsReceived) 
                                                     name:@"LyricsReceived"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(lyricsFailed) 
                                                     name:@"LyricsFailed"
                                                   object:nil];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}



#pragma mark - View lifecycle

-(CGFloat) getBottomY: (UIView*) view {
    return view.frame.origin.y + view.frame.size.height;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    mainScrollView_ = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    mainScrollView_.backgroundColor = [UIColor clearColor];
    mainScrollView_.bounces = YES;
    [self.view addSubview:mainScrollView_];
    [mainScrollView_ release];
    
    songChooseButton_ = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [songChooseButton_ setTitle:@"Choose Song" forState:UIControlStateNormal];
    songChooseButton_.frame = CGRectMake(320/2 - 150/2, 20, 150, 40);
    [songChooseButton_ addTarget:self action:@selector(chooseSongClicked) forControlEvents:UIControlEventTouchUpInside];
    [mainScrollView_ addSubview:songChooseButton_];
    
    title_ = [[UILabel alloc] initWithFrame:CGRectMake(20, [self getBottomY:songChooseButton_] + 10,  280, 30)];
    title_.backgroundColor = [UIColor clearColor];
    [mainScrollView_ addSubview:title_];
    [title_ release];
    
    artistTitle_ = [[UILabel alloc] initWithFrame:CGRectMake(20, [self getBottomY:title_], 280, 30)];
    artistTitle_.backgroundColor = [UIColor clearColor];
    [mainScrollView_ addSubview:artistTitle_];
    [artistTitle_ release];
    
    albumTitle_ = [[UILabel alloc] initWithFrame:CGRectMake(20, [self getBottomY:artistTitle_], 280, 30)];
    albumTitle_.backgroundColor = [UIColor clearColor];
    [mainScrollView_ addSubview:albumTitle_];
    [albumTitle_ release];
    
    genre_ = [[UILabel alloc] initWithFrame:CGRectMake(20, [self getBottomY:albumTitle_], 280, 30)];
    genre_.backgroundColor = [UIColor clearColor];
    [mainScrollView_ addSubview:genre_];
    [genre_ release];
    
    duration_ = [[UILabel alloc] initWithFrame:CGRectMake(20, [self getBottomY:genre_], 280, 30)];
    duration_.backgroundColor = [UIColor clearColor];
    [mainScrollView_ addSubview:duration_];
    [duration_ release];
    
    numberOfChannels_ = [[UILabel alloc] initWithFrame:CGRectMake(20, [self getBottomY:duration_], 280, 30)];
    numberOfChannels_.backgroundColor = [UIColor clearColor];
    [mainScrollView_ addSubview:numberOfChannels_];
    [numberOfChannels_ release];
    
    sampleRate_ = [[UILabel alloc] initWithFrame:CGRectMake(20, [self getBottomY:numberOfChannels_], 280, 30)];
    sampleRate_.backgroundColor = [UIColor clearColor];
    [mainScrollView_ addSubview:sampleRate_];
    [sampleRate_ release];
    
    amazonCovertArt_ = [[CoverArtView alloc] initWithFrame:CGRectMake(320/2-250/2, [self getBottomY: sampleRate_] + 10, 250, 250)];
    [mainScrollView_ addSubview:amazonCovertArt_];
    [amazonCovertArt_ release];
      
    waveFormLabel = [[UILabel alloc] initWithFrame:CGRectMake(320/2 - 100/2, [self getBottomY:amazonCovertArt_] + 10, 100, 30)];
    waveFormLabel.backgroundColor = [UIColor clearColor];
    waveFormLabel.text = @"Wave form";
    waveFormLabel.hidden = YES;
    [mainScrollView_ addSubview:waveFormLabel];
    [waveFormLabel release];
        
    waveformScrollView_ = [[UIScrollView alloc] initWithFrame:CGRectMake(5, [self getBottomY:waveFormLabel] + 10, 310, 200)];
    waveformScrollView_.backgroundColor = [UIColor clearColor];
    [mainScrollView_ addSubview:waveformScrollView_];
    [waveformScrollView_ release];
    
    waveform_ = [[UIImageView alloc] init];
    [waveformScrollView_ addSubview:waveform_];
    [waveform_ release];    
    
    waveformSpinner_ = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    waveformSpinner_.frame = CGRectMake(320/2 - 15, waveformScrollView_.frame.origin.y + waveformScrollView_.frame.size.height/2 - 15, 30, 30);
    [mainScrollView_ addSubview:waveformSpinner_];
    [waveformSpinner_ release];
    
    lyricsLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(320/2 - 50/2, [self getBottomY:waveformScrollView_] + 10, 50, 30)];
    lyricsLabel_.backgroundColor = [UIColor clearColor];
    lyricsLabel_.text = @"Lyrics";
    lyricsLabel_.hidden = YES;
    [mainScrollView_ addSubview:lyricsLabel_];
    [lyricsLabel_ release];

    lyricsView_ = [[LyricsView alloc] initWithFrame:CGRectMake(5, [self getBottomY:lyricsLabel_] + 10, 310, 0)];
    [mainScrollView_ addSubview:lyricsView_];
    [lyricsView_ release];
        
    mainScrollView_.contentSize = CGSizeMake(320, [self getBottomY:lyricsView_] + 50);
        
}

//Called upon receiving LyricsReceived notification
-(void)lyricsReceived{
    mainScrollView_.contentSize = CGSizeMake(320, [self getBottomY:lyricsView_] + 50);
    lyricsLabel_.hidden = NO;    
}
-(void)lyricsFailed {
    mainScrollView_.contentSize = CGSizeMake(320, [self getBottomY:lyricsView_] + 50);
    lyricsLabel_.hidden = NO;
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        return NO;
    }
    if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        return NO;
    }
    return YES;
}

/*
 Selector for Choose Cong Button
 */
-(void) chooseSongClicked {
    MPMediaPickerController* picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    picker.prompt = @"Choose song to process";
    picker.delegate = self;
    [self presentModalViewController:picker animated:YES];
    [picker release];
}

#pragma mark - MPMediaPickerControllerDelegate Methods

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {

    [self dismissModalViewControllerAnimated:YES];
	if ([mediaItemCollection count] < 1) {
		return;
	}
	
	// Populate meatadata
    MPMediaItem* song = [[mediaItemCollection items] objectAtIndex:0];
    title_.text = [NSString stringWithFormat:@"Title: %@", [song valueForProperty:MPMediaItemPropertyTitle]];
	artistTitle_.text = [NSString stringWithFormat:@"Artist: %@", [song valueForProperty:MPMediaItemPropertyArtist]];
    albumTitle_.text = [NSString stringWithFormat:@"Album: %@", [song valueForProperty:MPMediaItemPropertyAlbumTitle]];
    genre_.text = [NSString stringWithFormat:@"Genre: %@", [song valueForProperty:MPMediaItemPropertyGenre]];
    duration_.text = [NSString stringWithFormat:@"Duration: %@ %@", [song valueForProperty:MPMediaItemPropertyPlaybackDuration], @"ms"];
    waveFormLabel.hidden = NO;
        
    UIImage* nativeimage = [[song valueForProperty:MPMediaItemPropertyArtwork] imageWithSize:  amazonCovertArt_.bounds.size];
    if (nativeimage == nil) {
        NSLog(@"Getting Cover for %@ %@", artistTitle_.text, albumTitle_.text);
        [amazonCovertArt_ getCoverArtForArtist:[song valueForProperty:MPMediaItemPropertyArtist] album:[song valueForProperty:MPMediaItemPropertyAlbumTitle]];
    } else {
        [amazonCovertArt_ setCoverArtImage:nativeimage];
    }

       
    // Create wave form
    waveform_.image = nil;
    NSURL *assetURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    AVAssetTrack * songTrack = [songAsset.tracks objectAtIndex:0];
    UInt32 sampleRate,channelCount;
    
    NSArray* formatDesc = songTrack.formatDescriptions;
    for(unsigned int i = 0; i < [formatDesc count]; ++i) {
        CMAudioFormatDescriptionRef item = (CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
        const AudioStreamBasicDescription* fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription (item);
        if(fmtDesc ) {
            sampleRate = fmtDesc->mSampleRate;
            channelCount = fmtDesc->mChannelsPerFrame;
            // NSLog(@"channels:%u, bytes/packet: %u, sampleRate %f",fmtDesc->mChannelsPerFrame, fmtDesc->mBytesPerPacket,fmtDesc->mSampleRate);
        }
    }
    
    numberOfChannels_.text = [NSString stringWithFormat:@"Number of Channels: %i", channelCount];
    sampleRate_.text = [NSString stringWithFormat:@"Sampling Rate: %i Hz", sampleRate];
    
    [waveformSpinner_ startAnimating];
    [self performSelectorInBackground:@selector(createWaveForm:) withObject:songAsset];

       
    //Get lyrics. Will update the lyricsView automatically.
    
    [lyricsView_ getLyricsForArtist:[song valueForProperty:MPMediaItemPropertyArtist] song:[song valueForProperty:MPMediaItemPropertyTitle]];
//    [lyricsView_ getLyricsForArtist:@"jay-z kanye west" song:@"gotta have it"];
    
    
    
}


- (void) mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - ASIHTTPRequest delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
    // Use when fetching text data
   
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    NSLog(@"ASI Error");
}

#pragma mark - Draw Waveform Methods

-(void) createWaveForm:(AVURLAsset*) songAsset {
    
    NSData* imageData = [self renderPNGAudioPictogramForAssett:songAsset];
    UIImage* wave = [UIImage imageWithData:imageData];
    waveform_.frame =  CGRectMake(0, 0, 310, 200);
    waveform_.image = wave;
    
    waveformScrollView_.contentSize = CGSizeMake(310, 200);
    [waveformSpinner_ stopAnimating];
}

- (NSData *) renderPNGAudioPictogramForAssett:(AVURLAsset *)songAsset {
    
    NSError * error = nil;
    
    
    AVAssetReader * reader = [[AVAssetReader alloc] initWithAsset:songAsset error:&error];
    
    AVAssetTrack * songTrack = [songAsset.tracks objectAtIndex:0];
    
    NSDictionary* outputSettingsDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        
                                        [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                                        //     [NSNumber numberWithInt:44100.0],AVSampleRateKey, /*Not Supported*/
                                        //     [NSNumber numberWithInt: 2],AVNumberOfChannelsKey,    /*Not Supported*/
                                        
                                        [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsNonInterleaved,
                                        
                                        nil];
    
    
    AVAssetReaderTrackOutput* output = [[AVAssetReaderTrackOutput alloc] initWithTrack:songTrack outputSettings:outputSettingsDict];
    
    [reader addOutput:output];
    [output release];
    
    UInt32 sampleRate,channelCount;
    
    NSArray* formatDesc = songTrack.formatDescriptions;
    for(unsigned int i = 0; i < [formatDesc count]; ++i) {
    CMAudioFormatDescriptionRef item = (CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
        const AudioStreamBasicDescription* fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription (item);
        if(fmtDesc ) {
            
            sampleRate = fmtDesc->mSampleRate;
            channelCount = fmtDesc->mChannelsPerFrame;
            
            //    NSLog(@"channels:%u, bytes/packet: %u, sampleRate %f",fmtDesc->mChannelsPerFrame, fmtDesc->mBytesPerPacket,fmtDesc->mSampleRate);
        }
    }
    
    
    UInt32 bytesPerSample = 2 * channelCount;
    SInt16 normalizeMax = 0;
    
    NSMutableData * fullSongData = [[NSMutableData alloc] init];
    [reader startReading];
    
    
    UInt64 totalBytes = 0; 
    
    
    SInt64 totalLeft = 0;
    SInt64 totalRight = 0;
    NSInteger sampleTally = 0;
    
    NSInteger samplesPerPixel = sampleRate / 50;
    
    
    while (reader.status == AVAssetReaderStatusReading){
        
        AVAssetReaderTrackOutput * trackOutput = (AVAssetReaderTrackOutput *)[reader.outputs objectAtIndex:0];
        CMSampleBufferRef sampleBufferRef = [trackOutput copyNextSampleBuffer];
        
        if (sampleBufferRef){
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);
            
            size_t length = CMBlockBufferGetDataLength(blockBufferRef);
            totalBytes += length;
            
            
            NSAutoreleasePool *wader = [[NSAutoreleasePool alloc] init];
            
            NSMutableData * data = [NSMutableData dataWithLength:length];
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, data.mutableBytes);
            
            
            SInt16 * samples = (SInt16 *) data.mutableBytes;
            int sampleCount = length / bytesPerSample;
            for (int i = 0; i < sampleCount ; i ++) {
                
                SInt16 left = *samples++;
                
                totalLeft  += left;
                
                
                
                SInt16 right;
                if (channelCount==2) {
                    right = *samples++;
                    
                    totalRight += right;
                }
                
                sampleTally++;
                
                if (sampleTally > samplesPerPixel) {
                    
                    left  = totalLeft / sampleTally; 
                    
                    SInt16 fix = abs(left);
                    if (fix > normalizeMax) {
                        normalizeMax = fix;
                    }
                    
                    
                    [fullSongData appendBytes:&left length:sizeof(left)];
                    
                    if (channelCount==2) {
                        right = totalRight / sampleTally; 
                        
                        
                        SInt16 fix = abs(right);
                        if (fix > normalizeMax) {
                            normalizeMax = fix;
                        }
                        
                        
                        [fullSongData appendBytes:&right length:sizeof(right)];
                    }
                    
                    totalLeft   = 0;
                    totalRight  = 0;
                    sampleTally = 0;
                    
                }
            }
            
            
            
            [wader drain];
            
            
            CMSampleBufferInvalidate(sampleBufferRef);
            
            CFRelease(sampleBufferRef);
        }
    }
    
    
    NSData * finalData = nil;
    
    if (reader.status == AVAssetReaderStatusFailed || reader.status == AVAssetReaderStatusUnknown){
        // Something went wrong. return nil
        
        return nil;
    }
    
    if (reader.status == AVAssetReaderStatusCompleted){
        
        NSLog(@"rendering output graphics using normalizeMax %d",normalizeMax);
        
        UIImage *test = [self audioImageGraph:(SInt16 *) 
                         fullSongData.bytes 
                                 normalizeMax:normalizeMax 
                                  sampleCount:fullSongData.length / 4 
                                 channelCount:2
                                  imageHeight:100];
        
        finalData = UIImagePNGRepresentation(test);
    }
    
    
    
    
    [fullSongData release];
    [reader release];
    
    return finalData;
}

-(UIImage *) audioImageGraph:(SInt16 *) samples
                normalizeMax:(SInt16) normalizeMax
                 sampleCount:(NSInteger) sampleCount 
                channelCount:(NSInteger) channelCount
                 imageHeight:(float) imageHeight {
    
    CGSize imageSize = CGSizeMake(sampleCount, imageHeight);
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetAlpha(context,1.0);
    CGRect rect;
    rect.size = imageSize;
    rect.origin.x = 0;
    rect.origin.y = 0;
    
    CGColorRef leftcolor = [[UIColor whiteColor] CGColor];
    CGColorRef rightcolor = [[UIColor redColor] CGColor];
    
    CGContextFillRect(context, rect);
    
    CGContextSetLineWidth(context, 1.0);
    
    float halfGraphHeight = (imageHeight / 2) / (float) channelCount ;
    float centerLeft = halfGraphHeight*2;
    float centerRight = (halfGraphHeight*3); 
    float sampleAdjustmentFactor = (imageHeight/ (float) channelCount) / (float) normalizeMax;
    
    for (NSInteger intSample = 0 ; intSample < sampleCount ; intSample ++ ) {
        SInt16 left = *samples++;
        float pixels = (float) left;
        pixels *= sampleAdjustmentFactor;
        CGContextMoveToPoint(context, intSample, centerLeft-pixels);
        CGContextAddLineToPoint(context, intSample, centerLeft+pixels);
        CGContextSetStrokeColorWithColor(context, leftcolor);
        CGContextStrokePath(context);
        
//        if (channelCount==2) {
//            SInt16 right = *samples++;
//            float pixels = (float) right;
//            pixels *= sampleAdjustmentFactor;
//            CGContextMoveToPoint(context, intSample, centerRight - pixels);
//            CGContextAddLineToPoint(context, intSample, centerRight + pixels);
//            CGContextSetStrokeColorWithColor(context, rightcolor);
//            CGContextStrokePath(context); 
//        }
    }
    
    // Create new image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Tidy up
    UIGraphicsEndImageContext();   
    
    return newImage;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc]; 

}




@end
