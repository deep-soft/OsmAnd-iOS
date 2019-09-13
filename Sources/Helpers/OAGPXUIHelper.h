//
//  OAGPXUIHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 9/12/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAGPXDocument;
@class OARouteCalculationResult;

@interface OAGPXUIHelper : NSObject

+ (OAGPXDocument *) makeGpxFromRoute:(OARouteCalculationResult *)route;

@end

