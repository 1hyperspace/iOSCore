# 1Hyper iOSCore library for developing Offline Apps

Most of us developers design apps that are always connected and are always consulting backend services. Most of these apps require an active backend at the moment to do certain operations or to show certain data. 

What this library tries to do, is to allow the developer to create mini `Repositories` of classes that, if they conform to certain protocols, can be used offline (read, write, search).

## Installation 

* Swift Package manager
* Cocoapods
* Carthage

## The `Repository` class

The `Repository<T>` it's a class that allows you to create a locally stored repository of items. It works on top of a mini framework that allows to create `State` apps in a very declarative way. It's concepts are based on _Mobius Framework_ (see [Concepts](https://github.com/spotify/Mobius.swift/wiki/Concepts) and [Workflow](https://github.com/spotify/Mobius.swift/wiki/The-Mobius-Workflow))
