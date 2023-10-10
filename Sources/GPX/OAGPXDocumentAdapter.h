//
//  OAGPXDocumentAdapter.h
//  OsmAnd
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@class OAGPXTrackAnalysis;
@class OASplitMetric, QuadRect, OAApplicationMode;


@interface OAGPXDocumentAdapter : NSObject

@property (nonatomic) id object;
@property (nonatomic) NSString *path;

- (OAGPXTrackAnalysis *) getAnalysis:(long)fileTimestamp;
- (BOOL) hasAltitude;
- (int) pointsCount;
- (NSString *) getMetadataValueBy:(NSString *)tag;

@end
