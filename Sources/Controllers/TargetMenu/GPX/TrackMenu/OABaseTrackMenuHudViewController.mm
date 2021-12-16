//
//  OABaseTrackMenuHudViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseTrackMenuHudViewController.h"
#import "OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapRendererView.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocument.h"
#import "OsmAndApp.h"
#import "OASavingTrackHelper.h"
#import "OAGPXTrackAnalysis.h"

#define VIEWPORT_SHIFTED_SCALE 1.5f
#define VIEWPORT_NON_SHIFTED_SCALE 1.0f

@implementation OAGPXTableCellData

+ (instancetype)withData:(NSDictionary *)data
{
    OAGPXTableCellData *cellData = [OAGPXTableCellData new];
    if (cellData)
    {
        [cellData setData:data];
    }
    return cellData;
}

- (void)setData:(NSDictionary *)data
{
    if ([data.allKeys containsObject:kCellKey])
        _key = data[kCellKey];
    if ([data.allKeys containsObject:kCellType])
        _type = data[kCellType];
    if ([data.allKeys containsObject:kTableValues])
        _values = data[kTableValues];
    if ([data.allKeys containsObject:kCellTitle])
        _title = data[kCellTitle];
    if ([data.allKeys containsObject:kCellDesc])
        _desc = data[kCellDesc];
    if ([data.allKeys containsObject:kCellLeftIcon])
        _leftIcon = data[kCellLeftIcon];
    if ([data.allKeys containsObject:kCellRightIconName])
        _rightIconName = data[kCellRightIconName];
    if ([data.allKeys containsObject:kCellToggle])
        _toggle = [data[kCellToggle] boolValue];
    if ([data.allKeys containsObject:kCellTintColor])
        _tintColor = [data[kCellTintColor] integerValue];
    if ([data.allKeys containsObject:kCellOnSwitch])
        _onSwitch = data[kCellOnSwitch];
    if ([data.allKeys containsObject:kCellIsOn])
        _isOn = data[kCellIsOn];
    if ([data.allKeys containsObject:kTableUpdateData])
        _updateData = data[kTableUpdateData];
    if ([data.allKeys containsObject:kCellButtonPressed])
        _onButtonPressed = data[kCellButtonPressed];
    if ([data.allKeys containsObject:kTableUpdateProperty])
        _updateProperty = data[kTableUpdateProperty];
}

@end

@implementation OAGPXTableSectionData

+ (instancetype)withData:(NSDictionary *)data
{
    OAGPXTableSectionData *sectionData = [OAGPXTableSectionData new];
    if (sectionData)
    {
        [sectionData setData:data];
    }
    return sectionData;
}

- (void)setData:(NSDictionary *)data
{
    if ([data.allKeys containsObject:kSectionCells])
        _cells = data[kSectionCells];
    if ([data.allKeys containsObject:kSectionHeader])
        _header = data[kSectionHeader];
    if ([data.allKeys containsObject:kSectionHeaderHeight])
        _headerHeight = [data[kSectionHeaderHeight] floatValue];
    if ([data.allKeys containsObject:kSectionFooter])
        _footer = data[kSectionFooter];
    if ([data.allKeys containsObject:kTableValues])
        _values = data[kTableValues];
    if ([data.allKeys containsObject:kTableUpdateData])
        _updateData = data[kTableUpdateData];
    if ([data.allKeys containsObject:kTableUpdateProperty])
        _updateProperty = data[kTableUpdateProperty];
}

- (BOOL)containsCell:(NSString *)key
{
    for (OAGPXTableCellData *cellData in self.cells)
    {
        if ([cellData.key isEqualToString:key])
            return YES;
    }
    return NO;
}

@end

@implementation OAGPXTableData

+ (instancetype)withData:(NSDictionary *)data
{
    OAGPXTableData *tableData = [OAGPXTableData new];
    if (tableData)
    {
        [tableData setData:data];
    }
    return tableData;
}

- (void)setData:(NSDictionary *)data
{
    if ([data.allKeys containsObject:kTableSections])
        _sections = data[kTableSections];
    if ([data.allKeys containsObject:kTableUpdateData])
        _updateData = data[kTableUpdateData];
    if ([data.allKeys containsObject:kTableUpdateProperty])
        _updateProperty = data[kTableUpdateProperty];
}

