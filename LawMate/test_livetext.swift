import SwiftUI
import VisionKit

struct LiveTextImageView: UIViewRepresentable {
    let image: UIImage
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.tag = 999
        
        // Setup Live Text
        if #available(iOS 16.0, *) {
            let analyzer = ImageAnalyzer()
            let interaction = ImageAnalysisInteraction()
            imageView.addInteraction(interaction)
            
            Task {
                let config = ImageAnalyzer.Configuration([.text, .machineReadableCode])
                if let analysis = try? await analyzer.analyze(image, configuration: config) {
                    DispatchQueue.main.async {
                        interaction.analysis = analysis
                        interaction.preferredInteractionTypes = .automatic
                    }
                }
            }
        }
        
        scrollView.addSubview(imageView)
        
        // We need a coordinator for zooming
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // Update layout
    }
}
