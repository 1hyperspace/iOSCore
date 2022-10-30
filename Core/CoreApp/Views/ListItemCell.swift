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
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        contentView.addSubview(titleLabel)
        contentView.backgroundColor = .red
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(text: String) {
        titleLabel.text = text
    }
}
