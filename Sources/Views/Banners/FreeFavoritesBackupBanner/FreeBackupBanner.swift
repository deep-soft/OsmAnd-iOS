//
//  FreeFavoritesBackupBanner.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 18.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class FreeBackupBanner: UIView {
    @objc enum BannerType: Int {
        case favorite
        case settings
        
    }
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var osmAndCloudButton: UIButton! {
        didSet {
            osmAndCloudButton.titleLabel?.text = localizedString("banner_payment_free_backup_cloud_button_title")
        }
    }
    @IBOutlet weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.text = localizedString("free_favorites_backup_description")
        }
    }
    
    var didCloseButtonAction: (() -> Void)? = nil
    var didOsmAndCloudButtonAction: (() -> Void)? = nil
    
    var defaultFrameHeight = 120
    var leadingTrailingOffset = 137
    
    func configure(bannerType: BannerType) {
        switch bannerType {
        case .favorite:
            titleLabel.text = localizedString("free_favorites_backup")
            imageView.image = UIImage(named: "ic_custom_folder_cloud_colored")
        case .settings:
            titleLabel.text = localizedString("banner_payment_free_backup_settings_title")
            imageView.image = UIImage(named: "ic_custom_settings_cloud_colored")
        }
    }
    
    // MARK: - @IBActions
    @IBAction private func onOsmAndCloudButtonAction(_ sender: UIButton) {
        didOsmAndCloudButtonAction?()
    }
    
    @IBAction private func onCloseButtonAction(_ sender: UIButton) {
        didCloseButtonAction?()
    }
}