@end

@interface OABaseTrackMenuHudViewController()

@property (weak, nonatomic) IBOutlet UIView *backButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *backButtonLeadingConstraint;

@property (nonatomic) OAGPX *gpx;
@property (nonatomic) BOOL isShown;
@property (nonatomic) NSArray<OAGPXTableSectionData *> *tableData;

@end

@implementation OABaseTrackMenuHudViewController
{
    CGFloat _cachedYViewPort;
}

- (instancetype)initWithGpx:(OAGPX *)gpx
{
    self = [self initWithNibName:[self getNibName] bundle:nil];
    if (self)
    {
        _gpx = gpx;

        _settings = [OAAppSettings sharedManager];
        _savingHelper = [OASavingTrackHelper sharedInstance];
        _mapPanelViewController = [OARootViewController instance].mapPanel;
        _mapViewController = _mapPanelViewController.mapViewController;
        [self updateGpxData];
        [self commonInit];
    }
    return self;
}

- (NSString *)getNibName
{
    return nil; //override
}

- (void)updateGpxData
{
    _isCurrentTrack = !_gpx || _gpx.gpxFilePath.length == 0 || _gpx.gpxFileName.length == 0;
    if (_isCurrentTrack)
    {
        if (!_gpx)
        _gpx = [_savingHelper getCurrentGPX];

        _gpx.gpxTitle = OALocalizedString(@"track_recording_name");
    }
    _doc = _isCurrentTrack ? (OAGPXDocument *) _savingHelper.currentTrack
            : [[OAGPXDocument alloc] initWithGpxFile:[[OsmAndApp instance].gpxPath stringByAppendingPathComponent:_gpx.gpxFilePath]];

    _analysis = [_doc getGeneralTrack] && [_doc getGeneralSegment]
            ? [OAGPXTrackAnalysis segment:0 seg:_doc.generalSegment] : [_doc getAnalysis:0];

    _isShown = [_settings.mapSettingVisibleGpx.get containsObject:_gpx.gpxFilePath];
}

- (void)commonInit
{
    //override
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self applyLocalization];
    _cachedYViewPort = _mapViewController.mapView.viewportYScale;

    UIImage *backImage = [UIImage templateImageNamed:@"ic_custom_arrow_back"];
    [self.backButton setImage:[self.backButton isDirectionRTL] ? backImage.imageFlippedForRightToLeftLayoutDirection : backImage
                     forState:UIControlStateNormal];
    self.backButton.imageView.tintColor = UIColorFromRGB(color_primary_purple);
    [self.backButton addBlurEffect:YES cornerRadius:12. padding:0];

    [self setupView];

    [self generateData];
    [self setupHeaderView];

    [self updateShowingState:[self isLandscape] ? EOADraggableMenuStateFullScreen : EOADraggableMenuStateExpanded];
}

- (void)applyLocalization
{
    //override
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_mapPanelViewController setTopControlsVisible:NO
                              customStatusBarStyle:[OAAppSettings sharedManager].nightMode
                                      ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault];
    [_mapPanelViewController targetSetBottomControlsVisible:YES
                                                 menuHeight:[self isLandscape] ? 0 : [self getViewHeight] - [OAUtilities getBottomMargin] + 4
                                                   animated:YES];
    [_mapPanelViewController.hudViewController updateMapRulerData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (![self isLandscape])
            [self goExpanded];
    } completion:nil];
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [self restoreMapViewPort];
    [_mapViewController hideContextPinMarker];
    [super hide:YES duration:duration onComplete:^{
        [_mapPanelViewController.hudViewController resetToDefaultRulerLayout];
        [_mapPanelViewController hideScrollableHudViewController];
        if (onComplete)
            onComplete();
    }];
}

- (void)setupView
{
    //override
}

- (void)setupHeaderView
{
    //override
}

- (void)generateData
{
    //override
}

- (BOOL)isTabSelecting
{
    return NO;  //override
}

- (BOOL)adjustCentering
{
    return NO;  //override
}

