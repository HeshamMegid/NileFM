//
//  MainViewController.m
//  NileFM
//
//  Created by Hesham Abd-Elmegid on 5/7/12.
//

#import "MainViewController.h"
#import "RNBlurModalView.h"
#import "OLGhostAlertView.h"
#import "Reachability.h"

#define kStreamURL @"http://64.62.214.140/NILEFM"
#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

@implementation MainViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Respond to reachability changes to play/stop stream accordingly.
    Reachability* reach = [Reachability reachabilityWithHostname:kStreamURL];
    reach.reachableBlock = ^(Reachability*reach) {
        [self playStream];
    };
    reach.unreachableBlock = ^(Reachability*reach) {
        [self stopStream];
    };
    [reach startNotifier];
    
    // Observe UIApplicationDelegate's applicationDidBecomeActive: to play stream when the app is resumed
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playStream)
                                                 name:@"DidBecomeActive"
                                               object:nil];
    
    // Observe volume changes through harware buttons and multitasking bar control
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(volumeChanged:)
                                                 name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                               object:nil];
    
    // Set NileFM as the title of the currently playing track in the info center
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{MPMediaItemPropertyTitle : @"NileFM"};
    
    //-----
    // UI
    //-----
    
    if (![self isFirstRun]) [self displayDisclaimer];
    
    UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed: IS_IPHONE_5 ? @"background-568" : @"background"]];
    [self.view addSubview:bg];
    [self.view sendSubviewToBack:bg];
    
    // MPVolumeView is used to provide our own way of controlling the volume. When it's used, the default overlay that appears when using
    // the hardware volume buttons don't appear.
    MPVolumeView *myVolumeView =[[MPVolumeView alloc] initWithFrame:CGRectZero];
    [myVolumeView setShowsVolumeSlider:YES];
    [self.view addSubview: myVolumeView];

    // MPMoviePlayerController will handle the actual stream playback
    self.player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:kStreamURL]];
    // Set the MPMoviePlayerController to use the audio session of the application to continue working when sent to the background
    [self.player setUseApplicationAudioSession:YES];
    self.player.movieSourceType = MPMovieSourceTypeStreaming;
    // We don't want the MPMoviePlayerController to display it's own UI so we are going to hide it
    [self.player.view setHidden:YES];
    [self.view addSubview:self.player.view];
    
    // Set up the volume knob
    self.rotaryKnob.interactionStyle = MHRotaryKnobInteractionStyleRotating;
	self.rotaryKnob.scalingFactor = 1.5f;
	self.rotaryKnob.maximumValue = 1.0f;
	self.rotaryKnob.minimumValue = 0.0f;
	self.rotaryKnob.value = [[MPMusicPlayerController applicationMusicPlayer] volume];
	self.rotaryKnob.defaultValue = self.rotaryKnob.value;
	self.rotaryKnob.resetsToDefault = YES;
    [self.rotaryKnob addTarget:self action:@selector(rotaryKnobDidChange) forControlEvents:UIControlEventValueChanged];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

#pragma mark -

- (BOOL)isFirstRun {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"FirstRun"] boolValue];
}

- (void)displayDisclaimer {
    RNBlurModalView *modal = [[RNBlurModalView alloc] initWithViewController:self title:@"Disclaimer" message:@"NileFM is a registered trademark of Nile Radio Productions. This is an unofficial app that is not affiliated with Nile Radio Productions in any way."];
    [modal show];
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"FirstRun"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Remote control events

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    if (event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
        if ([self.player playbackState] == MPMoviePlaybackStatePlaying) {
            [self.player pause];
        } else {
            [self playStream];
        }
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark - Player related methods

- (IBAction)powerButtonTapped:(id)sender {
    if ([self.player playbackState] != MPMoviePlaybackStatePlaying)
        [self playStream];
    else
        [self stopStream];
}

- (void)rotaryKnobDidChange {
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:self.rotaryKnob.value];
}

/*
 Volume changed through hardware buttons or multitasking bar controls
 */
- (void)volumeChanged:(NSNotification *)notification {
    float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
 	[self.rotaryKnob setValue:volume animated:YES];
}

- (void)playStream {
    if ([self.player playbackState] != MPMoviePlaybackStatePlaying) {
        UIImage *knobImage = [UIImage imageNamed:@"dial-knob"];
        [self.rotaryKnob setKnobImage:knobImage forState:UIControlStateNormal];
        [self.rotaryKnob setKnobImage:knobImage forState:UIControlStateHighlighted];
        
        [self.player play];
        
        OLGhostAlertView *ghastly = [[OLGhostAlertView alloc] initWithTitle:@"" message:@"Connecting..." timeout:2 dismissible:YES];
        [ghastly show];
    }
}

- (void)stopStream {
    UIImage *knobImage = [UIImage imageNamed:@"dial-knob-closed"];
    [self.rotaryKnob setKnobImage:knobImage forState:UIControlStateNormal];
    [self.rotaryKnob setKnobImage:knobImage forState:UIControlStateHighlighted];
    
    [self.player stop];
}

@end
