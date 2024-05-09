//
//  RoomStatusTabInfoViewController.swift
//  kiosoft
//
//  Created by harry on 2020/7/6.
//  Copyright © 2020 Ubix Innovations. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import GoogleMobileAds
import CocoaLumberjack

class RoomStatusTabInfoViewController : KSBaseViewController, GADBannerViewDelegate {
    
    var room_id : String?
    var location_id:String?
    var roomName:String?
    
    var spinner = UIActivityIndicatorView(style: .whiteLarge)
    var refreshControl: UIRefreshControl!
    var loadingView: UIView = UIView()
    
    var machineListModel: MachineListModel?
    
    var timer: Timer?
    
    var bannerView: GADBannerView!
    
    var needLoadData = false
    let reachabilityManager = Alamofire.NetworkReachabilityManager()
    private var roomModels = [RoomModel]()

    var selectedRoomName:String?
    
    let collectionViewHeight = SCREEN_HEIGHT-kNavHeight-20 //kTabBarHeight
    private lazy var collectionView:UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.itemSize = CGSize.init(width:SCREEN_WIDTH/2, height:kP6(84))
        flowLayout.scrollDirection = .vertical
        //flowLayout.footerReferenceSize = CGSize(width: SCREEN_WIDTH, height: kP6(64))
        flowLayout.headerReferenceSize = CGSize(width: SCREEN_WIDTH, height: kP6(72))
        //行最小间距 //上下
        flowLayout.minimumLineSpacing  = kP6(4)
        // 列最小间距//左右
        flowLayout.minimumInteritemSpacing = kP6(0)
        let collView = UICollectionView.init(frame:CGRect.zero, collectionViewLayout: flowLayout)
        collView.delegate = self
        collView.dataSource = self
        collView.alwaysBounceVertical = true
        collView.showsVerticalScrollIndicator = false
        collView.showsHorizontalScrollIndicator = false
        collView.backgroundColor = .white
        //collView
        collView.register(RoomStatusListCollectViewCell.classForCoder(), forCellWithReuseIdentifier: "RoomStatusListCollectViewCellIdentifiter")
        collView.register(RoomStatusListInfoReusableView.classForCoder(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "RoomStatusListReusableViewIdentifiter")
        collView.register(UICollectionReusableView.classForCoder(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier:"RoomStatusListReusableViewFooterIdentifiter")
        return collView
    }()
    private lazy var transEmptyLabel:UILabel = {
        let lab = UILabel.init()
        lab.text = "Please select your laundry room"
        lab.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        lab.textColor = UIColor.init(hexString: "0xAAAAAA")
        lab.backgroundColor = .white
        //lab.backgroundColor = UIColor.red
        //lab.tintColor = UIColor.red
        //lab.backgroundColor = UIColor.white
        lab.numberOfLines = 0
        lab.textAlignment = .center
        return lab
        
    }()
    private lazy var menuListView:HomeMainMenuListView = {
        let v = HomeMainMenuListView.init()
        v.tableData = []
        return v
    }()
    private lazy var showPickView:RoomStatusInfoShowView = {
        let v = RoomStatusInfoShowView.init(frame: .zero)
        v.selectRoomBlock = {[weak self] in
            self?.room_id = $0.roomId
            self?.location_id = $0.locationId
            self?.roomName = $0.roomName ?? "# " + ($0.roomId ?? "0")
            self?.timer?.invalidate()
            self?.timer = nil
            self?.transEmptyLabel.isHidden = true
            self?.refreshCollectViewPage()
            self?.saveCurrentSelectRoom(room: $0)
        }
        return v
    }()
    private lazy var showDropDownSearchView:RoomStatusListSmartSearchView = {
        let v = RoomStatusListSmartSearchView.init(frame: .zero)
        v.roomListSearchBlock = {[weak self] in
            self?.room_id = $0.roomId
            self?.location_id = $0.locationId
            self?.roomName = $0.roomName ?? "# " + ($0.roomId ?? "0")
            self?.timer?.invalidate()
            self?.timer = nil
            self?.transEmptyLabel.isHidden = true
            self?.refreshCollectViewPage()
            self?.saveCurrentSelectRoom(room: $0)
        }
        return v
        
    }()
    private var dropImgView:UIImageView?
    private var refreshHeight:CGFloat = 0
    
    //TODO 这里以后应该修改返回信息的格式。 就不需要这么麻烦了
    private var allCollectionData: [[MachineModel]]! //放所有数组的数组
    private var allCollectionInfoData : [[String:String]]! //其他各种信息的数组
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }else{
            self.automaticallyAdjustsScrollViewInsets = false
        }
        reachabilityManager?.listener = { status in
            switch status {
            case .notReachable:
                DDLogVerbose("The network is not reachable")
            case .unknown :
                DDLogVerbose("It is unknown whether the network is reachable")
            case .reachable:
                if self.needLoadData {
                    self.refreshControl.beginRefreshing()
                    self.refreshControl.sendActions(for: .valueChanged)
                }
            }
        }
        initUI()
        initData()
        
