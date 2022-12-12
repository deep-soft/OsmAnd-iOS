//
//  OAGlobalSettingsItem.m
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAGlobalSettingsItem.h"
#import "OAAppSettings.h"
#import "Localization.h"

@implementation OAGlobalSettingsItem

@dynamic type, name, fileName;

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeGlobal;
}

- (NSString *) name
{
    return @"general_settings";
}

- (NSString *)getPublicName
{
    return OALocalizedString(@"general_settings_2");
}

- (BOOL)exists
{
    return YES;
}

- (long)localModifiedTime
{
    return [OAAppSettings.sharedManager getLastGloblalSettingsModifiedTime];
}

- (void)setLocalModifiedTime:(long)localModifiedTime
{
    [OAAppSettings.sharedManager setLastGlobalModifiedTime:localModifiedTime];
}

- (long)getEstimatedSize
{
    return OAAppSettings.sharedManager.getGlobalPreferences.count * APPROXIMATE_PREFERENCE_SIZE_BYTES;
}

- (OASettingsItemReader *)getReader
{
    return [[OAGlobalSettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *)getWriter
{
    return self.getJsonWriter;
}

- (void) readPreferenceFromJson:(NSString *)key value:(NSString *)value
{
    if ([key isEqualToString:@"available_application_modes"])
    {
        NSMutableArray<NSString *> *appModesKeys = [[value componentsSeparatedByString:@","] mutableCopy];
        NSMutableArray<NSString *> *nonexistentAppModesKeys = [NSMutableArray new];
        for (NSString *appModeKey in appModesKeys)
        {
            if ([OAApplicationMode valueOfStringKey:appModeKey def: nil] == nil)
                [nonexistentAppModesKeys addObject:appModeKey];
        }
        if (nonexistentAppModesKeys.count != 0)
            [appModesKeys removeObjectsInArray:nonexistentAppModesKeys];

        value = [appModesKeys componentsJoinedByString:@","];
    }

    if ([[OAAppSettings sharedManager] getGlobalPreference:key].shared)
        [OAAppSettings.sharedManager setGlobalPreference:value key:key];
}

// MARK: OASettingsItemWriter

- (void)writeItemsToJson:(id)json
{
    NSMapTable<NSString *, OACommonPreference *> *globalPreferences = [OAAppSettings.sharedManager getPreferences:YES];
    for (NSString *key in globalPreferences.keyEnumerator)
    {
        OACommonPreference *setting = [globalPreferences objectForKey:key];
        if (setting.shared)
        {
            NSString *stringValue = [setting toStringValue:nil];
            if (stringValue)
                json[key] = stringValue;
        }
    }
}

@end

// MARK: OASettingsItemReader

#pragma mark - OAGlobalSettingsItemReader

@implementation OAGlobalSettingsItemReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    if (self.item.read)
    {
        if (error)
            *error = [NSError errorWithDomain:kSettingsItemErrorDomain code:kSettingsItemErrorCodeAlreadyRead userInfo:nil];

        return NO;
    }

    NSError *readError;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&readError];
    if (readError)
    {
        if (error)
            *error = readError;

        return NO;
    }
    if (data.length == 0)
    {
        if (error)
            *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeEmptyJson userInfo:nil];

        return NO;
    }

    NSError *jsonError;
    id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
    if (jsonError)
    {
        if (error)
            *error = jsonError;

        return NO;
    }

    NSDictionary<NSString *, NSString *> *settings = (NSDictionary *) json;

    [settings enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [self.item readPreferenceFromJson:key value:obj];
    }];

    self.item.read = YES;
    return YES;
}

@end
