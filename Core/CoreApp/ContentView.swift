//
//  ContentView.swift
//  Core
//
//  Created by 1Hyper Space on 4/9/21.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var contentApp = StateApp<ContentApp>(
        helpers: .init(
            networkHelper: NetworkHelper(),
            abiStorage: Repository<ABIItems>.new()
        )
    )

    var body: some View {
        NavigationView {
            Button("Something to change: \(String(contentApp.state.buttonTapped))") {
                contentApp.dispatch(.buttonTapped)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
