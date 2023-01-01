# iOSCore - Storage library for large offline collections

iOSCore is a lightweight library for storing codable objects in a local database on iOS devices. With iOSCore, you can easily persist your data model objects and retrieve them with just a few lines of code. The library handles large, searchable collections in a seamless manner through a caching mechanism that allows maximum performance while having low memory footprint. The collection can be filtered and sorted according to a specified query. 

## Features

- Simple API for storing and retrieving codable objects
- Works with any type that conforms to the `Codable` protocol
- Written in Swift

## Usage

Here is an example of how to use iOSCore to store and retrieve an object:

```swift
import iOSCore

struct Movie: Storable, Equatable {
    let title: String
    let year: Int
    let cast: [String]
    let genres: [String]
    
    var id: String {
        title + "\(year)" + "\(genres)" + "\(cast)"
    }

    enum IndexedFields: IndexableKeys {
        case title, year
    }
}

let repo = Repository<Movie>()

// Handles caching internally
let movie = repo.get(itemAt: 0)
```

How to change the default filtering or sorting:

```swift

// Take default query
let query = repo.stateApp.helpers.modelBuilder.cleanQuery()

// You can sort or filter by the specified indexed keys
query.addSort(field: .year, expression: "DESC")
query.addFilter(field: .title, expression: "like %wind%")

// Set and lock the query for reads
repo.dispatch(.set(query: query))

```

How to add items:

```swift
// Parse or create items
let items = [Movie(...), Movie(...)]

// Dispatch async adding
repo.dispatch(.add(items: items))
```

## License

iOSCore is released under the MIT license. See LICENSE for details.

