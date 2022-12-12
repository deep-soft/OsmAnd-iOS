//
//  OAUtilities.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 6/5/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OANativeUtilities.h"

#import <UIKit/UIKit.h>
#import "OAUtilities.h"

#include <QString>

#include <SkCGUtils.h>
#include <SkCanvas.h>
#include <OsmAndCore/SkiaUtilities.h>

@implementation UIColor (nsColorNative)

- (OsmAnd::FColorARGB) toFColorARGB
{
    CGFloat red, green, blue, alpha;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    return OsmAnd::ColorARGB(alpha * 255, red * 255, green * 255, blue * 255);
}

@end

@implementation NSDate (nsDateNative)

- (std::tm) toTm
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:self];
    
    struct tm res;
    res.tm_year = (int) components.year - 1900;
    res.tm_mon = (int) components.month - 1;
    res.tm_mday = (int) components.day;
    res.tm_hour = (int) components.hour;
    res.tm_min = (int) components.minute;
    res.tm_sec = (int) components.second;
    std::mktime(&res);
    
    return res;
}

@end

@implementation OANativeUtilities

+ (sk_sp<SkImage>) skImageFromMmPngResource:(NSString *)resourceName
{
    resourceName = [OAUtilities drawablePath:[NSString stringWithFormat:@"mm_%@", resourceName]];
    
    const auto resourcePath = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"png"];
    if (resourcePath == nil)
        return nullptr;

    return [self.class skImageFromResourcePath:resourcePath];
}

+ (sk_sp<SkImage>) skImageFromPngResource:(NSString *)resourceName
{
    if ([UIScreen mainScreen].scale > 2.0f)
        resourceName = [resourceName stringByAppendingString:@"@3x"];
    else if ([UIScreen mainScreen].scale > 1.0f)
        resourceName = [resourceName stringByAppendingString:@"@2x"];

    const auto resourcePath = [[NSBundle mainBundle] pathForResource:resourceName
                                                              ofType:@"png"];
    if (resourcePath == nil)
        return nullptr;

    return [self.class skImageFromResourcePath:resourcePath];
}

+ (sk_sp<SkImage>) skImageFromResourcePath:(NSString *)resourcePath
{
    if (resourcePath == nil)
        return nullptr;
    
    NSData* resourceData = [NSData dataWithContentsOfFile:resourcePath];
    if (!resourceData)
        return nullptr;
    
    return [self.class skImageFromNSData:resourceData];
}

+ (sk_sp<SkImage>) skImageFromNSData:(const NSData *)data
{
    if (!data)
        return nullptr;
        
    CFDataRef dataRef = (CFDataRef)CFBridgingRetain(data);
    return SkImage::MakeFromEncoded(SkData::MakeWithProc(
             CFDataGetBytePtr(dataRef),
             CFDataGetLength(dataRef),
             [](const void* ptr, void* context) {
                 CFRelease(context);
             },
             (void *)dataRef
         ));
}

+ (sk_sp<SkImage>) getScaledSkImage:(sk_sp<SkImage>)skImage scaleFactor:(float)scaleFactor
{
    if (!qFuzzyCompare(scaleFactor, 1.0f) && skImage)
        skImage = OsmAnd::SkiaUtilities::scaleImage(skImage, scaleFactor, scaleFactor);
    return skImage;
}

+ (UIImage *) skImageToUIImage:(const sk_sp<SkImage> &)image
{
    if (!image)
        return nil;
    SkBitmap bmp;
    image->asLegacyBitmap(&bmp);
    CGImageRef img = SkCreateCGImageRef(bmp);
    UIImage *res = img != nil ? [[UIImage alloc] initWithCGImage:img] : nil;
    if (img)
        CGImageRelease(img);
    return res;
}

+ (NSArray<NSString *> *) QListOfStringsToNSArray:(const QList<QString> &)list
{
    NSMutableArray<NSString *> *array = [[NSMutableArray alloc] initWithCapacity:list.size()];
    for (const auto& item : list)
        [array addObject:item.toNSString()];

    return [NSArray arrayWithArray:array];
}

+ (Point31) convertFromPointI:(OsmAnd::PointI)input
{
    Point31 output;
    output.x = input.x;
    output.y = input.y;
    return output;
}

+ (OsmAnd::PointI) convertFromPoint31:(Point31)input
{
    OsmAnd::PointI output;
    output.x = input.x;
    output.y = input.y;
    return output;
}

+ (sk_sp<SkImage>) skImageFromCGImage:(CGImageRef)image
{
    return SkMakeImageFromCGImage(image);
}

+ (QHash<QString, QString>) dictionaryToQHash:(NSDictionary<NSString *, NSString*> *)dictionary
{
    QHash<QString, QString> res;
    if (dictionary != nil)
    {
        for (NSString *key in dictionary.allKeys)
            res.insert(QString::fromNSString(key), QString::fromNSString(dictionary[key]));
    }
    return res;
}

+ (QList<OsmAnd::TileId>)convertToQListTileIds:(NSArray<NSArray<NSNumber *> *> *)tileIds
{
    QList<OsmAnd::TileId> qTileIds;
    for (NSArray<NSNumber *> *tileId in tileIds)
    {
        OsmAnd::TileId qTileId = OsmAnd::TileId::fromXY([tileId.firstObject intValue], [tileId.lastObject intValue]);
        qTileIds.append(qTileId);
    }
    return qTileIds;
}

@end
