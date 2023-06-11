//
//  OAOsmLoginMainViewController.m
//  OsmAnd
//
//  Created by Skalii on 01.09.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAOsmLoginMainViewController.h"
#import "OAOsmAccountSettingsViewController.h"
#import "OASizes.h"
#import "Localization.h"

@interface OAOsmLoginMainViewController () <OAAccountSettingDelegate>

@property (weak, nonatomic) IBOutlet UIView *navigationBarView;
@property (weak, nonatomic) IBOutlet UIButton *cancelLabel;

@property (weak, nonatomic) IBOutlet UIScrollView *contentScrollView;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UIView *bottomButtonsContainerView;
@property (weak, nonatomic) IBOutlet UIButton *topButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *navBarHeightConstraint;

@end

@implementation OAOsmLoginMainViewController

- (void)applyLocalization
{
    [self.cancelLabel setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    self.titleLabel.text = OALocalizedString(@"login_open_street_map_org");
    self.descriptionLabel.text = OALocalizedString(@"open_street_map_login_mode_simple");
    [self.topButton setTitle:OALocalizedString(@"sign_in_with_open_street_map") forState:UIControlStateNormal];
    [self.bottomButton setTitle:OALocalizedString(@"use_login_and_password") forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupNavBarHeight];
    self.titleLabel.font = [UIFont scaledSystemFontOfSize:30. weight:UIFontWeightSemibold];
    self.topButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
    self.bottomButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];

}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setupNavBarHeight];
    } completion:nil];
}

- (void)setupNavBarHeight
{
    self.navBarHeightConstraint.constant = [self isModal] ? [OAUtilities isLandscape] ? defaultNavBarHeight : modalNavBarHeight : defaultNavBarHeight;
}

- (IBAction)onBottomButtonPressed:(id)sender
{
    OAOsmAccountSettingsViewController *accountSettings = [[OAOsmAccountSettingsViewController alloc] init];
    accountSettings.accountDelegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:accountSettings];
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - OAAccountSettingDelegate

- (void)onAccountInformationUpdated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.delegate)
                [self.delegate onAccountInformationUpdated];
        }];
    });
}

@end
