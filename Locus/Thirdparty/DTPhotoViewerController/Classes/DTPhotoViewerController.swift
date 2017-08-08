//
//  DTPhotoViewerController.swift
//  DTPhotoViewerController
//
//  Created by Vo Duc Tung on 29/04/16.
//  Copyright © 2016 Vo Duc Tung. All rights reserved.
//

import UIKit
import FLAnimatedImage

private let kPhotoCollectionViewCellIdentifier = "Cell"

open class DTPhotoViewerController: UIViewController {
    
    /// Datasource
    /// Providing number of image items to controller and how to confiure image for each image view in it.
    public var dataSource: DTPhotoViewerControllerDataSource?
    
    /// Delegate
    public var delegate: DTPhotoViewerControllerDelegate?
    
    /// Indicates if status bar should be hidden after photo viewer controller is presented.
    /// Default value is true
    open var shouldHideStatusBarOnPresent = true
    
    /// Indicates status bar style when photo viewer controller is being presenting
    /// Default value if UIStatusBarStyle.default
    open var statusBarStyleOnPresenting: UIStatusBarStyle = UIStatusBarStyle.default
    
    /// Indicates status bar animation style when changing hidden status
    /// Default value if UIStatusBarStyle.fade
    open var statusBarAnimationStyle: UIStatusBarAnimation = UIStatusBarAnimation.fade
    
    /// Indicates status bar style after photo viewer controller is being dismissing
    /// Include when pan gesture recognizer is active.
    /// Default value if UIStatusBarStyle.LightContent
    open var statusBarStyleOnDismissing: UIStatusBarStyle = UIStatusBarStyle.lightContent
    
    /// Background color of the viewer.
    /// Default value is black.
    open var backgroundColor: UIColor = UIColor.black {
        didSet {
            backgroundView.backgroundColor = backgroundColor
        }
    }
    
    /// Indicates if referencedView should be shown or hidden automatically during presentation and dismissal.
    /// Setting automaticallyUpdateReferencedViewVisibility to false means you need to update isHidden property of this view by yourself.
    /// Setting automaticallyUpdateReferencedViewVisibility will also set referencedView isHidden property to false.
    /// Default value is true
    open var automaticallyUpdateReferencedViewVisibility = true {
        didSet {
            if !automaticallyUpdateReferencedViewVisibility {
                referencedView?.isHidden = false
            }
        }
    }
    
    /// Indicates where image should be scaled smaller when being dragged.
    /// Default value is true.
    open var scaleWhileDragging = true
    
    /// This variable sets original frame of image view to animate from
    open fileprivate(set) var referenceSize: CGSize = CGSize.zero
    
    
    /// This is the image view that is mainly used for the presentation and dismissal effect.
    /// How it animates from the original view to fullscreen and vice versa.
    public fileprivate(set) var imageView: FLAnimatedImageView
    
    /// The view where photo viewer originally animates from.
    /// Provide this correctly so that you can have a nice effect.
    public weak internal(set) var referencedView: UIView? {
        didSet {
            // Unhide old referenced view and hide the new one
            oldValue?.isHidden = false
            if automaticallyUpdateReferencedViewVisibility {
                referencedView?.isHidden = true
            }
        }
    }
    
    /// Collection view.
    /// This will be used when displaying multiple images.
    fileprivate(set) var collectionView: UICollectionView
    public var scrollView: UIScrollView {
        return collectionView
    }
    
    /// View that has fading effect during presentation and dismissal animation or when controller is being dragged.
    public fileprivate(set) var backgroundView: UIView
    
    /// Pan gesture for dragging controller
    var panGestureRecognizer: UIPanGestureRecognizer!
    
    /// Double tap gesture
    var doubleTapGestureRecognizer: UITapGestureRecognizer!
    
    /// Single tap gesture
    var singleTapGestureRecognizer: UITapGestureRecognizer!
    
    //Dismiss Button
    var btnDismiss: UIButton!
    
    //Powered By GIPHY
    var lblPoweredBy: UILabel!
    var imageViewPoweredBy: UIImageView!
    
    fileprivate var _shouldHideStatusBar = false
    fileprivate var _defaultStatusBarStyle = false
    
    /// Transition animator
    /// Customizable if you wish to provide your own transitions.
    open lazy var animator: DTPhotoViewerBaseAnimator = DTPhotoAnimator()
    