- (void)setupModeViewShadowVisibility
{
    self.topHeaderContainerView.layer.shadowOpacity = 0.0;
}

- (CGFloat)expandedMenuHeight
{
    return DeviceScreenHeight / 2;
}

- (BOOL)showStatusBarWhenFullScreen
{
    return YES;
}

- (void)doAdditionalLayout
{
    BOOL isRTL = [self.backButtonContainerView isDirectionRTL];
    self.backButtonLeadingConstraint.constant = [self isLandscape]
            ? (isRTL ? 0. : [self getLandscapeViewWidth] - [OAUtilities getLeftMargin] + 10.)
            : [OAUtilities getLeftMargin] + 10.;
    self.backButtonContainerView.hidden = ![self isLandscape] && self.currentState == EOADraggableMenuStateFullScreen;
}

- (void)adjustMapViewPort
{
    if ([self isLandscape] && _mapViewController.mapView.viewportXScale != VIEWPORT_SHIFTED_SCALE)
        _mapViewController.mapView.viewportXScale = VIEWPORT_SHIFTED_SCALE;
    else if (![self isLandscape] && _mapViewController.mapView.viewportXScale != VIEWPORT_NON_SHIFTED_SCALE)
        _mapViewController.mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
    if (_mapViewController.mapView.viewportYScale != [self getViewHeight] / DeviceScreenHeight)
        _mapViewController.mapView.viewportYScale = [self getViewHeight] / DeviceScreenHeight;
}

- (void)restoreMapViewPort
{
    OAMapRendererView *mapView = _mapViewController.mapView;
    if (mapView.viewportXScale != VIEWPORT_NON_SHIFTED_SCALE)
        mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
    if (mapView.viewportYScale != _cachedYViewPort)
        mapView.viewportYScale = _cachedYViewPort;
}

- (void)changeMapRulerPosition
{
    CGFloat bottomMargin = [self isLandscape] ? 0 : (-[self getViewHeight] + [OAUtilities getBottomMargin] - 20.);
    CGFloat leftMargin = [self isLandscape]
            ? [self getLandscapeViewWidth] - [OAUtilities getLeftMargin] + 20.
            : [OAUtilities getLeftMargin] + 20.;
    [_mapPanelViewController targetSetMapRulerPosition:bottomMargin
                                                  left:leftMargin];
}

- (NSLayoutConstraint *)createBaseEqualConstraint:(UIView *)firstItem
                                   firstAttribute:(NSLayoutAttribute)firstAttribute
                                       secondItem:(UIView *)secondItem
                                  secondAttribute:(NSLayoutAttribute)secondAttribute
{
    return [self createBaseEqualConstraint:firstItem
                            firstAttribute:firstAttribute
                                secondItem:secondItem
                           secondAttribute:secondAttribute
                                  constant:0.f];
}

- (NSLayoutConstraint *)createBaseEqualConstraint:(UIView *)firstItem
                                   firstAttribute:(NSLayoutAttribute)firstAttribute
                                       secondItem:(UIView *)secondItem
                                  secondAttribute:(NSLayoutAttribute)secondAttribute
                                         constant:(CGFloat)constant
{
    return [NSLayoutConstraint constraintWithItem:firstItem
                                        attribute:firstAttribute
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:secondItem
                                        attribute:secondAttribute
                                       multiplier:1.0f
                                         constant:constant];
}

- (IBAction)onBackButtonPressed:(id)sender
{
    [self hide:YES duration:.2 onComplete:^{
        [_mapViewController hideContextPinMarker];
    }];
}

#pragma mark - OADraggableViewActions

- (void)onViewHeightChanged:(CGFloat)height
{
    if (![self isTabSelecting] && [self adjustCentering])
    {
        [_mapPanelViewController targetSetBottomControlsVisible:YES
                                                     menuHeight:[self isLandscape] ? 0 : height - [OAUtilities getBottomMargin]
                                                       animated:YES];
        if ((self.currentState != EOADraggableMenuStateFullScreen && ![self isLandscape]) || [self isLandscape])
        {
            [self changeMapRulerPosition];
            [self adjustMapViewPort];
            [_mapPanelViewController targetGoToGPX];
        }
    }
}

@end
