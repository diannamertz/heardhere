//
//  Player.m
//  Heard Here
//
//  Created by Dianna Mertz on 11/16/12.
//  Copyright (c) 2012 Dianna Mertz. All rights reserved.
//

#import "PlayerViewController.h"
#import "AppDelegate.h"

@interface PlayerViewController ()
{
    UIButton *backButton;
    IBOutlet UIView *volumeView;
    IBOutlet UIButton *playPauseButton;
    IBOutlet UILabel *artistLabel;
    IBOutlet UILabel *titleLabel;
    BOOL _preferCoord;
    MPMediaItem *currentItem;
    NSMutableArray *animationCameras;
    NSDate *destinationDate;
}

@property (nonatomic, weak) IBOutlet MKMapView *map;
@property (nonatomic, strong) Song *songObject;
@property (nonatomic, strong) CLPlacemark *placemark;

@end

@implementation PlayerViewController

#pragma mark - View Controller

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    [self registerMediaPlayerNotifications];
    
    self.view.backgroundColor = [UIColor colorWithRed:128.0/255.0 green:128.0/255.0 blue:128.0/255.0 alpha:1.0];
    
    // Back Button
    UIImage *backImage = [UIImage imageNamed:@"player-back.png"];
    backButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,backImage.size.width*.5, backImage.size.height*.5) ];
    [backButton setImage:backImage forState:UIControlStateNormal];
    self.navigationItem.hidesBackButton = TRUE;
    UIBarButtonItem *barBackItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = barBackItem;
    [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchDown];
    
    // Custom UI
    artistLabel.textColor = [UIColor colorWithRed:1.0 green:0.9176 blue:0.5843 alpha:1.0];
    artistLabel.font = [UIFont fontWithName:@"Arial" size:16.0];
    
    titleLabel.textColor = [UIColor colorWithRed:1.0 green:0.9176 blue:0.5843 alpha:1.0];
    titleLabel.font = [UIFont fontWithName:@"Arial" size:16.0];
    
    // Volume View
    volumeView.backgroundColor = [UIColor clearColor];
    MPVolumeView *myVolumeView = [[MPVolumeView alloc] initWithFrame: volumeView.bounds];
    [volumeView addSubview:myVolumeView];
    
    [[self locationManager] startUpdatingLocation];
}

-(void)back {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];

    if ([self.musicPlayer playbackState] == MPMusicPlaybackStatePlaying) {
        [playPauseButton setImage:[UIImage imageNamed:@"ddplayer-button-pause.png"] forState:UIControlStateNormal];
    } else {
        [playPauseButton setImage:[UIImage imageNamed:@"ddplayer-button-play.png"] forState:UIControlStateNormal];
    }
    
    // Update now playing info
    currentItem = [self.musicPlayer nowPlayingItem];
    NSString *titleString = [[self.musicPlayer nowPlayingItem] valueForProperty:MPMediaItemPropertyTitle];
    if (titleString) {
        titleLabel.text = titleString;
    } else {
        titleLabel.text = @"Unknown Title";
    }
    
    NSString *artistString = [currentItem valueForProperty:MPMediaItemPropertyArtist];
    if (artistString) {
        artistLabel.text = artistString;
    } else {
        artistLabel.text = @"Unknown Artist";
    }
    
    if (self.previousController == YES) {
        [self showMap];
    } else if (self.previousController == NO) {
        [self showCurrentLocation];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification
                                                  object: self.musicPlayer];
    
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MPMusicPlayerControllerPlaybackStateDidChangeNotification
                                                  object: self.musicPlayer];
    
    [self.musicPlayer endGeneratingPlaybackNotifications];
    
    self.songObject = nil;
    backButton = nil;
    self.map = nil;
    //musicPlayer = nil;
}

#pragma mark - Register media player notifications