    public init?(referencedView: UIView?, image: UIImage?, gifURL: String) {
        if let newImage = image {
            let flowLayout = DTCollectionViewFlowLayout()
            flowLayout.scrollDirection = .horizontal
            flowLayout.sectionInset = UIEdgeInsets.zero
            flowLayout.minimumLineSpacing = 0
            flowLayout.minimumInteritemSpacing = 0
            
            // Collection view
            collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
            collectionView.register(DTPhotoCollectionViewCell.self, forCellWithReuseIdentifier: kPhotoCollectionViewCellIdentifier)
            collectionView.backgroundColor = UIColor.clear
            collectionView.isPagingEnabled = true
            
            backgroundView = UIView(frame: CGRect.zero)
            
            // Image view
            //let newImageView = FLAnimatedImageView(frame: CGRect.zero)//DTImageView(frame: CGRect.zero)
            //imageView = newImageView
            
            imageView = FLAnimatedImageView(frame: CGRect.zero)
            
            super.init(nibName: nil, bundle: nil)
            
            transitioningDelegate = self
            
            imageView.image = newImage
            self.referencedView = referencedView
            collectionView.dataSource = self
            
            //Load Image from URL
            self.loadGIFForURL(strURL: gifURL)
            
            
            modalPresentationStyle = UIModalPresentationStyle.overFullScreen
            modalPresentationCapturesStatusBarAppearance = true
        }
        else {
            return nil
        }
    }
    
    func loadGIFForURL(strURL: String) -> Void {
        let arrayURLString = strURL.components(separatedBy: "/")
        let strKey  = arrayURLString[arrayURLString.count - 2]
        let strName = arrayURLString.last
        
        //let strImageName = (strURL as NSString).lastPathComponent
        let strImageName = strKey + "_" + strName!
        let imagePath = Constants.Directory_GIF_Path.appending(strImageName)
        
        
        if FileManager().fileExists(atPath: imagePath) {
            print("Exist at path : \(imagePath)")
            
            let data = NSData(contentsOfFile: imagePath)
            let image = FLAnimatedImage(animatedGIFData: data as Data!)
            imageView.animatedImage = image
        }else {
            
            let url = URL(string: strURL)
            DispatchQueue.global(qos: .background).async {
                //Background
                let data = NSData(contentsOf: url!)
                DispatchQueue.main.async {
                    //Write GIF to Directory
                    do {
                        let fileURL = URL(fileURLWithPath: imagePath)
                        try data?.write(to: fileURL, options: .atomic)
                    }catch {
                        print(error)
                    }
                    
                    //Main Thread
                    let image = FLAnimatedImage(animatedGIFData: data as Data!)
                    self.imageView.animatedImage = image
                }
            }
        }
    }
    
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: - View Life Cycle
    override open func viewDidLoad() {
        if let view = referencedView {
            // Content mode should be identical between image view and reference view
            imageView.contentMode = view.contentMode
        }
        
        //Background view
        view.addSubview(backgroundView)
        backgroundView.alpha = 0
        backgroundView.backgroundColor = self.backgroundColor
        
        //Image view
        // Configure this block for changing image size when image changed
        (imageView as? DTImageView)?.imageChangeBlock = {[weak self](image: UIImage?) -> Void in
            // Update image frame whenever image changes and when the imageView is not being visible
            // imageView is only being visible during presentation or dismissal
            // For that reason, we should not update frame of imageView no matter what.
            if let strongSelf = self, let image = image, strongSelf.imageView.isHidden == true {
                strongSelf.imageView.frame.size = strongSelf.imageViewSizeForImage(image: image)
                strongSelf.imageView.center = strongSelf.view.center
                
                // No datasource, only 1 item in collection view --> reloadData
                guard let _ = strongSelf.dataSource else {
                    strongSelf.collectionView.reloadData()
                    return
                }
            }
        }
        
        imageView.frame = _frameForReferencedView()
        imageView.clipsToBounds = true
        
        //Scroll view
        scrollView.delegate = self
        view.addSubview(imageView)
        view.addSubview(scrollView)
        
        //Tap gesture recognizer
        singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(_handleTapGesture))
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.numberOfTouchesRequired = 1
        