        // 添加广告
        if (CommonUtil.showGoogleADsFlag() == 1) && !Configuration.isCampus() {
            addGoogleAdmob()
        }
        if CommonUtil.isNeedToShowAds() && Configuration.isCampus() {
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActiveNotify), name: NSNotification.Name(rawValue:"UIApplicationDidBecomeActiveNotification"), object: nil)
            
            if let locationInfo = LocationInfoManagement().getLocationInfo() {
                let uln = locationInfo.location_code
                self.getGoogleADInfo(uln: uln as NSString)
            }
            updateAdsUI()
       }
        configSubViews()
    }
    
    private func configSubViews() {
        self.navigationBar.backType = .home
        
//        self.view.addSubview(self.transTableView)
//        self.transTableView.mas_makeConstraints { maker in
//            maker?.top.mas_equalTo()(navigationBar.mas_bottom)?.offset()(20)
//            maker?.leading.trailing().mas_equalTo()(self.view)
//            maker?.bottom.mas_equalTo()(self.view)
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.navigationItem.title = LanguageHelper.getString(key: "Room_Status")
        self.transEmptyLabel.text = LanguageHelper.getString(key: "Please_select_room")
        self.menuListView.tableData = []
        
//        refreshControl.beginRefreshing()
//        refreshControl.sendActions(for: .valueChanged)
//        for machineModel in MachineBookManager.shared.bookList {
//            if machineModel.finishTimeSeconds < Date().timeIntervalSince1970 {
//                MachineBookManager.removeMachine(machineModel)
//            }
//        }
//        self.refreshCollectViewPage()
        // 添加广告
        if CommonUtil.isNeedToShowAds() && !Configuration.isCampus() {
            if (CommonUtil.showGoogleADsFlag() == 1) {
                if bannerView == nil {
                    addGoogleAdmob()
                }
                if bannerView != nil {
                    addBannerViewToView(bannerView)
                }
            }else {
                if bannerView != nil {
                    bannerView.removeFromSuperview()
                }
            }
            
            updateAdsUI()
        }
    }
    
    func updateAdsUI() {
        if (CommonUtil.showGoogleADsFlag() == 1) {

            if bannerView == nil {
                addGoogleAdmob()
            }
            if bannerView != nil {
                addBannerViewToView(bannerView)

                self.collectionView.mas_updateConstraints({ (make) in
                    
                    make?.left.equalTo()(self.view)
                    make?.right.equalTo()(self.view)
//                    make?.top.equalTo()(self.view)
                    make?.top.mas_equalTo()(navigationBar.mas_bottom)?.offset()(20)
//                    make?.bottom.equalTo()(self.view)?.offset()(-googleAdmobHeight-(Configuration.isCampus() ? kIphoneTabH : 0))
                    make?.bottom.equalTo()(self.view)?.offset()(-googleAdmobHeight)
                })
            }
        }else {
            if bannerView != nil {
                bannerView.removeFromSuperview()
//                self.collectionView.frame = self.view.bounds
//                bannerView = nil
                self.collectionView.mas_updateConstraints({ (make) in
                    
                    make?.left.equalTo()(self.view)
                    make?.right.equalTo()(self.view)
//                    make?.top.equalTo()(self.view)
                    make?.top.mas_equalTo()(navigationBar.mas_bottom)?.offset()(20)
//                    make?.bottom.equalTo()(self.view)?.offset()(-(Configuration.isCampus() ? kIphoneTabH : 0))
                    make?.bottom.equalTo()(self.view)
                })
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.refreshCollectViewPage()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshCollectViewPage), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.timer?.invalidate()
        self.timer = nil
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)

    }
    
    private func initUI() {
//        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: UIImage.init(named: "ic_home_nav_menu"), style: .done, target: self, action: #selector(showMenuListAction))
//        self.navigationItem.leftBarButtonItem?.accessibilityLabel = LanguageHelper.getString(key: "Open_Main_Menu")
        self.view.addSubview(self.collectionView)
        collectionView.mas_makeConstraints { (make) in
            make?.left.equalTo()(self.view)
            make?.right.equalTo()(self.view)
//            make?.top.equalTo()(self.view)
            make?.top.mas_equalTo()(navigationBar.mas_bottom)?.offset()(20)
            
            if CommonUtil.isNeedToShowAds() {
                if (CommonUtil.showGoogleADsFlag() == 1) {
//                    make?.bottom.equalTo()(self.view)?.offset()(-googleAdmobHeight - (Configuration.isCampus() ? kIphoneTabH : 0))
                    make?.bottom.equalTo()(self.view)?.offset()(-googleAdmobHeight)
              }else {
//                    make?.bottom.equalTo()(self.view)?.offset()(-(Configuration.isCampus() ? kIphoneTabH : 0))
                  make?.bottom.equalTo()(self.view)
              }
            }else {
//                make?.bottom.equalTo()(self.view)?.offset()(-(Configuration.isCampus() ? kIphoneTabH : 0))
                make?.bottom.equalTo()(self.view)
          }
        }
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor.white
        refreshControl.tintColor = UIColor.gray
        refreshControl.addTarget(self, action: #selector(getRoomStatusMachineList), for: UIControl.Event.valueChanged)
        self.collectionView.refreshControl = refreshControl
        self.refreshHeight = self.refreshControl.frame.size.height
        self.view.addSubview(self.transEmptyLabel)
        self.transEmptyLabel.isHidden = true
        self.transEmptyLabel.mas_makeConstraints { (make) in
            make?.left.bottom().right()?.mas_equalTo()(self.view)
            make?.top.mas_equalTo()(self.collectionView)?.offset()(kP6(40))
            
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    private func initData() {
        if let m = self.readCurrentSelectRoom() {
            self.room_id = m.roomId
            self.location_id = m.locationId
            self.roomName = m.roomName ?? "# " + (m.roomId ?? "0")
            self.timer?.invalidate()
            self.timer = nil
            self.getcurrentRoomList(isLoading: false)
            
        }else {
            self.getcurrentRoomList(isLoading: true)
        }
    }
    private func saveCurrentSelectRoom(room:RoomModel) {
        guard let userid = AccountInfoManagement().getAccountInfo()?.user_id else { return }
        guard let locationId = LocationInfoManagement().getLocationInfo()?.location_id else {return}
        let data = NSKeyedArchiver.archivedData(withRootObject:room )
        UserDefaults.standard.set(data, forKey: "RoomStatus-SelectCurrentRoom_\(userid)_\(locationId)")
    }
    
    private func readCurrentSelectRoom()-> RoomModel?{
        guard let userid = AccountInfoManagement().getAccountInfo()?.user_id else { return nil}
        guard let locationId = LocationInfoManagement().getLocationInfo()?.location_id else { return nil}
        guard let data = UserDefaults.standard.data(forKey: "RoomStatus-SelectCurrentRoom_\(userid)_\(locationId)") else { return nil}
        //          bookList = NSKeyedUnarchiver.unarchiveObject(with: data) as! [MachineModel]
        //          DDLogVerbose(bookList)
        let room = NSKeyedUnarchiver.unarchiveObject(with: data) as! RoomModel
        return room
    }
    @objc private func showMenuListAction() {
        self.menuListView.tableData = []
        self.menuListView.showMenuListView()
    }
    @objc public func refreshCollectViewPage() {
        if (self.reachabilityManager?.isReachable) == true {
            needLoadData = false
            reachabilityManager?.stopListening()
        }else {
            reachabilityManager?.startListening()
            needLoadData = true
            for machine in self.machineListModel?.washers ?? [] {
                if machine.statusText.contains("Available") {
                    continue
                } else if machine.satus == "1" || machine.satus == "4" {
                    if machine.leftTime <= 0 {
                        machine.satus = "Z"
                        machine.statusText = "Out of Order"
                        MachineBookManager.removeMachine(machine)
                    }
                }
            }
            for machine in self.machineListModel?.dryers ?? [] {
                if machine.statusText.contains("Available") {
                    continue
                } else if machine.satus == "1" || machine.satus == "4" {
                    if machine.leftTime <= 0 {
                        machine.satus = "Z"
                        machine.statusText = "Out of Order"
                        MachineBookManager.removeMachine(machine)
                    }
                }
            }
            ReachabilitySwift.showConnectivityWarningDialog(sender: self, completion: {
                self.collectionView.reloadData()
                self.refreshControl.endRefreshing()
            })
            return
        }
        
//        if self.refreshControl.isRefreshing {
//
//        }else {
            UIView.animate(withDuration: 0.24, delay: 0, options: .beginFromCurrentState, animations: {
                if self.transEmptyLabel.isHidden == true {
                    self.collectionView.contentOffset = CGPoint.init(x: 0, y: -self.refreshHeight)
                }else {
                    self.collectionView.reloadData()
                }
            }) { (finished) in
                self.collectionView.bounces = true
                self.refreshControl.beginRefreshing()
                self.refreshControl.sendActions(for: .valueChanged)
                for machineModel in MachineBookManager.shared.bookList {
                    
                    if machineModel.finishTimeSeconds != nil {
                        if machineModel.finishTimeSeconds < Date().timeIntervalSince1970 {
                            MachineBookManager.removeMachine(machineModel)
                        }
                    }else{
                        
                        /**
                         新增加了需求 universal pulses里面也会有wash 和 dryer，
                         每次刷新的时候 判断是leftTime没了 就从保存的数组里面删掉
                         不知道为什么 现在都没有finishTimeSeconds这个值了，所以上面判断了非空
                         
                         这里为了防止没有finishTimeSeconds没办法从数组里删除
                         这个方法有待验证！！！！！！！！！
                         */
                        if machineModel.leftTime <= 0 {
                            machineModel.satus = "Z"
                            machineModel.statusText = "Out of Order"
                            MachineBookManager.removeMachine(machineModel)
                        }
                    }
                    
                    
                }
            }
//        }
    }
    @objc private func getcurrentRoomList(isLoading:Bool) {
        let locationCoreDataInstance = LocationInfoManagement()
        if let locationInfoInstance = locationCoreDataInstance.getLocationInfo(){
            if isLoading == true {
                CommonUtil.showActivityIndicator(sourceView: self.view, spinner: spinner, loadingView: loadingView)
            }
            let APICon = APIConnectionWithTimeOut()
            APICon.getLocationApi(location_code: locationInfoInstance.location_code){ responseObject, error, errorJson in
                CommonUtil.hideActivityIndicator(spinner: self.spinner, loadingView: self.loadingView)
                DDLogVerbose("wjw6710----getcurrentRoomList - Response:\(responseObject),\(error),\(errorJson)")
                let dic = JSON.init(responseObject as Any)
                if dic["status"] == 200  {
//                    self.roomModels.removeAll()
                    self.roomModels = dic["rooms"].arrayValue.map {
                        RoomModel.init(fromJson: $0)
                    }
                    self.roomModels.sort { (r1, r2) -> Bool in
                        return r1.roomName.uppercased() < r2.roomName.uppercased()
                    }
                    self.showPickView.dataSource = self.roomModels
                    self.showDropDownSearchView.tableData = self.roomModels
                    if  let saveRoom = self.readCurrentSelectRoom() {
                        var roomIdList : [String]=[]
                        for r in self.roomModels {
                            roomIdList.append(r.roomId)
                            if r.id == saveRoom.id {
                                r.isSelectd = 1
                            }else {
                                r.isSelectd = 0
                            }
                        }
                        self.showDropDownSearchView.tableData = self.roomModels
                        if roomIdList.contains(saveRoom.roomId) {
                            
                        }else {
                            self.roomName = ""
                        }
                        //                        if self.roomModels.contains(saveRoom) {
                        //
                        //                        }else {
                        //                            self.roomName = ""
                        //                        }
                    }
                }
                if errorJson != nil{
                    guard let errMsg = errorJson?["message"].string else { return }
                    CommonUtil.showAlert(sender: self, title: errMsg, message: "", button1: LanguageHelper.getString(key: "Mul_OK"), button2: nil)
                }
            }
        }
    }
    @objc private func getRoomStatusMachineList() {
        
        if let roomId = self.room_id,let locationId = self.location_id {
            if !ReachabilitySwift.isConnectedToNetwork() {
                reachabilityManager?.startListening()
                needLoadData = true
                
                for machine in self.machineListModel?.washers ?? [] {
                    if machine.statusText.contains(LanguageHelper.getString(key: "Available")) {
                        continue
                    } else if machine.satus == "1" || machine.satus == "4" {
                        if machine.leftTime <= 0 {
                            machine.satus = "Z"
                            machine.statusText = LanguageHelper.getString(key: "Out of Order")
                            MachineBookManager.removeMachine(machine)
                        }
                    }
                }
                
                for machine in self.machineListModel?.dryers ?? [] {
                    if machine.statusText.contains(LanguageHelper.getString(key: "Available")) {
                        continue
                    } else if machine.satus == "1" || machine.satus == "4" {
                        if machine.leftTime <= 0 {
                            machine.satus = "Z"
                            machine.statusText = LanguageHelper.getString(key: "Out of Order")
                            MachineBookManager.removeMachine(machine)
                        }
                    }
                }
                
                //直接show alert 会阻塞self.refreshControl.endRefreshing()的执行
                ReachabilitySwift.showConnectivityWarningDialog(sender: self, completion: {
                    self.collectionView.reloadData()
                    self.refreshControl.endRefreshing()
                })
                
                return
            }
            guard (AccountInfoManagement().getAccountInfo()?.session_token) != nil else {
                self.refreshControl.endRefreshing()
                return
            }
            needLoadData = false
            reachabilityManager?.stopListening()
            //            CommonUtil.showActivityIndicator(sourceView: self.view, spinner: spinner, loadingView: loadingView)
            let APICon = APIConnectionWithTimeOut()
            
            APICon.getRoomStatusMachineListApi(sender: self, room_id:roomId, location_id: locationId) { (responseObject, error, errorJson) in
                //                CommonUtil.hideActivityIndicator(spinner: self.spinner, loadingView: self.loadingView)
                self.transEmptyLabel.isHidden = true
                self.refreshControl.endRefreshing()
                let dic = JSON.init(responseObject as Any)
                if let printStr = dic.rawString() {
                    DDLogVerbose(printStr)
                }
                if dic["status"] == 200  {
                    if dic["data"]["data_status"] == "100" {
                        let machineListModel = MachineListModel.init(fromJson: dic["data"])
                        machineListModel.setCurrentTime(Date())
                        machineListModel.setMachineId(locationId: self.location_id, roomId: self.room_id, roomName: self.roomName)
                        self.machineListModel = machineListModel
                        //status为1，door open，有可能是available状态
                        for bookListItem in MachineBookManager.shared.bookList {
                            for machine in machineListModel.washers {
                                if machine.machineId == bookListItem.machineId {
                                    if machine.statusText.contains(LanguageHelper.getString(key: "Available")) {
                                        MachineBookManager.removeMachine(machine)
                                    } else if machine.satus == "1" || machine.satus == "4" {
                                        if machine.finishTimeSeconds - bookListItem.finishTimeSeconds > 120 { //top off
                                            do {
                                                try MachineBookManager.addMachine(machine)
                                            } catch {
                                                continue
                                            }
                                        }
                                    } else {
                                        MachineBookManager.removeMachine(machine)
                                    }
                                }
                            }
                            for machine in machineListModel.dryers {
                                if machine.machineId == bookListItem.machineId {
                                    if machine.statusText.contains(LanguageHelper.getString(key: "Available")) {
                                        MachineBookManager.removeMachine(machine)
                                    } else if machine.satus == "1" || machine.satus == "4" {
                                        if machine.finishTimeSeconds - bookListItem.finishTimeSeconds > 120 { //top off
                                            do {
                                                try MachineBookManager.addMachine(machine)
                                            } catch {
                                                continue
                                            }
                                        }
                                    } else {
                                        MachineBookManager.removeMachine(machine)
                                    }
                                }
                            }
                        }
                        
                        self.timer?.invalidate()
                        self.timer = nil
                        
                        self.timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.countDownOneMinute), userInfo: nil, repeats: true)
                        RunLoop.main.add(self.timer!, forMode: .common)
                        
                        self.collectionView.reloadData()
                        
                    } else {
                        guard let errMsg = dic["message"].string else {
                            let machineListModel = MachineListModel.init(fromJson: dic["data"])
                            machineListModel.setCurrentTime(Date())
                            machineListModel.setMachineId(locationId: self.location_id, roomId: self.room_id, roomName: self.roomName)
                            self.machineListModel = machineListModel
                            self.collectionView.reloadData()
                            return }
                        if errMsg.elementsEqual(LanguageHelper.getString(key: "Room_Not_found")) {
                            self.roomName = ""
                        }
                        self.collectionView.reloadData()
                        CommonUtil.showAlert(sender: self, title: errMsg, message: "", button1: LanguageHelper.getString(key: "Mul_OK"), button2: nil)
                    }
                }
                if errorJson != nil{ //解析数据错误
                    guard let errMsg = errorJson!["message"].string else {
                        CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Network_error_please_try_again"), message: "", button1: LanguageHelper.getString(key: "Mul_OK"), button2: nil)
                        return
                    }
                    CommonUtil.showAlert(sender: self, title: errMsg, message: "", button1: LanguageHelper.getString(key: "Mul_OK"), button2: nil)
                }
            }
        }else {
            self.refreshControl.endRefreshing()
            self.transEmptyLabel.isHidden = false
            self.collectionView.bounces = false
        }
    }
    
    @objc
    func countDownOneMinute() {
        DDLogVerbose("countDownOneMinute - \(#function)")
        var needReload = false
        for machine in self.machineListModel?.washers ?? [] {
            if machine.statusText.contains(LanguageHelper.getString(key: "Available")) {
                continue
            } else if machine.satus == "1" || machine.satus == "4" {
                machine.leftTime = machine.leftTime - 1
                if machine.leftTime <= 0 {
                    needReload = true
                } else {
                    machine.statusText = "\(machine.leftTime ?? 0) " + LanguageHelper.getString(key: "Minutes_left")
                }
            }
        }
        
        for machine in self.machineListModel?.dryers ?? [] {
            if machine.statusText.contains(LanguageHelper.getString(key: "Available")) {
                continue
            } else if machine.satus == "1" || machine.satus == "4" {
                machine.leftTime = machine.leftTime - 1
                if machine.leftTime <= 0 {
                    needReload = true
                } else {
                    machine.statusText = "\(machine.leftTime ?? 0) " + LanguageHelper.getString(key: "Minutes_left")
                }
            }
        }
        
        for machine in self.machineListModel?.universalPulses ?? [] {
            if machine.statusText.contains(LanguageHelper.getString(key: "Available")) {
                continue
            }else if machine.satus == "1" || machine.satus == "4" {
                machine.leftTime = machine.leftTime - 1
                if machine.leftTime <= 0 {
                    needReload = true
                } else {
                    machine.statusText = "\(machine.leftTime ?? 0) " + LanguageHelper.getString(key: "Minutes_left")
                }
            }
        }
        
        if needReload {
            self.refreshControl.beginRefreshing()
            self.refreshControl.sendActions(for: .valueChanged)
        } else {
            collectionView.reloadData()
        }
    }
    @objc private func didSelectRoomAction(sender:UIButton) {
        debugPrint("self.roomModels ---: \(self.roomModels)")
        if self.roomModels.count == 0 {
            CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Room_Not_found"), message: "", button1: LanguageHelper.getString(key: "Mul_OK"), button2: nil)
//            self.initData() //#14175
            self.getcurrentRoomList(isLoading: false)
            return
        }
        if Configuration.isWashConnectCleanPay() {
            self.showDropDownSearchView.showView(dropView: sender,dropImageV: self.dropImgView!)

        }else {
            self.showPickView.showPickView(dropView: self.dropImgView!, roomNameT: selectedRoomName)
        }
    }

    // add Google Admob -- start
    func addGoogleAdmob() {
        
        if !CommonUtil.isNeedToShowAds() {
            return
        }

        // Instantiate the banner view with your desired banner size.
        if bannerView == nil {
            bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        }
        if bannerView != nil {
            addBannerViewToView(bannerView)
            bannerView.rootViewController = self
            bannerView.delegate = self
            // Set the ad unit ID to your own ad unit ID here.
            bannerView.adUnitID = CommonUtil.getBannerAdsId()
//            bannerView.load(GADRequest())
            self.loadBannerAd()
        }
    }
    
    func addBannerViewToView(_ bannerView: UIView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        if #available(iOS 11.0, *) {
            positionBannerAtBottomOfSafeArea(bannerView)
        }
        else {
            positionBannerAtBottomOfView(bannerView)
        }
    }
    
    @available (iOS 11, *)
    func positionBannerAtBottomOfSafeArea(_ bannerView: UIView) {
        // Position the banner. Stick it to the bottom of the Safe Area.
        // Centered horizontally.
        let guide: UILayoutGuide = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate(
            [bannerView.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
             bannerView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)]
        )
    }
    
    func positionBannerAtBottomOfView(_ bannerView: UIView) {
        // Center the banner horizontally.
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .centerX,
                                              multiplier: 1,
                                              constant: 0))
        // Lock the banner to the top of the bottom layout guide.
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: self.bottomLayoutGuide,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 0))
    }
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        debugPrint("adViewDidReceiveAd")
        //        // 动画显示
        //        bannerView.alpha = 0
        //        UIView.animate(withDuration: 1, animations: {
        //            bannerView.alpha = 1
        //        })
    }
    
    /// Tells the delegate an ad request failed.
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
//    override func viewWillTransition(
//        to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
//    ) {
//        coordinator.animate(alongsideTransition: { _ in
//            self.loadBannerAd()
//        })
//    }
    
    func loadBannerAd() {
        
        // Here safe area is taken into account, hence the view frame is used after the
        // view has been laid out.
        let frame = { () -> CGRect in
            if #available(iOS 11.0, *) {
                return view.frame.inset(by: view.safeAreaInsets)
            } else {
                return view.frame
            }
        }()
        let viewWidth = frame.size.width
        
        // Here the current interface orientation is used. If the ad is being preloaded
        // for a future orientation change or different orientation, the function for the
        // relevant orientation should be used.
        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        googleAdmobHeight = bannerView.adSize.size.height

        bannerView.load(GADRequest())
    }
    
    @objc func applicationDidBecomeActiveNotify(nofi : Notification){

        if (!CommonUtil.isNeedToShowAds() || !Configuration.isCampus()) {
            return;
        }
        
        if let locationInfo = LocationInfoManagement().getLocationInfo() {
            let uln = locationInfo.location_code
            self.getGoogleADInfo(uln: uln as NSString)
        }
    }
    
    func getGoogleADInfo(uln: NSString?) {
        
        if uln == nil || uln == "" || uln == " " {
            print("getGoogleADInfo uln=\(String(describing: uln))")
            return
        }
        let APICon = APIConnectionWithTimeOut();
        DispatchQueue.global(qos: .userInitiated).async {
            APICon.getGoogleADInfoApi(sender: self, uln: uln! as String) { (response, error, errorJson) in
//                debugPrint("getGoogleADInfo============\nresonse=========\(String(describing: response)) \n\n errorJson============\(String(describing:errorJson))")
                DispatchQueue.main.async{
                    if let responseV = response {
                        let jsonObject = JSON(responseV)
                        let status = jsonObject["status"].intValue
                        if status == 200 {
                            let ADSwitch = jsonObject["start_app_ad"].stringValue
                            let adLevel = jsonObject["start_app_level"].stringValue
                            CommonUtil.setGoogleADLevelToLocal(ADSwitch: ADSwitch, adLevel: adLevel)

                            self.updateAdsUI()
                        } else {
                            CommonUtil.setGoogleADLevelToLocal(ADSwitch: "0", adLevel: "low")
                            self.updateAdsUI()
                            print("获取google广告等级数据失败！！ status=\(status)")
                        }
                    }else {
                        CommonUtil.setGoogleADLevelToLocal(ADSwitch: "0", adLevel: "low")
                        self.updateAdsUI()
                    }
                }
            }
        }
    }
    // add Google Admob — end
}

