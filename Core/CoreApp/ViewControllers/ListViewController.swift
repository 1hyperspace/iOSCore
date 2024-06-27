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

class ListViewController: UIViewController {

    private var contentApp: StateApp<ContentApp>
    private let repo: Repository<Movie>
    private let searchController = UISearchController(searchResultsController: nil)
    private var lastOp: Operation?

    private var collectionView: UICollectionView!
    private var bag = Set<AnyCancellable>()
    private let compositionalLayout: UICollectionViewCompositionalLayout = {
        let fractionWidth: CGFloat = 1
        let fractionHeight: CGFloat = 1 / 2
        let inset: CGFloat = 2.5

        // Item
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fractionWidth), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)

        // Group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(fractionHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        // Section
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
        return UICollectionViewCompositionalLayout(section: section)
    }()

    init() {
        repo = Repository<Movie>()

        contentApp = StateApp<ContentApp>(
            helpers: .init(
                networkHelper: NetworkHelper(),
                movieRepo: repo
            )
        )

        let query = repo.stateApp.helpers.modelBuilder.defaultQuery()
        query.addSort(field: .year, expression: "DESC")
        _ = repo.dispatch(.set(query: query))

        contentApp.dispatch(.checkForData)
        
        super.init(nibName: nil, bundle: nil)
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
        _ = repo.dispatch(.reloadItems)
    }

    private func setup() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: compositionalLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ListItemCell.self, forCellWithReuseIdentifier: "listItemCell")
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        repo.stateApp.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.collectionView.reloadData()
        }.store(in: &bag)

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Movies"
        navigationItem.searchController = searchController
        definesPresentationContext = true

    }
}

extension ListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return repo.stateApp.state.totalCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "listItemCell", for: indexPath) as? ListItemCell else {
            fatalError()
        }
        let movie = repo.get(itemAt: indexPath.row)
        if let movie = movie {
            cell.configure(text: "\(movie.title)")
        } else {
            cell.configure(text: "")
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movie = repo.get(itemAt: indexPath.row)

        print("TODO: Push: \(movie!.id)")
    }
}

extension ListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        var query = repo.stateApp.helpers.modelBuilder.searchQuery()
        if let queryText = searchController.searchBar.text, !queryText.isEmpty {
            query.addFilter(field: .title, expression: "MATCH \"\(queryText)\"")
        } else {
            query = repo.stateApp.helpers.modelBuilder.defaultQuery()
        }
        lastOp?.cancel()
        lastOp = repo.dispatch(.set(query: query))
        contentApp.dispatch(.checkForData)
    }
}