        //Pan gesture recognizer
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(_handlePanGesture))
        panGestureRecognizer.maximumNumberOfTouches = 1
        self.view.isUserInteractionEnabled = true
        
        //Double tap gesture recognizer
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(_handleDoubleTapGesture))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.numberOfTouchesRequired = 1
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        
        scrollView.addGestureRecognizer(doubleTapGestureRecognizer)
        scrollView.addGestureRecognizer(singleTapGestureRecognizer)
        self.view.addGestureRecognizer(panGestureRecognizer)
        
        super.viewDidLoad()
        
        //Dismiss button
        btnDismiss = UIButton(frame: CGRect(x: self.view.frame.size.width - 50, y: 25, width: 40, height: 40))
        btnDismiss.backgroundColor = UIColor.clear
        btnDismiss.setImage(UIImage(named: "CloseWhite"), for: .normal)
        btnDismiss.addTarget(self, action: #selector(_dismiss), for: .touchUpInside)
        self.view.addSubview(btnDismiss)
        
        
        //Power By GIPHY
        lblPoweredBy = UILabel(frame: CGRect(x: 0, y: self.view.frame.size.height - 40, width: self.view.frame.size.width - 15, height: 40))
        lblPoweredBy.backgroundColor = UIColor.clear
        lblPoweredBy.textColor = UIColor.lightGray
        lblPoweredBy.text = "Powered by GIPHY"
        lblPoweredBy.font = UIFont(name: Constants.Fonts.Roboto_Medium, size: 13.0)
        lblPoweredBy.textAlignment = .right
        //self.view.addSubview(lblPoweredBy)
        
        imageViewPoweredBy = UIImageView(frame: CGRect(x: 0, y: self.view.frame.size.height - 35, width: self.view.frame.size.width, height: 25))
        imageViewPoweredBy.image = UIImage(named: "powered_by_giphy")
        imageViewPoweredBy.contentMode = .scaleAspectFit
        imageViewPoweredBy.clipsToBounds = true
        self.view.addSubview(imageViewPoweredBy)
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        backgroundView.frame = self.view.bounds
        scrollView.frame = self.view.bounds
        
        // Update iamge view frame everytime view changes frame
        (imageView as? DTImageView)?.imageChangeBlock?(imageView.image)
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Update layout
        (collectionView.collectionViewLayout as? DTCollectionViewFlowLayout)?.currentIndex = currentPhotoIndex
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
       
        if !animated {
            self.presentingAnimation()
            self.presentationAnimationDidFinish()
        }
        else {
            self.presentationAnimationWillStart()
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !animated {
            self.dismissingAnimation()
            self.dismissalAnimationDidFinish()
        }
        else {
            self.dismissalAnimationWillStart()
            
        }
    }
    
    open override var prefersStatusBarHidden : Bool {
        if shouldHideStatusBarOnPresent {
            return _shouldHideStatusBar
        }
        return false
    }
    
    open override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return statusBarAnimationStyle
    }
    
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        if _defaultStatusBarStyle {
            return statusBarStyleOnPresenting
        }
        return statusBarStyleOnDismissing
    }
    
    //MARK: Private methods
    fileprivate func startAnimation() {
        //Hide reference image view
        if automaticallyUpdateReferencedViewVisibility {
            referencedView?.isHidden = true
        }
        
        //Animate to center
        _animateToCenter()
    }
    
    func _animateToCenter() {
        UIView.animate(withDuration: animator.presentingDuration, animations: {
            self.presentingAnimation()
        }) { (finished) in
            // Presenting animation ended
            self.presentationAnimationDidFinish()
        }
    }
    
    func _hideImageView(_ imageViewHidden: Bool) {
        // Hide image view should show collection view and vice versa
        imageView.isHidden = imageViewHidden
        scrollView.isHidden = !imageViewHidden
    }
    
    func _dismiss() {
        self.btnDismiss.alpha = 0.0
        self.imageViewPoweredBy.alpha = 0.0
        self.dismiss(animated: true, completion: nil)
    }
    
    func _handleTapGesture(_ gesture: UITapGestureRecognizer) {
        // Method to override
        didReceiveTapGesture()
        
        // Delegate method
        delegate?.photoViewerControllerDidReceiveTapGesture?(self)
    }
    
    func _handleDoubleTapGesture(_ gesture: UITapGestureRecognizer) {
        // Method to override
        didReceiveDoubleTapGesture()
        
        // Delegate method
        delegate?.photoViewerControllerDidReceiveDoubleTapGesture?(self)
        
        let index = Int(scrollView.contentOffset.x / scrollView.bounds.size.width)
        let indexPath = IndexPath(item: index, section: 0)
        
        if let cell = collectionView.cellForItem(at: indexPath) as? DTPhotoCollectionViewCell {
            // Double tap
            // self.imageViewerControllerDidDoubleTapImageView()
            
            if (cell.scrollView.zoomScale == cell.scrollView.maximumZoomScale) {
                // Zoom out
                cell.scrollView.minimumZoomScale = 1.0
                cell.scrollView.setZoomScale(cell.scrollView.minimumZoomScale, animated: true)
                
            } else {
                let location = gesture.location(in: view)
                let center = cell.imageView.convert(location, from: view)
                
                // Zoom in
                cell.scrollView.minimumZoomScale = 1.0
                let rect = zoomRect(for: cell.imageView, withScale: cell.scrollView.maximumZoomScale, withCenter: center)
                cell.scrollView.zoom(to: rect, animated: true)
            }
        }
    }
    
    func _frameForReferencedView() -> CGRect {
        if let view = referencedView {
            if let superview = view.superview {
                var frame = (superview.convert(view.frame, to: self.view))
                referenceSize = frame.size
                
                if abs(frame.size.width - view.frame.size.width) > 1 {
                    // This is workaround for bug in ios 8, everything is double.
                    frame = CGRect(x: frame.origin.x/2, y: frame.origin.y/2, width: frame.size.width/2, height: frame.size.height/2)
                    referenceSize = frame.size
                }
                
                return frame
            }
        }
        
        // Work around when there is no reference view, dragging might behave oddly
        // Should be fixed in the future
        let defaultSize: CGFloat = 1
        referenceSize = CGSize(width: defaultSize, height: defaultSize)
        return CGRect(x: self.view.frame.midX - defaultSize/2, y: self.view.frame.midY - defaultSize/2, width: defaultSize, height: defaultSize)
    }
    
    // Update zoom inside UICollectionViewCell
    fileprivate func _updateZoomScaleForSize(cell: DTPhotoCollectionViewCell, size: CGSize) {
        let widthScale = size.width / cell.imageView.bounds.width
        let heightScale = size.height / cell.imageView.bounds.height
        let zoomScale = min(widthScale, heightScale)
        
        cell.scrollView.maximumZoomScale = zoomScale
    }
    
    fileprivate func zoomRect(for imageView: UIImageView, withScale scale: CGFloat, withCenter center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        
        // The zoom rect is in the content view's coordinates.
        // At a zoom scale of 1.0, it would be the size of the
        // imageScrollView's bounds.
        // As the zoom scale decreases, so more content is visible,
        // the size of the rect grows.
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        
        // choose an origin so as to get the right center.
        zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
        
        return zoomRect
    }
    
    func _handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        if let view = gesture.view {
            switch gesture.state {
            case .began:
                //Make status bar visible when beginning to drag image view
                _shouldHideStatusBar = false
                _defaultStatusBarStyle = false
                
                setNeedsStatusBarAppearanceUpdate()
                
                // Hide collection view & display image view
                _hideImageView(false)
                
                // Method to override
                willBegin(panGestureRecognizer: panGestureRecognizer)
                
                // Delegate method
                delegate?.photoViewerController?(self, willBeginPanGestureRecognizer: panGestureRecognizer)
                
            case .changed:
                let translation = gesture.translation(in: view)
                self.imageView.center = CGPoint(x: self.view.center.x + translation.x, y: self.view.center.y + translation.y)
                
                //Change opacity of background view based on vertical distance from center
                let yDistance = CGFloat(abs(self.imageView.center.y - self.view.center.y))
                let alpha = 1.0 - yDistance/(self.view.center.y)
                self.backgroundView.alpha = alpha
                self.btnDismiss.alpha = 0.0
                self.imageViewPoweredBy.alpha = 0.0
                
                //Scale image
                //Should not go smaller than max ratio
                if scaleWhileDragging {
                    let ratio = max(referenceSize.height/imageView.frame.height, referenceSize.width/imageView.frame.width)
                    
                    //If alpha = 0, then scale is max ratio, if alpha = 1, then scale is 1
                    let scale = 1 + (1 - alpha)*(ratio - 1)
                    
                    //imageView.transform = CGAffineTransformMakeScale(scale, scale)
                    // Do not use transform to scale down image view
                    // Instead change width & height
                    if scale < 1 && scale >= ratio {
                        let size = imageViewSizeForImage(image: imageView.image)
                        imageView.frame.size = CGSize(width: size.width * scale, height: size.height * scale)
                    }
                }
                
            default:
                //Animate back to center
                if self.backgroundView.alpha < 0.8 {
                    _dismiss()
                }
                else {
                    _animateToCenter()
                    self.btnDismiss.alpha = 1.0
                    self.imageViewPoweredBy.alpha = 1.0
                }
                
                // Method to override
                didEnd(panGestureRecognizer: panGestureRecognizer)
                
                // Delegate method
                delegate?.photoViewerController?(self, didEndPanGestureRecognizer: panGestureRecognizer)
            }
        }
    }
    
    private func imageViewSizeForImage(image: UIImage?) -> CGSize {
        if let image = image {
            let size = image.size
            var destinationSize = CGSize.zero
            
            // Calculate size of image view so that it would fit in self.view
            // This will make the transition more perfect than setting frame of UIImageView as self.view.bounds
            if image.size.width/image.size.height > view.frame.size.width/view.frame.size.height {
                destinationSize.width = view.frame.size.width
                destinationSize.height = view.frame.size.width * (size.height / size.width)
            }
            else {
                destinationSize.height = view.frame.size.height
                destinationSize.width = view.frame.size.height * (size.width / size.height)
            }
            
            print("\(view.frame)\n")
            
            return destinationSize
        }
        
        return CGSize.zero
    }
    
    func presentingAnimation() {
        //Hide reference view
        if automaticallyUpdateReferencedViewVisibility {
            referencedView?.isHidden = true
        }
        
        //Calculate final frame
        var destinationFrame = CGRect.zero
        destinationFrame.size = imageViewSizeForImage(image: imageView.image)
        
        //Animate image view to the center
        self.imageView.frame = destinationFrame
        self.imageView.center = self.view.center
        
        //Change status bar to black style
        self._defaultStatusBarStyle = true
        self._shouldHideStatusBar = true
        self.setNeedsStatusBarAppearanceUpdate()
        
        //Animate background alpha
        self.backgroundView.alpha = 1.0
    }
    
    func dismissingAnimation() {
        self.imageView.frame = _frameForReferencedView()
        self.backgroundView.alpha = 0
    }
    
    func presentationAnimationDidFinish() {
        
        //Commeneted by Mehul on 27 Feb 2017
        /*
        // Method to override
        didEndPresentingAnimation()
        
        // Delegate method
        self.delegate?.photoViewerControllerDidEndPresentingAnimation?(self)
        
        // Hide animating image view and show collection view
        _hideImageView(true)
        */
    }
    
    func presentationAnimationWillStart() {
        // Hide collection view and show image view
        _hideImageView(false)
    }
    
    func dismissalAnimationWillStart() {
        // Hide collection view and show image view
        _hideImageView(false)
    }
    
    func dismissalAnimationDidFinish() {
        if automaticallyUpdateReferencedViewVisibility {
            referencedView?.isHidden = false
        }
    }
}