extension RoomStatusTabInfoViewController : UICollectionViewDelegate,UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        allCollectionData = [[MachineModel]]()
        allCollectionInfoData = [[String:String]]()
        
        //washers and dryers就算没有数据也要显示出来
        let washerDic:[String:String] = ["available":self.machineListModel?.washerAvailable ?? "",
                         "total":self.machineListModel?.washTotal ?? "",
                         "name":LanguageHelper.getString(key: "Washers")]
        allCollectionInfoData.append(washerDic)
        allCollectionData.append(self.machineListModel?.washers ?? [])
        
        let dryerDic:[String:String] = ["available":self.machineListModel?.dryerAvailable ?? "",
                         "total":self.machineListModel?.dryerTotal ?? "",
                         "name":LanguageHelper.getString(key: "Dryers")]
        allCollectionInfoData.append(dryerDic)
        allCollectionData.append(self.machineListModel?.dryers ?? [])
        
        //vendingAPI
        if self.machineListModel?.vendingApis.count ?? 0 > 0 {
            let dic:[String:String] = ["available":self.machineListModel?.vendingApisAvailable ?? "",
                             "total":self.machineListModel?.vendingApisTotal ?? "",
                             "name":LanguageHelper.getString(key: "VendingAPI")]
            allCollectionInfoData.append(dic)
            allCollectionData.append(self.machineListModel?.vendingApis ?? [])
        }
        
        //vendingMachines
        if self.machineListModel?.vendingMachines.count ?? 0 > 0 {
            let dic:[String:String] = ["available":self.machineListModel?.vendingMachineAvailable ?? "",
                             "total":self.machineListModel?.vendingMachineTotal ?? "",
                             "name":LanguageHelper.getString(key: "VendingMachines")]
            allCollectionInfoData.append(dic)
            allCollectionData.append(self.machineListModel?.vendingMachines ?? [])
        }
        
        //ultraPulse
        if self.machineListModel?.ultraPulse.count ?? 0 > 0 {
            let dic:[String:String] = ["available":self.machineListModel?.ultraAvailable ?? "",
                             "total":self.machineListModel?.ultraTotal ?? "",
                             "name":LanguageHelper.getString(key: "UltraPulses")]
            allCollectionInfoData.append(dic)
            allCollectionData.append(self.machineListModel?.ultraPulse ?? [])
        }
        
        //games
        if self.machineListModel?.games.count ?? 0 > 0 {
            let dic:[String:String] = ["available":self.machineListModel?.gameAvailable ?? "",
                             "total":self.machineListModel?.gameTotal ?? "",
                             "name":LanguageHelper.getString(key: "Games")]
            allCollectionInfoData.append(dic)
            allCollectionData.append(self.machineListModel?.games ?? [])
        }
        
        //universalPulses
        if self.machineListModel?.universalPulses.count ?? 0 > 0 {
            let dic:[String:String] = ["available":self.machineListModel?.universalPulsesAvailable ?? "",
                             "total":self.machineListModel?.universalPulsesTotal ?? "",
                             "name":LanguageHelper.getString(key: "UniversalPulses")]
            allCollectionInfoData.append(dic)
            allCollectionData.append(self.machineListModel?.universalPulses ?? [])
        }
        
        return allCollectionData.count
        
