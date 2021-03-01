//
//  OASelectTrackFolderViewController.h
//  OsmAnd
//
//  Created by nnngrach on 05.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"
#import "OAGPXDatabase.h"

@protocol OASelectTrackFolderDelegate <NSObject>

- (void) updateSelectedFolder:(OAGPX *)gpx oldFilePath:(NSString *)oldFilePath newFilePath:(NSString *)newFilePath;     //TODO:nnngrach delete
- (void) onFolderSelected:(NSString *)selectedFolderName;
- (void) onNewFolderAdded;

@end

@interface OASelectTrackFolderViewController : OABaseTableViewController

@property (nonatomic, weak) id<OASelectTrackFolderDelegate> delegate;

- (instancetype) initWithGPX:(OAGPX *)gpx;
//- (instancetype) initWithGPX:(OAGPX *)gpx delegate:(id<OASelectTrackFolderDelegate>)delegate;     //TODO:nnngrach delete
//- (instancetype) initWithGPXFileName:(NSString *)fileName delegate:(id<OASelectTrackFolderDelegate>)delegate;     //TODO:nnngrach delete

@end
