//
//  ListViewController.swift
//  Core
//
//  Created by LL on 7/20/22.
//

import Foundation
import UIKit
import SnapKit
import Combine

class ListViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private var contentApp: StateApp<ContentApp>
    private var repoApp: StateApp<RepositoryApp<Person>>
    private let repo: Repository<Person>

    private var collectionView: UICollectionView!
    var cancellable: Cancellable?

    override init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
        repo = Repository<Person>()

        contentApp = StateApp<ContentApp>(
            helpers: .init(
                networkHelper: NetworkHelper(),
                abiRepo: Repository<ABIItems>(),
                personRepo: repo
            )
        )

        repoApp = repo.stateApp
        let query = repoApp.helpers.modelBuilder.cleanQuery()
        query.addSort(field: .age, expression: "DESC")
        repoApp.dispatch(.set(query: query))
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .red
        setup()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        repoApp.dispatch(.reloadItems)
    }

    private func setup() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.estimatedItemSize = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        self.view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        collectionView.register(ListItemCell.self, forCellWithReuseIdentifier: "listItemCell")

        cancellable = repo.stateApp.$state.sink { [weak self] _ in
            self?.collectionView.reloadData()
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return repo.stateApp.state.totalCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "listItemCell", for: indexPath) as? ListItemCell else {
            fatalError()
        }
        let person = repo.get(itemAt: indexPath.row)
        if let person = person {
            cell.configure(text: "\(person.name) of \(person.age)")
        } else {
            cell.configure(text: "EMPTY")
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 200, height: 80)
    }

}
