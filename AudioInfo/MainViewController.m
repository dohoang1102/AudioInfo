//
//  MainViewController.m
//  AudioInfo
//
//  Created by Rinat Abdrashitov on 12-05-10.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TFHpple.h"

#import "MainViewController.h"

#define EXPORT_NAME @"exported.caf"
#define PAUSE 0
#define PLAY 1

@interface MainViewController()

- (NSData *) renderPNGAudioPictogramForAssett:(AVURLAsset *)songAsset;
- (UIImage *) audioImageGraph:(SInt16*)samples normalizeMax:(SInt16)normalizeMax sampleCount:(NSInteger)sampleCount 
              channelCount:(NSInteger)channelCount imageHeight:(float)imageHeight;
-(CGFloat) getBottomY: (UIView*) view;
-(void) createWaveForm:(AVURLAsset*) songAsset;
-(void) showAudioPlayer;
-(void) convertToCAF:(AVURLAsset*) songAsset;
@end


@implementation MainViewController

- (id)init {
    self = [super init];
    if (self) {
        // Custom initialization
        self.view.backgroundColor = [UIColor whiteColor];
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateLevel) userInfo:nil repeats:YES];

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
    
    //Set up audioplayer view
  
    
    audioPLayerLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(320/2 - 100/2, [self getBottomY:amazonCovertArt_] + 10, 100, 30)];
    audioPLayerLabel_.backgroundColor = [UIColor clearColor];
    audioPLayerLabel_.text = @"Audio Player";
    audioPLayerLabel_.hidden = YES;
    [mainScrollView_ addSubview:audioPLayerLabel_];
    [audioPLayerLabel_ release];
    
    audioPlayerView_ = [[UIView alloc] initWithFrame:CGRectMake(20, [self getBottomY:audioPLayerLabel_],280, 220)];
    audioPlayerView_.backgroundColor = [UIColor clearColor];
    convertingAudioSpinner_ = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    convertingAudioSpinner_.frame = CGRectMake(320/2 - 15, audioPlayerView_.frame.origin.y + audioPlayerView_.frame.size.height/2 - 15, 30, 30);
    [mainScrollView_ addSubview:convertingAudioSpinner_];
    [convertingAudioSpinner_ release];
    
    playButton_= [UIButton buttonWithType:UIButtonTypeCustom];
    playButton_.frame = CGRectMake(5, 25, 50, 50);
    playButton_.selected = NO;
    [playButton_ setImage:[UIImage imageNamed:@"play1-150x150.png"] forState:UIControlStateNormal];
    [playButton_ setImage:[UIImage imageNamed:@"pause1-150x150"] forState:UIControlStateSelected];
        [playButton_ setImage:[UIImage imageNamed:@"play1-150x150.png"] forState:UIControlStateHighlighted];
    [playButton_ addTarget:self action:@selector(playButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    playButton_.tag = PAUSE;
    [audioPlayerView_ addSubview:playButton_];
    
    UILabel* audioLevelLabel = [[UILabel alloc] initWithFrame:CGRectMake(65, 25, 220, 25)];
    audioLevelLabel.backgroundColor = [UIColor clearColor];
    audioLevelLabel.text = @"Level Meter";
    [audioPlayerView_ addSubview:audioLevelLabel];
    [audioLevelLabel release];
    
    audioLevel_ = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    audioLevel_.frame = CGRectMake(65, 25+30, 220, 30);
    [audioPlayerView_ addSubview:audioLevel_];
    [audioLevel_ release];
    
    UILabel* volumeSliderText = [[UILabel alloc] initWithFrame:CGRectMake(0, [self getBottomY:playButton_]+10, 80, 20)];
    volumeSliderText.backgroundColor = [UIColor clearColor];
    volumeSliderText.userInteractionEnabled = NO;
    volumeSliderText.text = @"Volume";
    [audioPlayerView_ addSubview:volumeSliderText];
    [volumeSliderText release];    
    volumeSlider_ = [[UISlider alloc] initWithFrame:CGRectMake(80, [self getBottomY:playButton_]+10, 280-80, 10)];
    [volumeSlider_ setMaximumValue:1.0f];
    [volumeSlider_ setMinimumValue:0.0f];
    [volumeSlider_ addTarget:self action:@selector(volumeChanged) forControlEvents:UIControlEventTouchDragInside];
    [audioPlayerView_ addSubview:volumeSlider_];
    [volumeSlider_ release];
    
    UILabel* speedSliderText = [[UILabel alloc] initWithFrame:CGRectMake(0, [self getBottomY:volumeSlider_]+10, 50, 20)];
    speedSliderText.backgroundColor = [UIColor clearColor];
    speedSliderText.userInteractionEnabled = NO;
    speedSliderText.text = @"Rate";
    [audioPlayerView_ addSubview:speedSliderText];
    [speedSliderText release]; 
    speedSlider_ = [[UISlider alloc] initWithFrame:CGRectMake(80, [self getBottomY:volumeSlider_]+10, 280-80-60, 10)];
    [speedSlider_ setMaximumValue:2.0f];
    [speedSlider_ setMinimumValue:0.5f];
    [speedSlider_ addTarget:self action:@selector(speedChanged) forControlEvents:UIControlEventTouchDragInside];
    [audioPlayerView_ addSubview:speedSlider_];
    [speedSlider_ release];
    UIButton* setToNormalRate = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    setToNormalRate.frame = CGRectMake(80+speedSlider_.frame.size.width+5, [self getBottomY:volumeSlider_]+10, 60, 20);
    [setToNormalRate setTitle:@"normal" forState:UIControlStateNormal];
    [setToNormalRate addTarget:self action:@selector(setToNormalRateClicked) forControlEvents:UIControlEventTouchUpInside];
    [audioPlayerView_ addSubview:setToNormalRate];
    
    
    UILabel* panSliderText = [[UILabel alloc] initWithFrame:CGRectMake(0, [self getBottomY:speedSlider_]+10, 200, 20)];
    panSliderText.backgroundColor = [UIColor clearColor];
    panSliderText.userInteractionEnabled = NO;
    panSliderText.text = @"Pan (need headphones)";
    [audioPlayerView_ addSubview:panSliderText];
    [panSliderText release]; 
    panSlider_ = [[UISlider alloc] initWithFrame:CGRectMake(80, [self getBottomY:panSliderText]+10, 280-80, 10)];
    [panSlider_ setMaximumValue:1.0f];
    [panSlider_ setMinimumValue:-1.0f];
    [panSlider_ addTarget:self action:@selector(panChanged) forControlEvents:UIControlEventTouchDragInside];
    [audioPlayerView_ addSubview:panSlider_];
    [panSlider_ release];
    
    
    [mainScrollView_ addSubview:audioPlayerView_];    
    [audioPlayerView_ release];
    
    
    waveFormLabel = [[UILabel alloc] initWithFrame:CGRectMake(320/2 - 100/2, [self getBottomY:audioPlayerView_] + 20, 100, 30)];
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


-(void)updateLevel{
    if (!audioPlayerView_.hidden) {
            
        [avplayer_ updateMeters];
        
        float power = [avplayer_ averagePowerForChannel:0];
        power = 100 + power;
        audioLevel_.progress = power/100;
        //power = -1*power;
        
    //    NSLog(@"%f", [avplayer_ averagePowerForChannel:0]);
    //    NSLog(@"%f", [avplayer_ peakPowerForChannel:0]);
    }
}

-(void) setToNormalRateClicked{

   
    avplayer_.rate = 1.0;
    speedSlider_.value = 1.0;
}

-(void)volumeChanged{
    avplayer_.volume = volumeSlider_.value;
}

-(void) panChanged{
    avplayer_.pan = panSlider_.value;
    
}
-(void) speedChanged{
    avplayer_.rate = speedSlider_.value;
}



-(void)playButtonClicked{
    if (playButton_.tag == PAUSE) {
        playButton_.selected = YES;
        playButton_.tag = PLAY;
        [avplayer_ play];
    } else {
        playButton_.selected = NO;
        playButton_.tag = PAUSE;
        [avplayer_ pause];
    }
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
    numberOfChannels_.text = @"Number Of Channels: Loading...";
    sampleRate_.text = @"Sampling Rate: Loading...";
    waveFormLabel.hidden = NO;
    audioPLayerLabel_.hidden = NO;
        
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
//    AVAssetTrack * songTrack = [songAsset.tracks objectAtIndex:0];
//    UInt32 sampleRate,channelCount;
    
//    NSArray* formatDesc = songTrack.formatDescriptions;
//    for(unsigned int i = 0; i < [formatDesc count]; ++i) {
//        CMAudioFormatDescriptionRef item = (CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
//        const AudioStreamBasicDescription* fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription (item);
//        if(fmtDesc ) {
//            sampleRate = fmtDesc->mSampleRate;
//            channelCount = fmtDesc->mChannelsPerFrame;
//            // NSLog(@"channels:%u, bytes/packet: %u, sampleRate %f",fmtDesc->mChannelsPerFrame, fmtDesc->mBytesPerPacket,fmtDesc->mSampleRate);
//        }
//    }
    
    //numberOfChannels_.text = [NSString stringWithFormat:@"Number of Channels: %i", channelCount];
    //sampleRate_.text = [NSString stringWithFormat:@"Sampling Rate: %i Hz", sampleRate];
    
    [waveformSpinner_ startAnimating];
    [convertingAudioSpinner_  startAnimating];
    [avplayer_ stop];
    audioPlayerView_.hidden = YES;
    playButton_.selected = NO;
    [self performSelectorInBackground:@selector(createWaveForm:) withObject:songAsset];
    [self performSelectorInBackground:@selector(convertToCAF:) withObject:songAsset];
    [self convertToCAF:songAsset];
       
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

-(void) convertToCAF:(AVURLAsset*) songAsset {
    NSError *assetError = nil;
	AVAssetReader *assetReader = [[AVAssetReader assetReaderWithAsset:songAsset
                                                                error:&assetError]
								  retain];
	if (assetError) {
		NSLog (@"error: %@", assetError);
		return;
	}
	
	AVAssetReaderOutput *assetReaderOutput = [[AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:songAsset.tracks
                                                                                                      audioSettings: nil] retain];
	if (! [assetReader canAddOutput: assetReaderOutput]) {
		NSLog (@"can't add reader output... die!");
		return;
	}
	[assetReader addOutput: assetReaderOutput];
	
	NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
	NSString *exportPath = [[documentsDirectoryPath stringByAppendingPathComponent:EXPORT_NAME] retain];
	if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath]) {
		[[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
	}
	NSURL *exportURL = [NSURL fileURLWithPath:exportPath];
	AVAssetWriter *assetWriter = [[AVAssetWriter assetWriterWithURL:exportURL
                                                           fileType:AVFileTypeCoreAudioFormat
                                                              error:&assetError]
								  retain];
	if (assetError) {
		NSLog (@"error: %@", assetError);
		return; 
	}
	AudioChannelLayout channelLayout;
	memset(&channelLayout, 0, sizeof(AudioChannelLayout));
	channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
	NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey, 
									[NSNumber numberWithFloat:44100.0], AVSampleRateKey,
									[NSNumber numberWithInt:2], AVNumberOfChannelsKey,
									[NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
									[NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
									[NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
									[NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
									[NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
									nil];
	AVAssetWriterInput *assetWriterInput = [[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                                               outputSettings:outputSettings]
											retain];
	if ([assetWriter canAddInput:assetWriterInput]) {
		[assetWriter addInput:assetWriterInput];
	} else {
		NSLog (@"can't add asset writer input... die!");
		return;
	}
	
	assetWriterInput.expectsMediaDataInRealTime = NO;
    
	[assetWriter startWriting];
	[assetReader startReading];
    
	AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
	CMTime startTime = CMTimeMake (0, soundTrack.naturalTimeScale);
	[assetWriter startSessionAtSourceTime: startTime];
	
	__block UInt64 convertedByteCount = 0;
	
	dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
	[assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue 
											usingBlock: ^ 
	 {
		 // NSLog (@"top of block");
		 while (assetWriterInput.readyForMoreMediaData) {
             CMSampleBufferRef nextBuffer = [assetReaderOutput copyNextSampleBuffer];
             if (nextBuffer) {
                 // append buffer
                 [assetWriterInput appendSampleBuffer: nextBuffer];
                 //				NSLog (@"appended a buffer (%d bytes)", 
                 //					   CMSampleBufferGetTotalSampleSize (nextBuffer));
                 convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
                 // oops, no
                 // sizeLabel.text = [NSString stringWithFormat: @"%ld bytes converted", convertedByteCount];
                 
                 NSNumber *convertedByteCountNumber = [NSNumber numberWithLong:convertedByteCount];
                 CFRelease(nextBuffer);
             } else {
                 // done!
                 [assetWriterInput markAsFinished];
                 [assetWriter finishWriting];
                 [assetReader cancelReading];
                 NSDictionary *outputFileAttributes = [[NSFileManager defaultManager]
                                                       attributesOfItemAtPath:exportPath
                                                       error:nil];
                 NSLog (@"done. file size is %ld", [outputFileAttributes fileSize]);
                 NSNumber *doneFileSize = [NSNumber numberWithLong:[outputFileAttributes fileSize]];
                 
                 [self performSelectorOnMainThread:@selector(showAudioPlayer) withObject:nil waitUntilDone:NO];
                                    
                 [assetReader release];
                 [assetReaderOutput release];
                 [assetWriter release];
                 [assetWriterInput release];
                 [exportPath release];
                 break;
             }
         }
         
	 }];
	NSLog (@"bottom of convertTapped:");
    
    
}
-(void) showAudioPlayer{
    if (avplayer_ !=nil) {
        [avplayer_ release];
    }
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
    NSString *exportPath = [[documentsDirectoryPath stringByAppendingPathComponent:EXPORT_NAME] retain];
    NSURL *url = [NSURL fileURLWithPath:exportPath];
    NSError *error;
    avplayer_ = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (error)
    {
        NSLog(@"Error in audioPlayer: %@", 
              [error localizedDescription]);
    } else {
        avplayer_.delegate = self;
        avplayer_.volume = 0.3;
        avplayer_.enableRate = YES;
        [avplayer_ setMeteringEnabled:YES];
        
        speedSlider_.value = 1.0;
        volumeSlider_.value = 0.3;
        panSlider_.value = 0.0;
        
        [avplayer_ prepareToPlay];
        NSLog(@"%@", [avplayer_.settings valueForKey:AVChannelLayoutKey]);
        NSLog(@"%@", [avplayer_.settings valueForKey:AVEncoderBitRateKey]);
        NSLog(@"%@", [avplayer_.settings valueForKey:AVFormatIDKey]);
        
        
        numberOfChannels_.text = [NSString stringWithFormat:@"Number Of Channels: %@", [avplayer_.settings valueForKey:AVNumberOfChannelsKey]];
        sampleRate_.text = [NSString stringWithFormat:@"Sampling Rate: %@ Hz" , [avplayer_.settings valueForKey:AVSampleRateKey]];
        NSLog(@"%@", [avplayer_.settings valueForKey:AVLinearPCMBitDepthKey]);
        NSLog(@"%@", [avplayer_.settings valueForKey:AVLinearPCMIsBigEndianKey]);
        
    }
    [convertingAudioSpinner_ stopAnimating];
    audioPlayerView_.hidden = NO;
    
}

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
  
       // NSURL *url = [NSURL fileURLWithPath:@"exported.caf"];


        NSError *error;
        AVAudioPlayer* avplayer = [[AVAudioPlayer alloc] initWithData:fullSongData error:&error];
        avplayer.delegate = self;
        avplayer.volume = 1.0;
        
        [avplayer prepareToPlay];
        [avplayer play];
        
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

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"Shit happened" );
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