- (void)registerMediaPlayerNotifications
{
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver: self
                           selector: @selector (handle_PlaybackStateChanged:)
                               name: MPMusicPlayerControllerPlaybackStateDidChangeNotification
                             object: self.musicPlayer];
    
    [notificationCenter addObserver: self
                           selector: @selector (handle_NowPlayingItemChanged:)
                               name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification
                             object: self.musicPlayer];
    
    [self.musicPlayer beginGeneratingPlaybackNotifications];

}

- (void)handle_NowPlayingItemChanged:(id)notification
{
    if ([self.musicPlayer playbackState] != MPMusicPlaybackStateStopped) {
        
        [self grabDate];
        
        currentItem = [self.musicPlayer nowPlayingItem];
        
        NSString *titleString = [currentItem valueForProperty:MPMediaItemPropertyTitle];
        if (titleString) {
            titleLabel.text = titleString;
        } else {
            titleLabel.text = @"Unknown title";
        }
        
        NSString *artistString = [currentItem valueForProperty:MPMediaItemPropertyArtist];
        if (artistString) {
            artistLabel.text = artistString;
        } else {
            artistLabel.text = @"Unknown artist";
        }

        if (self.previousController == YES) {
            [self showMap];
        } else if (self.previousController == NO) {
            [self showCurrentLocation];
        }
        
        [self storeSong];
    }
}

- (void)handle_PlaybackStateChanged:(id)notification
{
    MPMusicPlaybackState playbackState = [self.musicPlayer playbackState];
    
    NSLog(@"playbackState: %ld", (long)playbackState);
    
    if (playbackState == MPMusicPlaybackStatePaused) {
        [playPauseButton setImage:[UIImage imageNamed:@"ddplayer-button-play.png"] forState:UIControlStateNormal];
    } else if (playbackState == MPMusicPlaybackStatePlaying) {
        [playPauseButton setImage:[UIImage imageNamed:@"ddplayer-button-pause.png"] forState:UIControlStateNormal];
    } else if (playbackState == MPMusicPlaybackStateInterrupted) {
        [playPauseButton setImage:[UIImage imageNamed:@"ddplayer-button-play.png"] forState:UIControlStateNormal];
        
    } else if (playbackState == MPMusicPlaybackStateStopped) {
        [playPauseButton setImage:[UIImage imageNamed:@"ddplayer-button-play.png"] forState:UIControlStateNormal];
    }
}

-(void)grabDate
{
    // Grab Date
    NSDate* sourceDate = [NSDate date];
    NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    destinationDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate];
}

-(void)storeSong
{
    currentItem = [self.musicPlayer nowPlayingItem];
    
    AppDelegate *myApp = (AppDelegate *) [[UIApplication sharedApplication]delegate];
    Song *songToSaveInDB = (Song *) [NSEntityDescription insertNewObjectForEntityForName:@"Song" inManagedObjectContext:myApp.managedObjectContext];
    
    // Grab Location
    CLLocation *location = [_locationManager location];
    if (!location) {
        return;
    }
    CLLocationCoordinate2D coordinate = [location coordinate];
    
    [self grabDate];
    
    // send to DB
    [songToSaveInDB setAlbum:[currentItem valueForProperty:MPMediaItemPropertyAlbumTitle]];
    [songToSaveInDB setArtist:[currentItem valueForProperty:MPMediaItemPropertyArtist]];
    [songToSaveInDB setGenre:[currentItem valueForProperty:MPMediaItemPropertyGenre]];
    [songToSaveInDB setTitle:[currentItem valueForProperty:MPMediaItemPropertyTitle]];
    [songToSaveInDB setLongitude:[NSNumber numberWithDouble:coordinate.longitude]];
    [songToSaveInDB setLatitude:[NSNumber numberWithDouble:coordinate.latitude]];
    [songToSaveInDB setListenDate:destinationDate];
    [songToSaveInDB setPersistentID:[currentItem valueForProperty:MPMediaItemPropertyPersistentID]];
    [songToSaveInDB.managedObjectContext save:nil];
}

#pragma mark - Controls

