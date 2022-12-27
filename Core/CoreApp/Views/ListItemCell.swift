//
//  ListItemCell.swift
//  Core
//
//  Created by LL on 7/20/22.
//

import Foundation
import UIKit
import SnapKit

class ListItemCell: UICollectionViewCell {

    var titleLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        titleLabel = UILabel()
        titleLabel.textAlignment = .left
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        titleLabel.font = titleLabel.font.withSize(31)
        contentView.addSubview(titleLabel)
        contentView.backgroundColor = .red
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
    }

    func configure(text: String) {
        titleLabel.text = text
    }
}