//MARK: - UIViewControllerTransitioningDelegate
extension DTPhotoViewerController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animator
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animator
    }
}

//MARK: UICollectionViewDataSource
extension DTPhotoViewerController: UICollectionViewDataSource {
    //MARK: Public methods
    public var currentPhotoIndex: Int {
        if scrollView.frame.width == 0 {
            return 0
        }
        return Int(scrollView.contentOffset.x / scrollView.frame.width)
    }
    
    public var zoomScale: CGFloat {
        let index = currentPhotoIndex
        let indexPath = IndexPath(item: index, section: 0)
        
        if let cell = collectionView.cellForItem(at: indexPath) as? DTPhotoCollectionViewCell {
            return cell.scrollView.zoomScale
        }
        
        return 1.0
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let dataSource = dataSource {
            let count = dataSource.numberOfItems(in: self)
            return count > 0 ? count : 1
        }
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kPhotoCollectionViewCellIdentifier, for: indexPath) as! DTPhotoCollectionViewCell
        cell.delegate = self
        
        if let dataSource = dataSource {
            if dataSource.numberOfItems(in: self) > 0 {
                dataSource.photoViewerController(self, configurePhotoAt: indexPath.row, withImageView: cell.imageView)
                dataSource.photoViewerController?(self, configureCell: cell, forPhotoAt: indexPath.row)
                
                return cell
            }
        }
        
