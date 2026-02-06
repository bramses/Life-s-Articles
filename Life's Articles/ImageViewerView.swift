//
//  ImageViewerView.swift
//  Life's Articles
//
//  Created by Bram Adams on 2/6/26.
//

import SwiftUI

struct ImageViewerView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                Color.black
                    .ignoresSafeArea()
                    .overlay(
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: proxy.size.width, maxHeight: proxy.size.height)
                            .padding()
                    )
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
