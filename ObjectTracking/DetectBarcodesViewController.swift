//
//  DetectBarcodesViewController.swift
//  ObjectTracking
//
//  Created by 越智宗洋 on 2019/02/11.
//  Copyright © 2019年 越智宗洋. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class DetectBarcodesViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private var handler = VNSequenceRequestHandler()
    private var currentTarget: VNDetectedObjectObservation?
    private var textLayer: CATextLayer! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.session.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.session.stopRunning()
    }
    
    private func setup() {
        setupVideoProcessing()
        setupCameraPreview()
        setupTextLayer()
    }
    
    private func setupVideoProcessing() {
        self.session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        let input = try! AVCaptureDeviceInput(device: device)
        self.session.addInput(input)
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: .global())
        self.session.addOutput(videoDataOutput)
    }
    
    private func setupCameraPreview() {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer.backgroundColor = UIColor.clear.cgColor
        self.previewLayer.videoGravity = .resizeAspectFill
        let rootLayer = self.view.layer
        rootLayer.masksToBounds = true
        self.previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(self.previewLayer)
    }
    
    private func setupTextLayer() {
        let textLayer = CATextLayer()
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.fontSize = 20
        textLayer.alignmentMode = .center
        textLayer.frame = CGRect(x: 0, y: 0, width: 300, height: 24)
        textLayer.cornerRadius = 4
        textLayer.backgroundColor = UIColor(white: 0.25, alpha: 0.5).cgColor
        textLayer.position = self.view.center
        textLayer.isHidden = true
        self.previewLayer.addSublayer(textLayer)
        self.textLayer = textLayer
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let handler = VNSequenceRequestHandler()
        let barcodesDetectionRequest = VNDetectBarcodesRequest(completionHandler: self.handleBarcodes)
        
        try? handler.perform([barcodesDetectionRequest], on: pixelBuffer)
    }
    
    private func handleBarcodes(request: VNRequest, error: Error?) {
        guard let barcode = request.results?.first as? VNBarcodeObservation else {
            DispatchQueue.main.async {
                self.textLayer.isHidden = true
            }
            return
        }
        
        if let value = barcode.payloadStringValue {
            DispatchQueue.main.async {
                self.textLayer.string = value
                self.textLayer.isHidden = false
            }
        }
    }
    
}