        cell.imageView.image = imageView.image
        return cell
    }
}

//MARK: Public data methods
extension DTPhotoViewerController {
    // For each reuse identifier that the collection view will use, register either a class or a nib from which to instantiate a cell.
    // If a nib is registered, it must contain exactly 1 top level object which is a DTPhotoCollectionViewCell.
    // If a class is registered, it will be instantiated via alloc/initWithFrame:
    open func registerClassPhotoViewer(_ cellClass: Swift.AnyClass?) {
        collectionView.register(cellClass, forCellWithReuseIdentifier: kPhotoCollectionViewCellIdentifier)
    }
    
    open func registerNibForPhotoViewer(_ nib: UINib?) {
        collectionView.register(nib, forCellWithReuseIdentifier: kPhotoCollectionViewCellIdentifier)
    }
    
    // Update data before calling theses methods
    open func reloadData() {
        collectionView.reloadData()
    }
    
    open func insertPhotos(at indexes: [Int], completion: ((Bool) -> Void)?) {
        let indexPaths = indexPathsForIndexes(indexes: indexes)
        
        collectionView.performBatchUpdates({
            self.collectionView.insertItems(at: indexPaths)
        }, completion: completion)
    }
    
    open func deletePhotos(at indexes: [Int], completion: ((Bool) -> Void)?) {
        let indexPaths = indexPathsForIndexes(indexes: indexes)
        
        collectionView.performBatchUpdates({
            self.collectionView.deleteItems(at: indexPaths)
        }, completion: completion)
    }
    