- (IBAction)playPause:(id)sender
{
    MPMusicPlaybackState playbackState = [self.musicPlayer playbackState];
    
    if (playbackState == MPMusicPlaybackStateStopped || playbackState == MPMusicPlaybackStatePaused || playbackState == MPMusicPlaybackStateInterrupted) {
        [playPauseButton setImage:[UIImage imageNamed:@"ddplayer-button-pause.png"] forState:UIControlStateNormal];
        [self.musicPlayer play];
        
    } else if (playbackState == MPMusicPlaybackStatePlaying) {
        [playPauseButton setImage:[UIImage imageNamed:@"ddplayer-button-play.png"] forState:UIControlStateNormal];
        [self.musicPlayer pause];
    }
}

- (IBAction)nextSong:(id)sender
{
    [self.musicPlayer skipToNextItem];
}

- (IBAction)previousSong:(id)sender
{
    [self.musicPlayer skipToPreviousItem];
}

#pragma Map

-(void)updateCameraProperties
{
    if ([self.map respondsToSelector:@selector(camera)]) {
        [self.map setShowsBuildings:YES];
        MKMapCamera *newCamera = [[self.map camera] copy];
        [newCamera setPitch:45.0];
        [newCamera setHeading:90.0];
        [newCamera setAltitude:500.0];
        
        [self.map setCamera:newCamera animated:YES];
    }
}

-(void)showMap
{
    if (self.map.annotations > 0) {
        [self.map removeAnnotations:self.map.annotations];
    }
    
    double lati = [[self.latitudeArray objectAtIndex:[self.musicPlayer indexOfNowPlayingItem]] doubleValue];
    double longi = [[self.longitudeArray objectAtIndex:[self.musicPlayer indexOfNowPlayingItem]] doubleValue];
    NSDate *dateOfPlay = [self.datesArray objectAtIndex:[self.musicPlayer indexOfNowPlayingItem]];
    
    CLLocationCoordinate2D coord = {.latitude = lati, .longitude = longi};
    MKCoordinateSpan span = {.latitudeDelta =  0.0005, .longitudeDelta =  0.0005};
    MKCoordinateRegion region = {coord, span};
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.title = @"You heard this on ";
    annotation.subtitle = [NSString stringWithFormat:@"%@", dateOfPlay];
    //annotation.subtitle = placemark.locality;
    annotation.coordinate = coord;
    [self.map addAnnotation:annotation];
    
    [self.map setRegion:region];
    
    [self updateCameraProperties];
}

- (void)showCurrentLocation {
    
    CLLocation *location = [_locationManager location];
    if (!location) {
        return;
    }
    CLLocationCoordinate2D coordinate = [location coordinate];
    
    MKCoordinateSpan span = {.latitudeDelta =  0.0005, .longitudeDelta =  0.0005};
    MKCoordinateRegion region = {coordinate, span};
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.title = @"You are hearing this on ";
    annotation.subtitle = [NSString stringWithFormat:@"%@", destinationDate];
    //annotation.subtitle = placemark.locality;
    annotation.coordinate = coordinate;
    [self.map addAnnotation:annotation];
    
    [self.map setRegion:region];
    [self updateCameraProperties];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *const identifier = @"MyCustomAnnotation";
    MKAnnotationView *annotationView = [self.map dequeueReusableAnnotationViewWithIdentifier:identifier];
    
    if (annotationView)
    {
        annotationView.annotation = annotation;
    }
    else
    {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
    }
    
    annotationView.image = [UIImage imageNamed:@"mappin.png"];
    annotationView.canShowCallout = YES;
    
    return annotationView;
}


// Saving location of played song

#pragma mark Location manager

- (CLLocationManager *)locationManager {
	
    if (_locationManager != nil) {
		return _locationManager;
	}
	
	_locationManager = [[CLLocationManager alloc] init];
	[_locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
	[_locationManager setDelegate:self];
	
	return _locationManager;
}

#pragma mark - MKAnnotation Protocol (for map pin)

- (CLLocationCoordinate2D)coordinate
{
    return self.placemark.location.coordinate;
}

- (NSString *)title
{
    return self.placemark.thoroughfare;
}

@end