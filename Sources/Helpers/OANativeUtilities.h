//
//  OAUtilities.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 6/5/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#include <OsmAndCore/stdlib_common.h>
#include <memory>
#include <ctime>

#include <OsmAndCore/QtExtensions.h>
#include <QList>

#include <SkImage.h>

#include <OsmAndCore/Color.h>

#include <OsmAndCore/CommonTypes.h>

#import <Foundation/Foundation.h>

#import "OACommonTypes.h"

@interface UIColor (nsColorNative)

- (OsmAnd::FColorARGB) toFColorARGB;

@end

@interface NSDate (nsDateNative)

- (std::tm) toTm;

@end

@interface OANativeUtilities : NSObject

+ (sk_sp<SkImage>) skImageFromMmPngResource:(NSString *)resourceName;
+ (sk_sp<SkImage>) skImageFromPngResource:(NSString *)resourceName;
+ (sk_sp<SkImage>) skImageFromResourcePath:(NSString *)resourcePath;
+ (sk_sp<SkImage>) skImageFromNSData:(const NSData *)data;
+ (sk_sp<SkImage>) getScaledSkImage:(sk_sp<SkImage>)skImage scaleFactor:(float)scaleFactor;

+ (NSArray<NSString *> *) QListOfStringsToNSArray:(const QList<QString> &)list;
+ (Point31) convertFromPointI:(OsmAnd::PointI)input;
+ (OsmAnd::PointI) convertFromPoint31:(Point31)input;
+ (sk_sp<SkImage>) skImageFromCGImage:(CGImageRef) image;
+ (UIImage *) skImageToUIImage:(const sk_sp<SkImage> &)image;

+ (QHash<QString, QString>) dictionaryToQHash:(NSDictionary<NSString *, NSString*> *)dictionary;

+ (QList<OsmAnd::TileId>)convertToQListTileIds:(NSArray<NSArray<NSNumber *> *> *)tileIds;

@end
