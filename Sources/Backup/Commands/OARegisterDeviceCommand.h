//
//  OARegisterDeviceCommand.h
//  OsmAnd Maps
//
//  Created by Paul on 25.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OARegisterDeviceCommand : NSOperation

- (instancetype) initWithToken:(NSString *)token;

@end

NS_ASSUME_NONNULL_END
