//
//  ViewController.swift
//  AID
//
//  Created by Alexandr Sokolov on 19.03.2024.
//

import UIKit
import SwiftUI
import SnapKit

protocol MainViewControllerProtocol: AnyObject {
    func setContent(pagesInfo: [PageInfo])
    func pushCompanyDetailsViewController(companyName: String)
}

final class MainViewController: UIViewController {

    private let pageViewFactory = PageViewFactory()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var currentViewIndex: Int = 0
    private var initialPosition: CGPoint = .zero
    private var swipeableViews: [PageViewBlank] = []

    var presenter: MainScreenPresenterProtocol?

    // Заглушка для PageView, пока у нас нет данных
    private lazy var plugPageView: UIView = {
        let view = UIView()

        // Заглушка для цвета, потом обговорить и добавить правильный в Assets
        view.backgroundColor = .systemGray.withAlphaComponent(0.5)
        view.layer.cornerRadius = Constants.cornerRadius

        return view
    }()

    // Навигация под PageView, нажатия на нее еще не реализованы
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()

        return pageControl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupPageControl()
        setupPlugPageView()

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))

        view.addGestureRecognizer(panGestureRecognizer)
        view.isUserInteractionEnabled = false
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        hideViews()
        plugPageView.isHidden = false
        self.presenter?.launchData()
    }

    private func setupPageControl() {
        view.addSubview(pageControl)

        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(Constants.tabBarMargin)
        }
    }

    private func setupPlugPageView() {
        view.addSubview(plugPageView)

        plugPageView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.mediumMargin)
            make.top.equalToSuperview().inset(Constants.largeMargin)
            make.bottom.equalTo(pageControl.snp.top)
        }
    }

    private func hideViews() {
        swipeableViews.forEach {
            $0.removeFromSuperview()
        }

        swipeableViews.removeAll()
    }

    private func setupView() {
        view.isOpaque = true
        view.backgroundColor = .background
    }

    // Обработка свайпов pageViews
    @objc private func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: view)
        var index = (currentViewIndex + (Int(translation.x) < 0 ? 1 : -1)) % (swipeableViews.isEmpty ? 1 : swipeableViews.count)

        index = index == -1 ? swipeableViews.count - 1 : index

        switch gestureRecognizer.state {
        case .began:
            initialPosition = swipeableViews[currentViewIndex].center
        case .changed:
            swipeableViews[currentViewIndex].center = CGPoint(x: initialPosition.x + translation.x, y: initialPosition.y)
            if abs(translation.x) > 10 {
                swipeableViews.forEach { $0.isHidden = true }
                swipeableViews[currentViewIndex].isHidden = false
                swipeableViews[index].isHidden = false
                swipeableViews[index].center = CGPoint(
                    x: swipeableViews[currentViewIndex].center.x
                    + (translation.x < 0 ? 1 : -1) * (swipeableViews[currentViewIndex].frame.width + Constants.bigMargin),
                    y: initialPosition.y
                )
            } else {
                swipeableViews[index].isHidden = true
            }
        case .ended:
            if abs(translation.x) > swipeableViews[currentViewIndex].frame.width / 4 {
                UIView.animate(withDuration: Constants.animateDuration, animations: { [self] in
                    swipeableViews[index].center = self.initialPosition
                    swipeableViews[currentViewIndex].center.x = self.initialPosition.x
                    + (translation.x > 0 ? 1 : -1) * (swipeableViews[currentViewIndex].frame.width + Constants.bigMargin)
                }, completion: { _ in
                    self.swipeableViews[self.currentViewIndex].isHidden = true
                    self.currentViewIndex = index
                    self.pageControl.currentPage = index
                })
            } else {
                UIView.animate(withDuration: Constants.animateDuration, animations: { [self] in
                    swipeableViews[currentViewIndex].center = self.initialPosition
                    if translation.x > 0 {
                        swipeableViews[index].center.x = self.initialPosition.x - swipeableViews[index].frame.width - Constants.bigMargin
                    } else {
                        swipeableViews[index].center.x = self.initialPosition.x + swipeableViews[index].frame.width + Constants.bigMargin
                    }
                }, completion: { _ in
                    self.swipeableViews[index].isHidden = true
                })
            }

        case .cancelled:
            break
        default:
            break
        }
    }
}

extension MainViewController: MainViewControllerProtocol {
    
    // Конфигурирует наши pageViews и все, что в них находится
    func setContent(pagesInfo: [PageInfo]) {
        view.isUserInteractionEnabled = true
        activityIndicator.removeFromSuperview()
        let views = pageViewFactory.make(
            pagesInfo: pagesInfo,
            countOfViews: pagesInfo.count,
            delegate: self
        ) { [weak self] companyName in

            guard let self = self else {
                return
            }

            self.presenter?.openInfoAboutCompany(companyName: companyName)
        }

        views.forEach { pageView in
            self.view.addSubview(pageView)

            pageView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(Constants.mediumMargin)
                make.top.equalToSuperview().inset(Constants.largeMargin)
                make.bottom.equalTo(self.pageControl.snp.top)
            }

            self.swipeableViews.append(pageView)
        }

        self.swipeableViews[currentViewIndex].isHidden = false
        self.pageControl.numberOfPages = swipeableViews.count

        if !(self.swipeableViews.isEmpty) {
            self.plugPageView.isHidden = true
        }
    }
    
    func pushCompanyDetailsViewController(companyName: String) {
        let controller = NavigationHostingController(
            rootView: DetailsView()
                .environmentObject(DetailsController(ticker: companyName))
        )

        hideViews()

        self.navigationController?.pushViewController(controller, animated: true)
    }
}

extension MainViewController: ViewControllerDelegateFavourites {
    func deleteFromFavourites(companyName: String) -> Bool {
        presenter?.deleteFromFavourites(companyName: companyName)

        return false
    }
    
    func addToFavourites(companyName: String) {
        presenter?.addToFavourites(companyName: companyName)
    }
    
    func didCopmanyInFavourites(companyName: String) -> Bool {
        presenter?.companyInFavourites(companyName: companyName) ?? false
    }
}
