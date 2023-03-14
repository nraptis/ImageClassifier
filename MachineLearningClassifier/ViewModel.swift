//
//  ViewModel.swift
//  MachineLearningClassifier
//
//  Created by Nicky Taylor on 2/21/23.
//

import UIKit
import Vision
import CoreML

class ViewModel: ObservableObject {
    
    
    @Published var image: UIImage?
    
    @Published var classification1: String?
    @Published var confidence1: String?
    
    @Published var classification2: String?
    @Published var confidence2: String?
    
    @Published var classification3: String?
    @Published var confidence3: String?
    
    init() {
        if let url = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Red-eyed_Tree_Frog_%28Agalychnis_callidryas%29_1.png/800px-Red-eyed_Tree_Frog_%28Agalychnis_callidryas%29_1.png") {
            dragURLIntent(url: url)
        }
    }
    
    private lazy var model: MLModel? = {
        let configuration = MLModelConfiguration()
        do {
            let classifier = try MobileNet(configuration: configuration)
            return classifier.model
        } catch let error {
            print("MobileNet Model Load Error: \(error.localizedDescription)")
            return nil
        }
    }()
    
    private lazy var visionModel: VNCoreMLModel? = {
        guard let model = model else {
            return nil
        }
        do {
            let result = try VNCoreMLModel(for: model)
            return result
        } catch let error {
            print("VNCoreMLModel Load Error: \(error.localizedDescription)")
            return nil
        }
    }()
    
    func dragImageIntent(image: UIImage?) {
        guard let image = image else {
            failed(reason: "null image")
            return
        }
        
        guard let image = cropAndFit(image: image, width: 224.0, height: 224.0) else {
            failed(reason: "image invalid crop")
            return
        }
        
        DispatchQueue.main.async {
            self.image = image
        }
        
        DispatchQueue.global(qos: .default).async {
            self.classify(image: image)
        }
    }
    
    func dragURLIntent(url: URL?) {
        guard let url = url else {
            failed(reason: "null url")
            return
        }
        
        DispatchQueue.global(qos: .default).async {
            do {
                let data = try Data(contentsOf: url)
                guard let image = UIImage(data: data) else {
                    self.failed(reason: "data was not an image")
                    return
                }
                
                self.dragImageIntent(image: image)
                
            } catch let error {
                print("Data Download Error: \(error.localizedDescription)")
                self.failed(reason: "data download error")
            }
        }
    }
    
    private func cropAndFit(image: UIImage, width: CGFloat, height: CGFloat) -> UIImage? {
        
        guard width > 8.0 else { return nil }
        guard height > 8.0 else { return nil }
        guard image.size.width > 8.0 else { return nil }
        guard image.size.height > 8.0 else { return nil }
        
        let size = CGSize(width: width, height: height)
        let fit = size.getAspectFill(CGSize(width: image.size.width, height: image.size.height))
        
        let x: CGFloat = width * 0.5 - fit.width * 0.5
        let y: CGFloat = height * 0.5 - fit.height * 0.5
        
        UIGraphicsBeginImageContext(CGSizeMake(width, height))
        image.draw(in: CGRectMake(x, y, fit.width, fit.height))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }
    
    func classify(image: UIImage?) {
        guard let image = image else {
            failed(reason: "null image")
            return
        }
        
        guard let cgImage = image.cgImage else {
            failed(reason: "image null cgImage")
            return
        }
        
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)) else {
            failed(reason: "image orientation missing")
            return
        }
        
        guard let visionModel = visionModel else {
            failed(reason: "vision model null")
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestHandler)
        let requests = [request]
        
        let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage,
                                                        orientation: orientation)
        
        do {
            try imageRequestHandler.perform(requests)
        } catch let error {
            print("Vision Image Request Error: \(error.localizedDescription)")
            failed(reason: "vision image request error")
            return
        }
    }
    
    private func visionRequestHandler(request: VNRequest, error: Error?) {
        
        if let error = error {
            print("Vision Request Error: \(error.localizedDescription)")
            failed(reason: "vision request error")
            return
        }
        
        guard let results = request.results else {
            failed(reason: "vision request missing results")
            return
        }
        
        print("got \(results.count) results!!!")
        
        let classifications = results.compactMap {
            $0 as? VNClassificationObservation
        }
        
        guard classifications.count > 0 else {
            failed(reason: "no classifications found")
            return
        }
        
        DispatchQueue.main.async {
            if classifications.count > 0 {
                self.classification1 = classifications[0].identifier
                self.confidence1 = self.string(percent: classifications[0].confidence)
            } else {
                self.classification1 = nil
                self.confidence1 = nil
            }
            
            if classifications.count > 1 {
                self.classification2 = classifications[1].identifier
                self.confidence2 = self.string(percent: classifications[1].confidence)
            } else {
                self.classification2 = nil
                self.confidence2 = nil
            }
            
            if classifications.count > 2 {
                self.classification3 = classifications[2].identifier
                self.confidence3 = self.string(percent: classifications[2].confidence)
            } else {
                self.classification3 = nil
                self.confidence3 = nil
            }
        }
    }
    
    private func clearClassifications() {
        DispatchQueue.main.async {
            self.classification1 = nil
            self.confidence1 = nil
            
            self.classification2 = nil
            self.confidence2 = nil
            
            self.classification3 = nil
            self.confidence3 = nil
        }
    }
    
    func failed(reason: String) {
        print("Failed: \(reason)")
        clearClassifications()
    }
    
    private func string(percent: VNConfidence) -> String {
        let percent = max(min(percent * 100.0, 100.0), 0.0)
        return String(format: "%.1f%%", percent)
    }
    
}
