//
//  MainViewController.h
//  AudioInfo
//
//  Created by Rinat Abdrashitov on 12-05-10.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "ASIHTTPRequest.h"
#import "LyricsView.h"
#import "CoverArtView.h"

@interface MainViewController : UIViewController <AVAudioPlayerDelegate, MPMediaPickerControllerDelegate, ASIHTTPRequestDelegate> {
    UIScrollView* mainScrollView_;
    UIButton* songChooseButton_;
    UILabel* title_;
    UILabel* albumTitle_;
    UILabel* artistTitle_;
    UILabel* genre_;
    UILabel* duration_;
    UILabel* numberOfChannels_;
    UILabel* sampleRate_;
    UILabel* waveFormLabel;
    UILabel* coverArtLabel_;
    UIImageView* coverArtView_;
    UILabel* lyricsLabel_;
    UILabel* audioPLayerLabel_;
    LyricsView* lyricsView_;
    CoverArtView* amazonCovertArt_;
    AVAudioPlayer* avplayer_;

    UIProgressView* audioLevel_;
    
    UIView* audioPlayerView_;
    UIButton* playButton_;
    UISlider* seekSlider_;
    UISlider* speedSlider_;
    UISlider* volumeSlider_;
    UISlider* panSlider_;
    UIActivityIndicatorView* convertingAudioSpinner_;
    
    UIImageView* waveform_;
    UIActivityIndicatorView* waveformSpinner_;
    UIScrollView* waveformScrollView_;
        
}

@end
