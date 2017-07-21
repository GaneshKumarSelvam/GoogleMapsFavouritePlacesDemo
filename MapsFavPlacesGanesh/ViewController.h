//
//  ViewController.h
//  MapsFavPlacesGanesh
//
//  Created by Tarun Sharma on 19/07/17.
//  Copyright © 2017 Chetaru Web LInk Private Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "sqlite3.h"

@interface ViewController : UIViewController

- (IBAction)searchButtonClick:(id)sender;
- (IBAction)addToFavouriteButtonClick:(id)sender;
- (IBAction)showFavouritesButtonClick:(id)sender;

@property CLLocationCoordinate2D location,location1;

@property  NSString *databasePath;
@property sqlite3 * contactDB;
@end

