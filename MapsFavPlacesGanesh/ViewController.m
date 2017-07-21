//
//  ViewController.m
//  MapsFavPlacesGanesh
//
//  Created by Tarun Sharma on 19/07/17.
//  Copyright © 2017 Chetaru Web LInk Private Limited. All rights reserved.
//

#import "ViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import <GooglePlaces/GooglePlaces.h>
@interface ViewController ()<GMSMapViewDelegate,GMSAutocompleteViewControllerDelegate>
{
    GMSMarker *marker;
    GMSMapView *mapView;
    GMSCameraPosition *camera;
    
    
}
@end

@implementation ViewController

#pragma mark ViewMethods

- (void)loadView {
    
        camera = [GMSCameraPosition cameraWithTarget:CLLocationCoordinate2DMake(0, 0) zoom: 6];
    mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    mapView.myLocationEnabled = YES;
    mapView.delegate=self;
    self.view = mapView;
    
    
    marker = [[GMSMarker alloc] init];
    
    [mapView addObserver:self forKeyPath:@"myLocation" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
   
   
    
    
    [self createDBIfNotExist];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"myLocation"]) {
        // Animate map to current location (This will run every time user location updates!
        [mapView animateToLocation: mapView.myLocation.coordinate];
        // You can remove self from observing 'myLocation' to only animate once
        marker.position = mapView.myLocation.coordinate;
        
        marker.map = mapView;
        _location1=mapView.myLocation.coordinate;
        [mapView removeObserver:self forKeyPath:@"myLocation"];
    }
}

#pragma mark SQLITE Methods

-(void)createDBIfNotExist
{
    NSString *docsDir;
    NSArray *dirPaths;
    
    
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    
    NSLog(@"dirPaths is %@",dirPaths);
    
    docsDir = [dirPaths objectAtIndex:0];
    
    NSLog(@"docsDir is %@",docsDir);
    _databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent: @"favourites.db"]];
    
    NSLog(@"database path-->%@",_databasePath);
    NSFileManager * filemgr = [NSFileManager defaultManager];
    
    if ([filemgr fileExistsAtPath: _databasePath ] == NO)
    {
        const char *dbpath = [_databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
        {
            char *errMsg;
            const char *sql_stmt = "CREATE TABLE IF NOT EXISTS favourites (ID INTEGER PRIMARY KEY AUTOINCREMENT, LATITUDE DOUBLE, LONGITUDE DOUBLE)";
            
            if (sqlite3_exec(_contactDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
            {
                
                NSLog(@"Failed to create table");
            }
            
            sqlite3_close(_contactDB);
            
        } else {
            NSLog(@"Failed to open/create database");
            
        }    }
    
}
- (void) saveFavouritesInSQLite
{
    sqlite3_stmt    *statement;
    
    const char *dbpath = [_databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        NSString *insertSQL = [NSString stringWithFormat: @"INSERT INTO favourites (latitude,longitude) VALUES (\"%f\", \"%f\")", _location1.latitude, _location1.longitude];
        
        const char *insert_stmt = [insertSQL UTF8String];
        
        sqlite3_prepare_v2(_contactDB, insert_stmt, -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"Longitude and Latitude Added");

            UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"Success" message:@"Added To Favourites!" preferredStyle:UIAlertControllerStyleAlert];
            
            
            UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"Ok, thanks"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 [self getAllRecordsFromDB];
                                                             }];
            
            
            [alert addAction:noButton];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });
        } else {
            NSLog(@"Failed to Add Longitude and Latitude");
            
        }
        sqlite3_finalize(statement);
        sqlite3_close(_contactDB);
    }
}

