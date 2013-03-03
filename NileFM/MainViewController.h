//
//  MainViewController.h
//  NileFM
//
//  Created by Hesham Abd-Elmegid on 5/7/12.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MHRotaryKnob.h"

@interface MainViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

- (IBAction)powerButtonTapped:(id)sender;

@property (nonatomic, strong) IBOutlet MHRotaryKnob* rotaryKnob;
@property (nonatomic, strong) MPMoviePlayerController *player;
@property (nonatomic, assign) BOOL isPlaying;

@end
