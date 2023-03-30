//
//  OASearchHistorySettingsItem.h
//  OsmAnd Maps
//
//  Created by Paul on 06.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACollectionSettingsItem.h"

NS_ASSUME_NONNULL_BEGIN

@class OAHistoryItem;

@interface OASearchHistorySettingsItem : OACollectionSettingsItem<OAHistoryItem *>

- (instancetype) initWithItems:(NSArray<OAHistoryItem *> *)items fromNavigation:(BOOL)fromNavigation;
- (instancetype _Nullable) initWithJson:(id)json error:(NSError * _Nullable *)error fromNavigation:(BOOL)fromNavigation;

@end

NS_ASSUME_NONNULL_END