- (void) getAllRecordsFromDB
{
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat: @"SELECT * from favourites"];
        
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_contactDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                NSLog(@"columns count is %i",sqlite3_data_count(statement));
                
                NSString *idField = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                
                double latField = sqlite3_column_double(statement, 1);
                double longField = sqlite3_column_double(statement, 2);

               
                
                GMSMarker *multipleMarker = [[GMSMarker alloc] init];
                
                _location.latitude = latField;
                _location.longitude = longField;
               
                multipleMarker.position = CLLocationCoordinate2DMake(_location.latitude, _location.longitude);
                multipleMarker.icon=[UIImage imageNamed:@"FavouritePin"];

                multipleMarker.appearAnimation = kGMSMarkerAnimationPop;
                multipleMarker.map = mapView;
                
                
                NSLog(@"record is ID:%@ Latitude: %f Longitude: %f ",idField,latField,longField);
                
            }
            
            
            sqlite3_finalize(statement);
        }
        sqlite3_close(_contactDB);
       
    }

}

- (void)findFavouritesInSQLite
{
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat: @"SELECT latitude, longitude FROM favourites WHERE latitude=\"%f\" AND longitude=\"%f\"", _location1.latitude,_location1.longitude];
        
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_contactDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                NSString * latitude = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                NSLog(@"Match Found With Latitude is %@",latitude);
                
                
                NSString *longitute = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
                 NSLog(@"Match Found With Longitute is %@",longitute);
                NSLog(@"Match found");
               
                
                [self alertWithTitle:@"Notice" message:@"Location Already added as Favourite!" actionTitle:@"Ok, thanks" actionStyle:UIAlertActionStyleCancel];
                
                
            } else {
                 NSLog(@"Match Not found");
                [self saveFavouritesInSQLite];
                
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_contactDB);
    }
    
}

#pragma mark GMSMapView Delegates

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    NSLog(@"Tap at (%g,%g)", coordinate.latitude, coordinate.longitude);
    marker.position = coordinate;
    _location1=coordinate;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [((GMSMapView*)self.view) setSelectedMarker:marker];
    }];
}


#pragma mark GMSAutocompleteViewController Delegates

- (void)viewController:(GMSAutocompleteViewController *)viewController
didAutocompleteWithPlace:(GMSPlace *)place {
    
    NSLog(@"place Coordinates Lat %f, Long %f",place.coordinate.latitude,place.coordinate.longitude);
    NSLog(@"Place name %@", place.name);
    NSLog(@"Place address %@", place.formattedAddress);
    NSLog(@"Place attributions %@", place.attributions.string);
    [self dismissViewControllerAnimated:YES completion:^{
        
        marker.position = place.coordinate;
        _location1=place.coordinate;

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            camera = [GMSCameraPosition cameraWithLatitude:place.coordinate.latitude
                                                 longitude:place.coordinate.longitude
                                                      zoom:6];
            [mapView animateToCameraPosition:camera];
            [((GMSMapView*)self.view) setSelectedMarker:marker];
        }];
    }];
}

- (void)viewController:(GMSAutocompleteViewController *)viewController
didFailAutocompleteWithError:(NSError *)error {
    NSLog(@"error: %ld", [error code]);
    NSLog(@"error Name : %@", error );
    [self dismissViewControllerAnimated:YES completion:nil];
}

// User canceled the operation.
- (void)wasCancelled:(GMSAutocompleteViewController *)viewController {
    NSLog(@"Autocomplete was cancelled.");
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark SearchButtonClick
- (IBAction)searchButtonClick:(id)sender {
    GMSAutocompleteViewController *acController = [[GMSAutocompleteViewController alloc] init];
    acController.delegate = self;
    [self presentViewController:acController animated:YES completion:nil];
}


#pragma mark AddToFavouriteButtonClick

- (IBAction)addToFavouriteButtonClick:(id)sender {
    
    [self findFavouritesInSQLite];
}


#pragma mark ShowFavouriteButtonClick

- (IBAction)showFavouritesButtonClick:(id)sender {
    
    [self getAllRecordsFromDB];
}


#pragma mark Alert

-(void)alertWithTitle:(NSString *)titleName message:(NSString *)messageName actionTitle:(NSString *)actionName actionStyle:(UIAlertActionStyle)actionStyleName{
    
    UIAlertController *alertCont = [UIAlertController alertControllerWithTitle:titleName message:messageName preferredStyle:UIAlertControllerStyleAlert];
    
    
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:actionName style:actionStyleName handler:nil];
    [alertCont addAction:okAction];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertCont animated:true completion:nil];
    });
    
}
@end
