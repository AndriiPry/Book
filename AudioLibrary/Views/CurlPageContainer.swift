//
//  CurlPageContainer.swift
//  AudioLibrary
//
//  Created by Oleksii on 19.08.2025.
//

import UIKit
import SwiftUI
import AVFAudio

final class CurlPagesViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var pageController: UIPageViewController!
    private(set) var pages: [Page]
    private var controllers: [UIViewController] = []

    private var arrowLeftButton: UIButton!
    private var arrowRightButton: UIButton!

    // Audio properties
    private var audioPlayer: AVAudioPlayer?
    private var audioDelegate: AudioPlayerDelegate?
    
    // Image loading properties
    private var pagesImages: [Int: Image] = [:]
    private var loadedPageImages: Set<Int> = []
    private var isLoadingImages: Set<Int> = []
    
    private enum Constants {
        static let preloadRange: Int = 2
        static let animationDuration: TimeInterval = 0.8
    }
    
    // Bindings to SwiftUI
    var onIndexChange: ((Int) -> Void)?
    var onAudioModeChange: ((Bool) -> Void)?
    var onAudioPausedChange: ((Bool) -> Void)?
    var onAudioPlayingChange: ((Bool) -> Void)?

    private(set) var currentIndex: Int = 0 {
        didSet {
            if oldValue != currentIndex {
                onIndexChange?(currentIndex)
                updateArrowButtons()
                loadImagesForCurrentPage()
                handlePageChange()
            }
        }
    }
    
    private var isAudioMode: Bool = false {
        didSet {
            onAudioModeChange?(isAudioMode)
            if isAudioMode {
                playCurrentPageAudio()
            } else {
                stopAudio()
            }
        }
    }
    
    private var isAudioPaused: Bool = false {
        didSet {
            onAudioPausedChange?(isAudioPaused)
        }
    }
    
    private var isAudioPlaying: Bool = false {
        didSet {
            onAudioPlayingChange?(isAudioPlaying)
        }
    }

    init(pages: [Page], initialIndex: Int = 0) {
        self.pages = pages
        self.currentIndex = min(max(0, initialIndex), max(0, pages.count - 1))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageController()
        setupArrowButtons()
        rebuildControllers()
        setIndex(currentIndex, animated: false)
        loadImagesForCurrentPage()
    }

    private func setupPageController() {
        pageController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: nil
        )
        pageController.dataSource = self
        pageController.delegate = self

        addChild(pageController)
        view.addSubview(pageController.view)
        pageController.didMove(toParent: self)
        pageController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupArrowButtons() {
        arrowLeftButton = createArrowButton(systemName: "chevron.left", action: #selector(didTapPrevious))
        arrowRightButton = createArrowButton(systemName: "chevron.right", action: #selector(didTapNext))

        view.addSubview(arrowLeftButton)
        view.addSubview(arrowRightButton)

        arrowLeftButton.translatesAutoresizingMaskIntoConstraints = false
        arrowRightButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            arrowLeftButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            arrowLeftButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            arrowRightButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            arrowRightButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        updateArrowButtons()
    }

    private func createArrowButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        
        let config = UIImage.SymbolConfiguration(pointSize: 35, weight: .semibold)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        
        button.tintColor = .white
        button.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
        button.layer.cornerRadius = 40
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        button.addTarget(self, action: action, for: .touchUpInside)
        
        button.widthAnchor.constraint(equalToConstant: 80).isActive = true
        button.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        return button
    }

    private func updateArrowButtons() {
        arrowLeftButton.isEnabled = currentIndex > 0
        arrowLeftButton.alpha = currentIndex > 0 ? 1.0 : 0.3
        arrowRightButton.isEnabled = currentIndex < pages.count - 1
        arrowRightButton.alpha = currentIndex < pages.count - 1 ? 1.0 : 0.3
    }

    @objc public func didTapPrevious() { goToPreviousPage() }
    @objc public func didTapNext() { goToNextPage() }

    private func rebuildControllers() {
        controllers = pages.map { page in
            UIHostingController(
                rootView: GeometryReader { geometry in
                    PageView(
                        page: page,
                        geometry: geometry,
                        offset: 0,
                        img: self.imageForPage(page.pageNumber)
                    )
                }
            )
        }
    }

    func updatePages(_ newPages: [Page]) {
        pages = newPages
        let oldIndex = currentIndex
        rebuildControllers()
        currentIndex = min(max(0, oldIndex), max(0, pages.count - 1))
        setIndex(currentIndex, animated: false)
    }

    func setIndex(_ index: Int, animated: Bool) {
        guard controllers.indices.contains(index) else { return }
        let direction: UIPageViewController.NavigationDirection = index >= currentIndex ? .forward : .reverse
        currentIndex = index
        pageController.setViewControllers([controllers[index]], direction: direction, animated: animated)
    }

    func goToNextPage() {
        let next = currentIndex + 1
        guard controllers.indices.contains(next) else { return }
        handlePageTransition {
            setIndex(next, animated: true)
        }
    }

    func goToPreviousPage() {
        let prev = currentIndex - 1
        guard controllers.indices.contains(prev) else { return }
        handlePageTransition {
            setIndex(prev, animated: true)
        }
    }
    
    // MARK: - Audio Functions
    
    public func toggleReadingMode() {
        isAudioMode.toggle()
        isAudioPaused = false // Reset paused state when toggling mode
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            if self?.isAudioMode == true {
                self?.playCurrentPageAudio()
            } else {
                self?.stopAudio()
            }
        }
    }
    
    public func toggleAudioPlayback() {
        guard isAudioMode, let player = audioPlayer else { return }
        
        if isAudioPaused {
            player.play()
            isAudioPaused = false
            isAudioPlaying = true
        } else {
            player.pause()
            isAudioPaused = true
            isAudioPlaying = false
        }
    }
    
    private func playCurrentPageAudio() {
        guard isAudioMode,
              currentIndex < pages.count,
              let audioPath = pages[currentIndex].audioPath,
              let audioURL = getAudio(at: audioPath) else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: audioURL)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.audioPlayer = player
                self.setupAudioDelegate()
                
                if !self.isAudioPaused {
                    player.play()
                    self.isAudioPlaying = true
                } else {
                    player.prepareToPlay()
                    self.isAudioPlaying = false
                }
            }
        } catch {
            print("Error playing audio: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.isAudioPlaying = false
            }
        }
    }
    
    private func setupAudioDelegate() {
        audioDelegate = AudioPlayerDelegate(
            onAudioFinished: handleAudioFinished,
            onAudioStarted: handleAudioStarted
        )
        audioPlayer?.delegate = audioDelegate
    }
    
    private func stopAudio() {
        DispatchQueue.main.async { [weak self] in
            self?.audioPlayer?.stop()
            self?.audioPlayer = nil
            self?.audioDelegate = nil
            self?.isAudioPlaying = false
            self?.isAudioPaused = false
        }
    }
    
    private func handleAudioFinished() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isAudioPlaying = false
            
            if self.currentIndex < self.pages.count - 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.goToNextPage()
                }
            } else {
                // Last page - exit audio mode
                DispatchQueue.global(qos: .userInteractive).async {
                    self.stopAudio()
                }
                self.isAudioMode = false
            }
        }
    }
    
    private func handleAudioStarted() {
        DispatchQueue.main.async { [weak self] in
            self?.isAudioPlaying = true
        }
    }
    
    private func handlePageTransition(_ updateIndex: () -> Void) {
        if isAudioMode && isAudioPlaying {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                self?.stopAudio()
            }
        }
        
        updateIndex()
        
        if isAudioMode {
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 1.1) { [weak self] in
                self?.playCurrentPageAudio()
            }
        }
    }
    
    private func handlePageChange() {
        if isAudioMode {
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 1.1) { [weak self] in
                self?.playCurrentPageAudio()
            }
        }
    }
    
    // MARK: - Image Loading Functions
    
    private func loadImagesForCurrentPage() {
        let range = getPageLoadRange()
        
        for i in range.startIndex...range.endIndex {
            if i < pages.count {
                loadImageForPageIfNeeded(pages[i].pageNumber)
            }
        }
        
        cleanupDistantImages()
    }
    
    private func imageForPage(_ pageNumber: Int) -> Image? {
        return pagesImages[pageNumber]
    }
    
    private func getPageLoadRange() -> (startIndex: Int, endIndex: Int) {
        let startIndex = max(0, currentIndex - Constants.preloadRange)
        let endIndex = min(pages.count - 1, currentIndex + Constants.preloadRange)
        return (startIndex, endIndex)
    }
    
    private func loadImageForPageIfNeeded(_ pageNumber: Int) {
        guard !loadedPageImages.contains(pageNumber),
              !isLoadingImages.contains(pageNumber),
              let page = pages.first(where: { $0.pageNumber == pageNumber }),
              let imagePath = page.bgImagePath else { return }
        
        isLoadingImages.insert(pageNumber)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let image = self.getImage(at: imagePath)
            
            DispatchQueue.main.async {
                self.isLoadingImages.remove(pageNumber)
                
                if let image = image {
                    self.pagesImages[pageNumber] = Image(uiImage: image)
                    self.loadedPageImages.insert(pageNumber)
                    // Trigger UI update for the affected controllers
                    self.updateControllerForPage(pageNumber)
                }
            }
        }
    }
    
    private func updateControllerForPage(_ pageNumber: Int) {
        // Find and update the specific controller that needs the new image
        guard let pageIndex = pages.firstIndex(where: { $0.pageNumber == pageNumber }),
              controllers.indices.contains(pageIndex) else { return }
        
        let page = pages[pageIndex]
        controllers[pageIndex] = UIHostingController(
            rootView: GeometryReader { geometry in
                PageView(
                    page: page,
                    geometry: geometry,
                    offset: 0,
                    img: self.imageForPage(page.pageNumber)
                )
            }
        )
        
        // Refresh the current page if it's the one that was updated
        if pageIndex == currentIndex {
            pageController.setViewControllers([controllers[pageIndex]], direction: .forward, animated: false)
        }
    }
    
    private func cleanupDistantImages() {
        let keepRange = Constants.preloadRange * 2
        let startKeep = max(0, currentIndex - keepRange)
        let endKeep = min(pages.count - 1, currentIndex + keepRange)
        
        let pagesToRemove = loadedPageImages.filter { pageNumber in
            guard let pageIndex = pages.firstIndex(where: { $0.pageNumber == pageNumber }) else { return true }
            return pageIndex < startKeep || pageIndex > endKeep
        }
        
        pagesToRemove.forEach { pageNumber in
            pagesImages.removeValue(forKey: pageNumber)
            loadedPageImages.remove(pageNumber)
        }
    }
    
    // MARK: - Helper Functions
    
    private func getAudio(at path: String) -> URL? {
        URL(fileURLWithPath: path)
    }
    
    private func getImage(at path: String) -> UIImage? {
        guard FileManager.default.fileExists(atPath: path) else {
            print("Image not found at path: \(path)")
            return nil
        }
        return UIImage(contentsOfFile: path)
    }

    // MARK: - UIPageViewController DataSource & Delegate
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let idx = controllers.firstIndex(of: viewController), idx > 0 else { return nil }
        return controllers[idx - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let idx = controllers.firstIndex(of: viewController), idx < controllers.count - 1 else { return nil }
        return controllers[idx + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
              let visible = pageViewController.viewControllers?.first,
              let idx = controllers.firstIndex(of: visible)
        else { return }
        currentIndex = idx
    }
}