    open func reloadPhotos(at indexes: [Int]) {
        let indexPaths = indexPathsForIndexes(indexes: indexes)
        
        collectionView.reloadItems(at: indexPaths)
    }
    
    open func movePhoto(at index: Int, to newIndex: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        let newIndexPath = IndexPath(item: newIndex, section: 0)
        
        collectionView.moveItem(at: indexPath, to: newIndexPath)
    }
    
    open func scrollToPhoto(at index: Int, animated: Bool) {
        if self.collectionView.numberOfItems(inSection: 0) > index {
            let indexPath = IndexPath(item: index, section: 0)
            collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.right, animated: animated)
            
            if !animated {
                // Update image view's image as current collection view image
                updateImageView(scrollView: scrollView)
                
                // Need to call these methods since scrollView delegate method won't be called when not animated
                // Method to override
                didScrollToPhoto(at: index)
                
                // Call delegate
                delegate?.photoViewerController?(self, didScrollToPhotoAt: index)
            }
        }
    }
    
    // Helper for indexpaths
    func indexPathsForIndexes(indexes: [Int]) -> [IndexPath] {
        return indexes.map() {
            IndexPath(item: $0, section: 0)
        }
    }
}

//MARK: Public behavior methods
extension DTPhotoViewerController {
    open func didScrollToPhoto(at index: Int) {
        
    }
    
    open func didZoomOnPhoto(at index: Int, atScale scale: CGFloat) {
        
    }
    
    open func didEndZoomingOnPhoto(at index: Int, atScale scale: CGFloat) {
        
    }
    
    open func willZoomOnPhoto(at index: Int) {
        
    }
    
    open func didReceiveTapGesture() {
        
    }
    
    open func didReceiveDoubleTapGesture() {
        
    }
    
    open func willBegin(panGestureRecognizer gestureRecognizer: UIPanGestureRecognizer) {
        
    }
    
    open func didEnd(panGestureRecognizer gestureRecognizer: UIPanGestureRecognizer) {
        
    }
    
    open func didEndPresentingAnimation() {
        
    }
}

//MARK: DTPhotoCollectionViewCellDelegate
extension DTPhotoViewerController: DTPhotoCollectionViewCellDelegate {
    public func collectionViewCellDidZoomOnPhoto(_ cell: DTPhotoCollectionViewCell, atScale scale: CGFloat) {
        if let indexPath = collectionView.indexPath(for: cell) {
            // Method to override
            didZoomOnPhoto(at: indexPath.row, atScale: scale)
            
            // Call delegate
            delegate?.photoViewerController?(self, didZoomOnPhotoAtIndex: indexPath.row, atScale: scale)
        }
    }
    
    public func collectionViewCellDidEndZoomingOnPhoto(_ cell: DTPhotoCollectionViewCell, atScale scale: CGFloat) {
        if let indexPath = collectionView.indexPath(for: cell) {
            // Method to override
            didEndZoomingOnPhoto(at: indexPath.row, atScale: scale)
            
            // Call delegate
            delegate?.photoViewerController?(self, didEndZoomingOnPhotoAtIndex: indexPath.row, atScale: scale)
        }
    }
    
    public func collectionViewCellWillZoomOnPhoto(_ cell: DTPhotoCollectionViewCell) {
        if let indexPath = collectionView.indexPath(for: cell) {
            // Method to override
            willZoomOnPhoto(at: indexPath.row)
            
            // Call delegate
            delegate?.photoViewerController?(self, willZoomOnPhotoAtIndex: indexPath.row)
        }
    }
}