//        if self.machineListModel?.vendingMachines?.count ?? 0  == 0 {
//            return 2
//        }
//        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let currentList = allCollectionData[section]
        return currentList.count
        
//        if section == 0 {
//            return self.machineListModel?.washers?.count ?? 0
//        } else if section == 1 {
//            return self.machineListModel?.dryers?.count ?? 0
//        } else {
//            return self.machineListModel?.vendingMachines?.count ?? 0
//        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "RoomStatusListReusableViewIdentifiter", for: indexPath) as! RoomStatusListInfoReusableView
            
            let dic = allCollectionInfoData[indexPath.section]
            
            headerView.lblMachineType.text = dic["name"]
            headerView.lblMachineNum.text = "\(dic["available"] ?? "") \(LanguageHelper.getString(key: "of")) \(dic["total"] ?? "") \(LanguageHelper.getString(key: "Available New"))"
//            headerView.selectRoomBtn.isHidden = false
//            headerView.dropImgView.isHidden = false
            self.dropImgView = headerView.dropImgView
            if let r = roomName, r.count > 0 {
                headerView.selectRoomBtn.setTitle(r, for: .normal)
                selectedRoomName = r;
            }else {
                headerView.selectRoomBtn.setTitle(LanguageHelper.getString(key:"Select_your_room"), for: .normal)
                selectedRoomName = LanguageHelper.getString(key:"Select_your_room")
            }
            headerView.selectRoomBtn.addTarget(self, action: #selector(didSelectRoomAction(sender:)), for: .touchUpInside)
            
            if indexPath.section == 0{
                headerView.selectRoomBtn.isHidden = false
                headerView.dropImgView.isHidden = false
            }else{
                headerView.selectRoomBtn.isHidden = true
                headerView.dropImgView.isHidden = true
            }
            
            
//            if indexPath.section == 0 {
//                headerView.lblMachineType.text = LanguageHelper.getString(key: "Washers")
//                headerView.lblMachineNum.text = "\(self.machineListModel?.washerAvailable ?? "0") \(LanguageHelper.getString(key: "of")) \(self.machineListModel?.washTotal ?? "0") \(LanguageHelper.getString(key: "Available New"))"
////                headerView.labRoomName.text = roomName ?? "0"
//                headerView.selectRoomBtn.isHidden = false
//                headerView.dropImgView.isHidden = false
//                self.dropImgView = headerView.dropImgView
//                if let r = roomName, r.count > 0 {
//                    headerView.selectRoomBtn.setTitle(r, for: .normal)
//                }else {
//                    headerView.selectRoomBtn.setTitle(LanguageHelper.getString(key:"Select_your_room"), for: .normal)
//                }
//                headerView.selectRoomBtn.addTarget(self, action: #selector(didSelectRoomAction(sender:)), for: .touchUpInside)
//
//            } else if (indexPath.section == 1) {
//                headerView.lblMachineType.text = LanguageHelper.getString(key: "Dryers")
//                headerView.lblMachineNum.text = "\(self.machineListModel?.dryerAvailable ?? "0") \(LanguageHelper.getString(key: "of")) \(self.machineListModel?.dryerTotal ?? "0") \(LanguageHelper.getString(key: "Available New"))"
////                headerView.labRoomName.text = ""
//                headerView.selectRoomBtn.isHidden = true
//                headerView.dropImgView.isHidden = true
//            } else {
//                headerView.selectRoomBtn.isHidden = true
//                headerView.dropImgView.isHidden = true
//                headerView.lblMachineType.text = LanguageHelper.getString(key: "Vending_machines")
//                headerView.lblMachineNum.text = "\(self.machineListModel?.vendingMachineAvailable ?? "0") \(LanguageHelper.getString(key: "of")) \(self.machineListModel?.vendingMachineTotal ?? "0") \(LanguageHelper.getString(key: "Available New"))"
////                headerView.labRoomName.text = ""
//            }
            return headerView
        }else if kind == UICollectionView.elementKindSectionFooter {
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter,
                                                                             withReuseIdentifier:"RoomStatusListReusableViewFooterIdentifiter", for: indexPath as IndexPath)
            return footerView
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RoomStatusListCollectViewCellIdentifiter", for: indexPath) as! RoomStatusListCollectViewCell
        
        let currentList = allCollectionData[indexPath.section]
        cell.machineModel = currentList[indexPath.row]
        
//        if indexPath.section == 0 {
//            cell.machineModel = self.machineListModel?.washers[indexPath.row]
//        } else if indexPath.section == 1 {
//            cell.machineModel = self.machineListModel?.dryers[indexPath.row]
//        } else {
//            cell.machineModel = self.machineListModel?.vendingMachines[indexPath.row]
//        }
        cell.viewController = self
        return cell
    }
    
}
