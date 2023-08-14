//
//  OACloudIntroductionHeaderView.h
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 17.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OACloudIntroductionHeaderView : UIView

- (void)setUpViewWithTitle:(NSString *)title description:(NSString *)description image:(UIImage *)image;
- (CGFloat)calculateViewHeight;

- (void)addAnimatedViews;

@end

NS_ASSUME_NONNULL_END
