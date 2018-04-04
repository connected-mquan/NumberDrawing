//
//  ViewController.swift
//  NumberDrawing
//
//  Created by cl-dev on 2018-04-04.
//  Copyright © 2018 cl-dev. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {

  lazy var mlModel: VNCoreMLModel! = {
    do {
      return try VNCoreMLModel(for: MNIST().model)
    } catch {
      fatalError("Could not load MLModel")
    }
  }()

  lazy var canvasBorderView: UIView = {
    let view = UIView()
    view.backgroundColor = .blue
    return view
  }()

  lazy var canvasView: UIView = {
    let view = UIView()
    view.backgroundColor = .black
    view.clipsToBounds = true
    return view
  }()

  lazy var predictionLabel: UILabel = {
    let label = UILabel()
    return label
  }()

  lazy var clearButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("Clear Canvas", for: .normal)
    button.addTarget(self, action: #selector(clearCanvas), for: .touchUpInside)
    return button
  }()

  lazy var previewImage = UIImageView()

  var predictedNumber: String = "" {
    didSet {
      predictionLabel.text = "Prediction: \(predictedNumber)"
    }
  }

  var currentDrawingPath: UIBezierPath? = nil
  var currentDrawingLayer: CAShapeLayer? = nil

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    for v in [canvasBorderView, canvasView, previewImage, clearButton, predictionLabel] as [UIView] {
      v.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(v)
    }

    canvasBorderView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
    canvasBorderView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
    canvasBorderView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
    canvasBorderView.heightAnchor.constraint(equalTo: canvasBorderView.widthAnchor).isActive = true

    canvasView.leftAnchor.constraint(equalTo: canvasBorderView.leftAnchor, constant: 4).isActive = true
    canvasView.rightAnchor.constraint(equalTo: canvasBorderView.rightAnchor, constant: -4).isActive = true
    canvasView.topAnchor.constraint(equalTo: canvasBorderView.topAnchor, constant: 4).isActive = true
    canvasView.bottomAnchor.constraint(equalTo: canvasBorderView.bottomAnchor, constant: -4).isActive = true

    previewImage.widthAnchor.constraint(equalToConstant: 28).isActive = true
    previewImage.heightAnchor.constraint(equalToConstant: 28).isActive = true
    previewImage.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

    clearButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    clearButton.topAnchor.constraint(equalTo: previewImage.bottomAnchor, constant: 20).isActive = true

    predictionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    predictionLabel.topAnchor.constraint(equalTo: clearButton.bottomAnchor, constant: 20).isActive = true
    predictionLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    startPredictionTimer()
//    let timer = Timer(fire: Date().addingTimeInterval(1), interval: 1, repeats: true) { (_) in
//      guard let image = CIImage(image: self.copyViewAsImage(self.canvasView)) else {
//        return
//      }
//      self.previewImage.image = UIImage(ciImage: image)
//      let numberPredictionRequest = VNCoreMLRequest(model: self.mlModel, completionHandler: self.predictionRequestCompletionHandler)
//      let numberPredictionHandler = VNImageRequestHandler(ciImage: image, options: [:])
//      try? numberPredictionHandler.perform([numberPredictionRequest])
//    }
//    RunLoop.current.add(timer, forMode: .defaultRunLoopMode)
  }

  //////////////////////////////////////////////////////////
  ///////////////////// MARK: - CoreML /////////////////////
  //////////////////////////////////////////////////////////

  func startPredictionTimer() {
    let timer = Timer(fire: Date().addingTimeInterval(1), interval: 1, repeats: true) { (_) in
      guard let image = CIImage(image: self.copyViewAsImage(self.canvasView)) else {
        return
      }
      self.previewImage.image = UIImage(ciImage: image)
      let numberPredictionRequest = VNCoreMLRequest(model: self.mlModel, completionHandler: self.predictionRequestCompletionHandler)
      let numberPredictionHandler = VNImageRequestHandler(ciImage: image, options: [:])
      try? numberPredictionHandler.perform([numberPredictionRequest])
    }
    RunLoop.current.add(timer, forMode: .defaultRunLoopMode)
  }

  func predictionRequestCompletionHandler(request: VNRequest, error: Error?) {
    guard error == nil, let results = request.results as? [VNClassificationObservation] else {
      return
    }

    let topResult = results[0]
    DispatchQueue.main.async { [weak self] in
      self?.predictedNumber = topResult.identifier
    }

  }

  func copyViewAsImage(_ view: UIView) -> UIImage {
    let rect = view.bounds
    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()!
    view.layer.render(in: context)
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return image
  }

  //////////////////////////////////////////////////////////
  ///////////////////// MARK: - Canvas /////////////////////
  //////////////////////////////////////////////////////////

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    guard let touch = touches.first else {
      return
    }
    let point = touch.location(in: canvasView)
    let path = UIBezierPath()
    path.move(to: point)
    let shapeLayer = CAShapeLayer()
    shapeLayer.frame = canvasView.bounds
    shapeLayer.strokeColor = UIColor.white.cgColor
    shapeLayer.fillColor = UIColor.clear.cgColor
    shapeLayer.lineWidth = 15
    canvasView.layer.addSublayer(shapeLayer)

    currentDrawingPath = path
    currentDrawingLayer = shapeLayer
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesMoved(touches, with: event)
    guard let touch = touches.first, let path = currentDrawingPath, let shapeLayer = currentDrawingLayer else {
      return
    }
    let point = touch.location(in: canvasView)
    path.addLine(to: point)
    shapeLayer.path = path.cgPath
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    currentDrawingPath = nil
    currentDrawingLayer = nil
  }

  @objc func clearCanvas() {
    if let sublayers = canvasView.layer.sublayers {
      for sublayer in sublayers {
        sublayer.removeFromSuperlayer()
      }
    }
  }
}