struct CurlPageContainer: UIViewControllerRepresentable {
    @Binding var pages: [Page]
    @Binding var currentIndex: Int
    @Binding var isAudioMode: Bool
    @Binding var isAudioPaused: Bool
    @Binding var isAudioPlaying: Bool

    final class Coordinator {
            weak var controller: CurlPagesViewController?
        }
        
    let coordinator = Coordinator()

    func makeCoordinator() -> Coordinator { coordinator }

    func makeUIViewController(context: Context) -> CurlPagesViewController {
        let vc = CurlPagesViewController(pages: pages, initialIndex: currentIndex)

        vc.onIndexChange = { newIndex in
            if currentIndex != newIndex {
                DispatchQueue.main.async { self.currentIndex = newIndex }
            }
        }
        
        vc.onAudioModeChange = { newAudioMode in
            if isAudioMode != newAudioMode {
                DispatchQueue.main.async { self.isAudioMode = newAudioMode }
            }
        }
        
        vc.onAudioPausedChange = { newAudioPaused in
            if isAudioPaused != newAudioPaused {
                DispatchQueue.main.async { self.isAudioPaused = newAudioPaused }
            }
        }
        
        vc.onAudioPlayingChange = { newAudioPlaying in
            if isAudioPlaying != newAudioPlaying {
                DispatchQueue.main.async { self.isAudioPlaying = newAudioPlaying }
            }
        }

        context.coordinator.controller = vc
        return vc
    }

    func updateUIViewController(_ uiViewController: CurlPagesViewController, context: Context) {
        if pages.count != uiViewController.pages.count ||
           !zip(pages, uiViewController.pages).allSatisfy({ $0.pageNumber == $1.pageNumber }) {
            uiViewController.updatePages(pages)
        }

        if uiViewController.currentIndex != currentIndex {
            uiViewController.setIndex(currentIndex, animated: false)
        }
    }
}

