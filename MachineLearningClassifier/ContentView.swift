//
//  ContentView.swift
//  MachineLearningClassifier
//
//  Created by Nicky Taylor on 2/21/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    var body: some View {
        VStack {
            Spacer()
            
            Text("Use iPad in split view (3 dots at top), drag valid image onto app")
                .padding(.horizontal, 42.0)
                .padding(.bottom, 16.0)
            
            HStack {
                Spacer()
                
                ZStack {
                    if let image = viewModel.image {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 224.0, height: 224.0)
                    }
                }
                .frame(width: 224.0, height: 224.0)
                .background(Color.gray.opacity(0.5))
                .background(Rectangle().stroke(style: StrokeStyle(lineWidth: 2.0)).foregroundColor(.gray))
                
                Spacer()
            }
            
            if let classification = viewModel.classification1,
               let confidence = viewModel.confidence1 {
                classificationTagView(classification: classification,
                                      confidence: confidence)
            }
            
            if let classification = viewModel.classification2,
               let confidence = viewModel.confidence2 {
                classificationTagView(classification: classification,
                                      confidence: confidence)
            }
            
            if let classification = viewModel.classification3,
               let confidence = viewModel.confidence3 {
                classificationTagView(classification: classification,
                                      confidence: confidence)
            }
            
            Spacer()
        }
        .onDrop(of: [.url, .image], isTargeted: nil) { providers, _ in
            drop(providers: providers)
        }
    }
    
    private func classificationTagView(classification: String, confidence: String) -> some View {
        HStack {
            HStack {
                Text(classification)
                    .foregroundColor(.white)
                    .padding(.all, 4.0)
                    .multilineTextAlignment(.leading)
            }
            .background(RoundedRectangle(cornerRadius: 12.0).foregroundColor(.blue))
            
            HStack {
                Text(confidence)
                    .foregroundColor(.blue)
                    .padding(.all, 4.0)
            }
            .background(RoundedRectangle(cornerRadius: 12.0).foregroundColor(.black))
            
            Spacer()
        }
        .frame(width: 224.0)
    }
    
    func drop(providers: [NSItemProvider]) -> Bool {
        
        var found = false
        
        if !found {
            found = providers.loadObjects(ofType: URL.self) { url in
                print("got a url: \(url)")
                viewModel.dragURLIntent(url: url)
            }
        }
        
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                print("for a image: \(image.size.width) x \(image.size.height)")
                viewModel.dragImageIntent(image: image)
            }
        }
        
        return found
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
