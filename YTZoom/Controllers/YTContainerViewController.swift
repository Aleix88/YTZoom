//
//  ViewController.swift
//  YoutubeMagicDrag
//
//  Created by Aleix Baggerman on 31/01/2018.
//  Copyright © 2018 Aleix Baggerman. All rights reserved.
//

import UIKit

enum ViewState {
    case top, bottom, undisplayed, removing, scaling, landScape
}

enum HorizontalPosition {
    case left, right, none
}

class YTContainerViewController: UIViewController {
    
    let customProperties = Constants ()
    
    private var topViewControllerContainer: UIView!
    private var bottomViewControllerContainer: UIView!
    private var bottomViewController: UIViewController!
    private var topViewController: UIViewController!
    private var panGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    private var bottomXPosition: CGFloat!
    private var positon = CGPoint.zero
    private var viewState: ViewState! {
        didSet {
            if viewState == .top {
                deviceCanRotate(true)
            } else {
                deviceCanRotate(false)
            }
        }
    }
    
    var isUserInteractionEnabled = true {
        didSet {
            panGesture.isEnabled = isUserInteractionEnabled
            tapGesture.isEnabled = isUserInteractionEnabled
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewState = .undisplayed
        self.view.backgroundColor = .white
        AppUtility.lockOrientation(.portrait)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard self.viewState != .undisplayed else {return}
        let orientation = UIDevice.current.orientation
        
        if orientation.isLandscape {
            setupLandscapeContainerSize(mainViewSize: size)
            self.view.sendSubview(toBack: bottomViewControllerContainer)
            isUserInteractionEnabled = false
        } else {
            self.viewState = .top
            self.setupPortraitContainerSize(mainViewSize: size)
            self.view.bringSubview(toFront: bottomViewControllerContainer)
            isUserInteractionEnabled = true
        }
    }
    
    /// Enable or disable the device rotation.
    ///
    /// - Parameter allowed: boolean that represents if the screen can rotate.
    private func deviceCanRotate (_ allowed: Bool) {
        AppUtility.lockOrientation(allowed ? .all : .portrait)
    }

    /// Make the necessary changes to the containers when the device is in landscape mode.
    ///
    /// - Parameter mainViewSize: the size of the YTContainerViewController
    private func setupLandscapeContainerSize (mainViewSize: CGSize) {
        topViewControllerContainer.frame.size = CGSize.init(width: mainViewSize.width, height: mainViewSize.height)
        topViewControllerContainer.frame.origin.y = 0
    }
    
    
    /// Make the necessary changes to the containers when the device is in portrait mode.
    ///
    /// - Parameter mainViewSize: the size of the YTContainerViewController
    private func setupPortraitContainerSize (mainViewSize: CGSize) {
        self.topViewControllerContainer.frame.size = getTopContainerSize(mainViewWidth: mainViewSize.width)
        self.topViewControllerContainer.frame.origin.y += customProperties.topMargin
    }
    
    /// Present a new or a existing ViewController. If the YTTopViewController is undisplayed it will create new containers. If the YTTopViewControllers is displayed it reuse the exisiting containers
    ///
    /// - Parameters:
    ///   - initialFrame: where the container will be instiatiated. If the container was already instantiated the frame should be nil (it won't be used anyways, if the container wasn't instantiated it will appear from this frame.
    ///   - topViewController: ViewController linked with the top container view.
    ///   - bottomViewController: ViewController linked with the bottom container view.
    final func presentViewControllers (initialFrame: CGRect? = .zero, topViewController: UIViewController, bottomViewController: UIViewController) {
        if self.viewState == .undisplayed {
            presentViewControllersUndisplayed(initialFrame: initialFrame!, topViewController: topViewController, bottomViewController: bottomViewController)
        } else {
            moveContainersToOrigin()
        }
    }
    
    
    /// Add all the views needed to present the viewControllers. It also add an scale and transform animation of the top container from the initialFrame to the finalFrame.
    ///
    /// - Parameters:
    ///   - initialFrame: the initial frame to start the animation
    ///   - topViewController: the viewController added to the top container
    ///   - bottomViewController: the viewController added to the bottom container
    final func presentViewControllersUndisplayed (initialFrame: CGRect, topViewController: UIViewController, bottomViewController: UIViewController) {
        self.topViewController = topViewController
        self.bottomViewController = bottomViewController
        setupTopContainerView (initialFrame: initialFrame)
        setupBottomContainerView()
        addChildViewControllerViews ()
        moveContainersToOrigin()
        preparePanGesture ()
        prepareTapGesture ()
    }
    
    /// Configure the tap gesture recognizer.
    private func prepareTapGesture () {
        tapGesture = UITapGestureRecognizer (target: self, action: #selector (handleTapGesture))
        self.topViewControllerContainer.addGestureRecognizer(tapGesture)
    }
    
    
    /// Animate view if needed when is tapped.
    @objc func handleTapGesture () {
        moveContainersToOrigin()
    }
    
    /// Add the viewControllers views to the containers and setup the constraints.
    private func addChildViewControllerViews () {
        addChildViewController(topViewController)
        addChildViewController(bottomViewController)
            
        topViewControllerContainer.addSubview(topViewController.view)
        bottomViewControllerContainer.addSubview(bottomViewController.view)

        topViewController.view.anchor(top: topViewControllerContainer.topAnchor, left: topViewControllerContainer.leftAnchor, bottom: topViewControllerContainer.bottomAnchor, right: topViewControllerContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        bottomViewController.view.anchor(top: bottomViewControllerContainer.topAnchor, left: bottomViewControllerContainer.leftAnchor, bottom: bottomViewControllerContainer.bottomAnchor, right: bottomViewControllerContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        viewState = .top
    }
    
    
    /// Configure the pan gesture for the top container.
    private func preparePanGesture () {
        panGesture = UIPanGestureRecognizer.init(target: self, action: #selector (draggingScreen(sender:)))
        self.topViewControllerContainer.addGestureRecognizer(panGesture)
    }

    /// Set the initial paramenters for the top container
    ///
    /// - Parameter initialFrame: the intial frame from where it will appear.
    private func setupTopContainerView (initialFrame: CGRect) {
        let scaleFactor = calculateScaleFactor(viewFrame: initialFrame)
        
        topViewControllerContainer = UIView()
        topViewControllerContainer.layer.masksToBounds = true
        self.view.addSubview(topViewControllerContainer)
        
        topViewControllerContainer.frame.size = getTopContainerSize(mainViewWidth: self.view.frame.width)
        topViewControllerContainer.transform = CGAffineTransform.init(scaleX: scaleFactor, y: scaleFactor)
        topViewControllerContainer.frame.origin = initialFrame.origin
    }
    
    /// Return the top container size with the resolution indicated in the constants and with a width equals to the YTContainerViewController view.
    ///
    /// - Parameter mainViewWidth: YTContainerViewController width
    /// - Returns: size of the top container
    private func getTopContainerSize (mainViewWidth: CGFloat) -> CGSize {
        return CGSize (width: mainViewWidth, height: mainViewWidth/customProperties.videoRatio)
    }
    
    /// Animate the containers to the initial position
    ///
    /// - Parameter isScaled: if the top container is scaled.
    private func moveContainersToOrigin () {
        UIView.animate(withDuration: customProperties.animationDuration) {
            self.setContainersInitialPositions()
        }
    }
    
    /// Animate the containers to the bottom positon.
    private func moveContainersToFinal () {
        UIView.animate(withDuration: customProperties.animationDuration) {
            self.setContainersFinalPositions()
        }
    }
    
    
    /// Configure the initial parameters of the bottom container view.
    private func setupBottomContainerView () {
        bottomViewControllerContainer = UIView ()
        bottomViewControllerContainer.alpha = 1
        self.view.addSubview(bottomViewControllerContainer)
        bottomViewControllerContainer.frame.origin = CGPoint (x: 0, y: self.view.frame.height)
    }

    
    /// Controll all the pan gesture logic
    ///
    /// - Parameter sender: UIPanGestureRecognizer of the top view container.
    @objc func draggingScreen (sender: UIPanGestureRecognizer) {
        setupPositionWhilePan(sender: sender)
        
        if isHorizontalyDraggable() {
            dragHorizontaly(sender: sender)
        }
        if isVerticalyDraggable() {
            minimizeViews(sender: sender)
        }
        
        sender.setTranslation(.zero, in: topViewControllerContainer)
    }
    
    
    /// Returns if the top view can be dragged verticaly.
    ///
    /// - Returns: inidicate if the top view container verticaly draggable or not.
    private func isVerticalyDraggable () -> Bool {
        if abs(positon.y) > abs(positon.x) || viewState == .scaling {
            if viewState != .removing {
                return true
            }
        }
        return false
    }
    
    
    /// Returns if the top view can be dragged horizontaly.
    ///
    /// - Returns: inidicate if the top view container horizontaly draggable or not.
    private func isHorizontalyDraggable () -> Bool {
        if abs(positon.y) <= abs(positon.x) || viewState == .removing {
            if viewState != .scaling && viewState != .top {
                return true
            }
        }
        return false
    }
    
    
    /// Make the translation of the views while dragging.
    ///
    /// - Parameter sender: UIPanGestureRecognizer used by the top container view.
    private func setupPositionWhilePan (sender: UIPanGestureRecognizer) {
        let translation = sender.translation (in: topViewControllerContainer)
        positon.x += translation.x
        positon.y += translation.y
        if sender.state == .ended {
            positon = .zero
        }
    }
    
    
    /// Controll al the paramaters to drag the top view horizontaly.
    ///
    /// - Parameter sender: UIPanGestureRecognizer used by the top view container.
    private func dragHorizontaly (sender: UIPanGestureRecognizer) {
        guard let topView = sender.view else {return}
        let velocity = sender.velocity(in: topView)
        
        if sender.state == .changed {
            viewState = .removing
            
            let xTranslation = sender.translation(in: topView).x
            applyHorizontalTranslationEffect(xTranslation: xTranslation)

        } else if sender.state == .ended {
            if !launchHorizontalAnimationIfNeeded(velocity: velocity) {
                self.animateToNearHorizonalState()
            }
        }
    }
    
    
    /// Apply the translation of the top view container with the given value.
    ///
    /// - Parameter xTranslation: the value of the translation to be applied.
    private func applyHorizontalTranslationEffect (xTranslation: CGFloat) {
        topViewControllerContainer.center.x += xTranslation/(1/customProperties.dragVelocity)
    }
    
    
    /// If the UIPanGestureRecongizer detect a high velocity an animation of the top view container will be performed.
    ///
    /// - Parameter velocity: the velocity detected by the gesture recongizer
    /// - Returns: a boolean that indicate if the animation its been performed.
    private func launchHorizontalAnimationIfNeeded (velocity: CGPoint) -> Bool {
        if velocity.x < -self.customProperties.launchVelocityNeeded {
            UIView.animate(withDuration: self.customProperties.animationDuration, animations: {
                self.setRemovePositions(side: .left)
            }, completion: { (_) in
                self.removeViews()
            })
            return true
        } else if velocity.x > self.customProperties.launchVelocityNeeded {
            UIView.animate(withDuration: self.customProperties.animationDuration, animations: {
                self.setRemovePositions(side: .right)
            }, completion: { (_) in
                self.removeViews()
            })
            return true
        }
        return false
    }
    
    
    /// Animate the containers to the near state due to the top container view horizontal position
    private func animateToNearHorizonalState () {
        UIView.animate(withDuration: self.customProperties.animationDuration, animations: {
            if self.topViewControllerContainer.frame.origin.x < self.view.frame.width/6 {
                self.setRemovePositions(side: .left)
            } else if self.topViewControllerContainer.frame.origin.x >= self.view.frame.width * (3/4) {
                self.setRemovePositions(side: .right)
            } else {
                self.setContainersFinalPositions()
                self.changeViewStateAsync(state: .bottom)
            }
        }) { (_) in
            if self.viewState == .undisplayed {
                self.removeViews()
            }
        }
    }
    
    
    /// Set the positions for the containers when they are going to be removed.
    ///
    /// - Parameter side: The side where they dissappear.
    private func setRemovePositions (side: HorizontalPosition) {
        if side == .none {
            return
        }
        
        if side == .left {
            topViewControllerContainer.frame.origin.x = -topViewControllerContainer.frame.width
        } else if side == .right {
            topViewControllerContainer.frame.origin.x = self.view.frame.width
        }
        self.changeViewStateAsync(state: .undisplayed)
    }
    
    
    /// Change the view state asynchronously.
    ///
    /// - Parameter state: the view state to be seted.
    private func changeViewStateAsync (state: ViewState) {
        DispatchQueue.main.async {
            self.viewState = state
        }
    }
    
    
    /// The parameters to be modified when the containers are going to be removed.
    private func removeViews () {
        topViewControllerContainer.removeFromSuperview()
        bottomViewControllerContainer.removeFromSuperview()
        topViewController.removeFromParentViewController()
        bottomViewController.removeFromParentViewController()
        topViewController = nil
        bottomViewController = nil
        self.changeViewStateAsync(state: .undisplayed)
    }
    
    
    /// If the UIPanGestureRecongizer detect a high velocity an animation of the top view container will be performed.
    ///
    /// - Parameter velocity: the velocity detected by the gesture recongizer
    /// - Returns: a boolean that indicate if the animation its been performed.
    private func launchVerticalAnimationIfNeeded (velocity: CGPoint) -> Bool{
        if velocity.y < -self.customProperties.launchVelocityNeeded {
            moveContainersToOrigin()
            return true
        } else if velocity.y > self.customProperties.launchVelocityNeeded {
            moveContainersToFinal()
            return true
        }
        return false
    }
    
    private func minimizeViews (sender: UIPanGestureRecognizer) {
        guard let topView = sender.view else {return}
        let velocity = sender.velocity(in: topView)
        
        if sender.state == .changed {
            let yTranslation = sender.translation(in: topViewControllerContainer).y
            let alphaFactor = calculateAlphaFactor(viewFrame: topView.frame)
            let scaleFactor = calculateScaleFactor(viewFrame: topView.frame)
            viewState = .scaling

            applyVerticalTranslationEffect(yTranslation: yTranslation, alphaFactor: alphaFactor, scaleFactor: scaleFactor)
            limitTopDraggingArea()
            limitBottomDraggingArea()
        } else if sender.state == .ended {
            if !launchVerticalAnimationIfNeeded(velocity: velocity) {
                animateToNearVerticalState()
            }
        }
    }
    
    
    /// Calculates the scale factor of a given frame according to the video ratio.
    ///
    /// - Parameter viewFrame: the frame used to calculate the factor
    /// - Returns: CGFloat representing the scale factor of the frame gived.
    private func calculateScaleFactor (viewFrame: CGRect) -> CGFloat {
        return normalizeHorizontalTranslation(viewFrame: viewFrame, minValue: customProperties.finalScaleFactor)
    }
    
    
    /// Calculate the alpha factor of the top view container according to its x position.
    ///
    /// - Returns: CGFloat representing the alphaFactor. Min value: 0.0. Max value: 1.0.
    private func calculateAlphaFactor (viewFrame: CGRect) -> CGFloat {
        return normalizeHorizontalTranslation(viewFrame: viewFrame, minValue: customProperties.finalAlphaFactor)
    }
    
    private func normalizeHorizontalTranslation (viewFrame: CGRect, minValue: CGFloat) -> CGFloat {
        var normalizedY: CGFloat = 1 - ((viewFrame.origin.y - customProperties.topMargin)/(self.view.frame.height - viewFrame.height - customProperties.bottomMargin))

        if normalizedY < minValue {
            normalizedY = minValue
        }
        
        return normalizedY
    }
    
    /// Modify all the paramaters needed to permorm the vertical translation of the containers views.
    ///
    /// - Parameters:
    ///   - yTranslation: y translation to be applied to the containers.
    ///   - alphaFactor: the alpha value of the bottom container view.
    ///   - scaleFactor: the scale value of the top container view.
    private func applyVerticalTranslationEffect (yTranslation: CGFloat, alphaFactor: CGFloat, scaleFactor: CGFloat) {
        topViewControllerContainer.transform = CGAffineTransform (scaleX: scaleFactor, y: scaleFactor)
        bottomViewControllerContainer.alpha = alphaFactor
        topViewControllerContainer.center.y += yTranslation * customProperties.dragVelocity
        bottomViewControllerContainer.center.y += (yTranslation * customProperties.dragVelocity)
    }
    
    /// Controll that the containers doesn't overcome the limits of the top-screen.
    private func limitTopDraggingArea () {
        if topViewControllerContainer.frame.origin.y <= customProperties.topMargin {
            setContainersInitialPositions()
        }
    }
    
    
    /// Controll that the containers doesn't overcome the limits of the bottom-screen.
    private func limitBottomDraggingArea () {
        if topViewControllerContainer.frame.origin.y + topViewControllerContainer.frame.height > self.view.frame.height - customProperties.bottomMargin {
            setContainersFinalPositions()
        }
    }
    
    
    /// Animate the views to the state near state.
    private func animateToNearVerticalState () {
        if self.topViewControllerContainer.frame.origin.y + self.topViewControllerContainer.frame.height/2 <= (self.view.frame.height - customProperties.bottomMargin) / 2 {
            moveContainersToOrigin()
        } else {
            moveContainersToFinal()
        }
    }
    
    
    /// Set all the parameters of the containers in the bottom state.
    private func setContainersFinalPositions () {
        self.topViewControllerContainer.transform = CGAffineTransform (scaleX: self.customProperties.finalScaleFactor, y: self.customProperties.finalScaleFactor)
        self.topViewControllerContainer.frame.origin.y = self.view.frame.height - self.topViewControllerContainer.frame.height - self.customProperties.bottomMargin
        self.bottomViewControllerContainer.frame.origin.y = self.view.frame.height + (self.view.frame.height - topViewControllerContainer.frame.height - self.bottomViewControllerContainer.frame.height - customProperties.bottomMargin)
        self.bottomViewControllerContainer.alpha = self.customProperties.finalAlphaFactor
        if let bottomXPosition = self.bottomXPosition {
            self.topViewControllerContainer.frame.origin.x = bottomXPosition
        } else {
            self.bottomXPosition = self.topViewControllerContainer.frame.origin.x
        }
        self.changeViewStateAsync(state: .bottom)
    }
    
    
    /// Set all the parameters of the containers in the top state.
    private func setContainersInitialPositions () {
        self.topViewControllerContainer.layer.anchorPoint = CGPoint (x: 0.94, y: 0)
        self.topViewControllerContainer.transform = CGAffineTransform.init(scaleX: 1, y: 1)
        self.topViewControllerContainer.frame.origin = CGPoint (x: 0, y: self.customProperties.topMargin)
        self.bottomViewControllerContainer.frame = CGRect (x: 0, y: self.customProperties.topMargin + self.topViewControllerContainer.frame.height, width: self.view.frame.width, height: self.view.frame.height - topViewControllerContainer.frame.height)
        self.bottomViewControllerContainer.alpha = 1.0
        changeViewStateAsync(state: .top)
    }
}
