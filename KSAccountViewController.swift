//
//  KSAccountViewController.swift
//  kiosoft
//
//  Created by Steven Wang on 2024/7/24.
//  Copyright © 2024 Ubix Innovations. All rights reserved.
//

import Foundation
import SwiftyJSON

class KSAccountViewController: KSBaseViewController, UITextFieldDelegate {
    var spinner = UIActivityIndicatorView(style: .whiteLarge)
    var loadingView: UIView = UIView()
    
    var myScrollView = UIScrollView()
    var headEmail_Label = UILabel()
    var headPhone_Label = UILabel()
    var headName_Label = UILabel()
    var headLocation_Label = UILabel()
    
    var gCampusCardTitleLabel:UILabel? = nil
    var gDeleteOneCardBtn: UIButton? = nil
    var gOneCardSubTitleLabel:UILabel? = nil
    var gCardNumberLabel:UILabel? = nil
    var gManageAccountTitleLabel = UILabel()
    var gHeadIcon_IV = UIImageView()
    var gTurnOnCleanAlert_Popup_Btn = UIButton()
    var gEmailAlert_Popup_Btn = UIButton()
    var turnOnAlertFlag = "0"
    // 是否支持校园支付
    var isSupportAtriumAccount = "0"
    var isSupportTouchnetWallet = "0"
    // OneCard存在
    var isOneCardAlreadyBind = "0"
    var gOneCardNumber = ""
    var gAttriumBindUrl = ""
    
    let firstNameView = KSTextFieldView.init(labelText: LanguageHelper.getString(key: "First_name"),isName: true)
    let lastNameView = KSTextFieldView.init(labelText: LanguageHelper.getString(key: "Last_name"),isName: true)
    let aEmailView = KSTextFieldView.init(labelText: LanguageHelper.getString(key: "Email"))
    let phoneView = KSPhoneNumberView(labelText: LanguageHelper.getString(key: "phone_newUI"))
    let apartmentSuiteView = KSTextFieldView(labelText: LanguageHelper.getString(key: "Apartment / Suite # (Optional)"))
    
    var contentView = UIView()
    var LC_Optional_Views: [KSTextFieldView] = []
    var CVC_Optional_Views: [KSTextFieldView] = []
    var deleteButtons: [UIButton] = []
    
    var originalContentOffset: CGPoint = .zero
    let maxLaundryCards = 5
    let edgeMargin = 25.0
    let fontTitleSize = 14.0
    let fontSubTitleSize = 10.0
    let fontBtnSize = 12.0
    let fontHeaderSize = 14.0
    let fontHeaderLargeSize = 19.0
    
    let sectionSeparateSpace = 38.0
    
    var gTurnOnCleanAlert_Checkbox_IV = UIImageView()
    var gturnOnCleanAlert_Checkbox_Label = UILabel()
    var gEditCreditCardBtn = UIButton()
    var gAddCampusCardBtn: UIButton? = nil
    var g_Sub_LaundryCard_Title_Label = UILabel()
    var g_AddNew_LaundryCard_Btn = UIButton()
    var gResetPassword_Btn = UIButton()
    
    // Update Mobile Number Alert
    var alertUpdatePhoneNumTextField:UITextField?
    var updatePhoneNumConfirmAAction:UIAlertAction?
    // Deactive Alert
    var alertDeactAccTextField:UITextField?
    var deactAccountAAction:UIAlertAction?
    // Campus Card Alert
    var alertAddCampusCardUserNameTextField:UITextField?
    var alertAddCampusCardPasswordTextField:UITextField?
    var addCampusCardNamePasswordAAction:UIAlertAction?
    var isSupportAddCampusCardUserName = false
    var isSupportAddCampusCardPassword = false
    
    // Turn on CleanAlert是否显示，默认显示，“1”：显示， “0”：隐藏
    var isEnableCleanAlert = "1"

    var isSupportCbord = false
    
    var isAleadyRefreshed = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.backType = .home
        self.view.backgroundColor = .white
        
        let walletModel = CommonUtil.getSelectWalletModel()
        if walletModel.trans_type == .cbord{
            isSupportCbord = true
        }
        
//        var array: Array<HomeChangeWalletItemModel> = []
//        do {
//            if let data = UserDefaults.standard.object(forKey: "PaymentModelArray") as? Data {
//                array = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! Array<HomeChangeWalletItemModel>
//            }
//        }catch let error {
//            DDLogVerbose("反序列化取钱包Error:\(error)")
//        }
//        
//        let aaaa:HomeChangeWalletItemModel = array[0]
        
        self.initUI()
    }
    
    func getAccountLatestInfo() {
        let ApiCon = APIConnectionWithTimeOut()
        let AccountInfoController = AccountInfoManagement()
        if let accountInfo = AccountInfoController.getAccountInfo(), let locationInfoInstance = LocationInfoManagement().getLocationInfo() {
            CommonUtil.showActivityIndicator(sourceView: self.view, spinner: self.spinner, loadingView: self.loadingView)
            
            ApiCon.getAccountInfoRefreshLocalApi(sender: self, account_number: accountInfo.account_num ?? "",locationID:locationInfoInstance.location_id ) { (response, error, errorJson) in
                CommonUtil.hideActivityIndicator(spinner: self.spinner, loadingView: self.loadingView)
                debugPrint("getAccountLatestInfo====resonse=====\n====\(String(describing: response)) \n\n errorJson============\(String(describing:errorJson))")
                if let responseV = response {
                    let jsonResponse = JSON(responseV)
                    DispatchQueue.main.async {
                        let accountInfoManage = AccountInfoManagement()
                        let locationInfoManage = LocationInfoManagement()
                        
                        if jsonResponse["status"].intValue == 200, let accountInstance = accountInfoManage.getAccountInfo(), let locationInstance = locationInfoManage.getLocationInfo() {
                            
                            let countryCode = jsonResponse["country_code"].stringValue
                            
                            // Head---------------
                            let firstName = jsonResponse["first_name"].stringValue
                            let lastName = jsonResponse["last_name"].stringValue
                            self.headName_Label.text = "\(firstName) \(lastName)"
                            let userEmail = jsonResponse["email"].stringValue
                            self.headEmail_Label.text = userEmail
                            let userPhone = jsonResponse["user_mobile"].stringValue
                            self.headPhone_Label.text = (countryCode == "1") ? CommonUtil.formatUSAPhoneNumber(userPhone) : userPhone
                            
                            // Update Account Info -----
                            self.firstNameView.myTextField.text = firstName
                            self.lastNameView.myTextField.text = lastName
                            self.aEmailView.myTextField.text = userEmail
                            // 手机号
                            // +1
                            self.phoneView.phoneLabel.text = "+\(countryCode)"
                            // "user_country" = USA;
                            let targetCountry = jsonResponse["user_country"].stringValue
                            self.phoneView.selCountryButton.setTitle(targetCountry, for: .normal)
                            // Phone Number
                            self.phoneView.textField.text = (countryCode == "1") ? CommonUtil.formatUSAPhoneNumber(userPhone) : userPhone
                            let suite = jsonResponse["suite"].stringValue
                            self.apartmentSuiteView.myTextField.text = suite
                            
                            self.isEnableCleanAlert = jsonResponse["enable_clean_alert"].stringValue
                            
                            let alert = jsonResponse["alert"].stringValue
                            if alert == "1" {
                                self.turnOnAlertFlag = "1"
                                self.gTurnOnCleanAlert_Checkbox_IV.image = UIImage.init(named: "Ic_home_rememberme_selected")
                            }else {
                                self.turnOnAlertFlag = "0"
                                self.gTurnOnCleanAlert_Checkbox_IV.image = UIImage.init(named: "Ic_home_rememberme_unselected")
                            }
                            
                            // Update Laundry Card(s)
                            let cardlistServerArr = jsonResponse["laundry_card_list"].arrayValue
                            var card_list: [[String: String]] = []
                            
                            for card in cardlistServerArr {
                                let lcNumber = card["laundry_card_number"].stringValue
                                let cvcNumber = card["cvc"].stringValue
                                
                                let cardDict: [String: String] = ["lcNumber": lcNumber, "cvcNumber": cvcNumber]
                                card_list.append(cardDict)
                            }
                            
                            if card_list.count == 1 {
                                self.updateTextFieldPairs(with: card_list)
                            }else if card_list.count > 1 {
                                for _ in 0..<card_list.count-1 {
                                    self.addNewLaundryCardFields()
                                }
                                self.updateTextFieldPairs(with: card_list)
                            }
                            
                            // 获取校园支付支持状态
                            self.isSupportAtriumAccount = jsonResponse["user_location"]["atrium_account"].stringValue
                            self.isSupportTouchnetWallet = jsonResponse["user_location"]["touchnet_wallet"].stringValue
                            debugPrint("Campus Pay: self.isSupportAtriumAccount:\(self.isSupportAtriumAccount) --- self.isSupportTouchnetWallet:\(self.isSupportTouchnetWallet)")
                            // 判断是否已经有校园卡绑定 Touchnet / Attrium
                            if self.isSupportAtriumAccount == "1" || self.isSupportTouchnetWallet == "1" {
                                // 解析获取CardNumber值
                                self.gOneCardNumber = ""
                                let campusSolutions = jsonResponse["campus_solution"].arrayValue
                                for solution in campusSolutions {
                                    if let cardNumber = solution["card_number"].string {
                                        self.isOneCardAlreadyBind = "1"
                                        self.gOneCardNumber = cardNumber
                                        debugPrint("Card Number: \(cardNumber)")
                                    } else {
                                        print("card_number is empty or not found.")
                                    }
                                }
                                
                                if self.isSupportAtriumAccount == "1" {
                                    // 校园支付 Attrium
                                    let attriumBindUrl = jsonResponse["campus_bind_url"].stringValue
                                    debugPrint("attriumBindUrl--:\(attriumBindUrl)")
                                    if attriumBindUrl != "" {
                                        self.gAttriumBindUrl = attriumBindUrl
                                    }
                                }
                                self.isAleadyRefreshed = true
                            }else {
                                self.isSupportAtriumAccount = "0"
                                self.isSupportTouchnetWallet = "0"
                            }
                            // 更新UI
                            self.updateUILayout()
                        } else {
                            // 请求失败，显示错误提示
                            // self.showErrorAndRetry()
                        }
                    }
                }
                if error != nil {
                    DDLogVerbose("getAccountInfoDetail -- error:\(String(describing: error))")
                    if errorJson != nil {
                        if let message = errorJson?["message"].string, message != ""{
                            CommonUtil.showAlert(sender: self, title: message, message: "", button1: LanguageHelper.getString(key: "OK"), button2: nil)
                        }else{
                            
                        }
                    }
                }
            }
        }
    }
    
    func updateUILayout() {
        // part 1
        if (isSupportAtriumAccount == "1" || isSupportTouchnetWallet == "1") && isOneCardAlreadyBind == "1" && !isSupportCbord  {
            gCampusCardTitleLabel?.removeFromSuperview()
            gDeleteOneCardBtn?.removeFromSuperview()
            gOneCardSubTitleLabel?.removeFromSuperview()
            gCardNumberLabel?.removeFromSuperview()
            gCampusCardTitleLabel = nil
            gDeleteOneCardBtn = nil
            gOneCardSubTitleLabel = nil
            gCampusCardTitleLabel = nil

            // part 5 - OneCard
            gCampusCardTitleLabel = {
                let label = UILabel()
                label.textColor = UIColor(hexString: "404040")
                label.font = UIFont.boldSystemFont(ofSize: fontTitleSize)
                label.text = LanguageHelper.getString(key: "key_CampusCard")
                label.numberOfLines = 0
                return label
            }()
            contentView.addSubview(gCampusCardTitleLabel ?? UILabel())
            gCampusCardTitleLabel?.mas_remakeConstraints { make in
                make?.top.equalTo()(gTurnOnCleanAlert_Checkbox_IV.mas_bottom)?.offset()(sectionSeparateSpace)
                make?.leading.equalTo()(gHeadIcon_IV.mas_leading)
                make?.trailing.equalTo()(self.view)
            }
            
            // 5 - 2 Deleted BTN
            gDeleteOneCardBtn = {
                let btn = UIButton(type: .custom)
                btn.setTitle(LanguageHelper.getString(key: "MulT_Delete"), for: .normal)
                btn.setTitleColor(UIColor.init(hexString: "404040"), for: .normal)
                btn.backgroundColor = UIColor(hexString: "F7A1A1")
                btn.layer.cornerRadius = 5
                btn.titleLabel?.font = UIFont.systemFont(ofSize: fontBtnSize)
                btn.titleLabel?.numberOfLines = 0
                btn.addTarget(self, action: #selector(deleteOneCardBtnClicked(sender:)), for: .touchUpInside)
                return btn
            }()
            contentView.addSubview(gDeleteOneCardBtn ?? UIButton())
            gDeleteOneCardBtn?.mas_remakeConstraints { make in
                make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
                make?.width.mas_equalTo()(64)
                make?.height.mas_equalTo()(22)
                make?.centerY.equalTo()(gCampusCardTitleLabel)
            }
            
            // 5 - 3 sub Title
            gOneCardSubTitleLabel = {
                let label = UILabel()
                label.textColor = UIColor(hexString: "666666")
                label.font = UIFont.systemFont(ofSize: fontSubTitleSize)
                label.text = LanguageHelper.getString(key: "Users_can_only_add_one_card_per_account")
                label.numberOfLines = 0
                return label
            }()
            contentView.addSubview(gOneCardSubTitleLabel ?? UILabel())
            gOneCardSubTitleLabel?.mas_remakeConstraints { make in
                make?.top.equalTo()(gCampusCardTitleLabel?.mas_bottom)?.offset()(10)
                make?.leading.equalTo()(gHeadIcon_IV.mas_leading)
                make?.trailing.equalTo()(gDeleteOneCardBtn?.mas_trailing)
            }
            
            // 5 - 4 Card Number
            gCardNumberLabel = {
                let label = UILabel()
                label.textColor = UIColor(hexString: "666666")
                label.font = UIFont.systemFont(ofSize: fontTitleSize)
                label.text = LanguageHelper.getString(key: "Card_Number")
                label.numberOfLines = 0
                return label
            }()
            contentView.addSubview(gCardNumberLabel ?? UILabel())
            gCardNumberLabel?.mas_remakeConstraints { make in
                make?.top.equalTo()(gOneCardSubTitleLabel?.mas_bottom)?.offset()(15)
                make?.leading.equalTo()(gHeadIcon_IV.mas_leading)
                make?.trailing.equalTo()(gDeleteOneCardBtn?.mas_trailing)
            }
            gCardNumberLabel?.text = LanguageHelper.getString(key: "Card_Number") + self.gOneCardNumber
        }else {
            gCampusCardTitleLabel?.isHidden = true
            gDeleteOneCardBtn?.isHidden = true
            gOneCardSubTitleLabel?.isHidden = true
            gCardNumberLabel?.isHidden = true
        }
        
        // part 2
//        contentView.addSubview(gManageAccountTitleLabel)
        // Debug Code
//        isSupportCbord = true
//        (UIApplication.shared.delegate as? AppDelegate)?.showEditCreditCard = false
//        
//        isEnableCleanAlert = "1"
//        isSupportAtriumAccount = "1"
//        isSupportTouchnetWallet = "1"
//        isOneCardAlreadyBind = "0"
        
        // Turn on CleanAlert隐藏，但是绑定一张校园卡
        if isEnableCleanAlert == "0" {
            gTurnOnCleanAlert_Checkbox_IV.isHidden = true
            gturnOnCleanAlert_Checkbox_Label.isHidden = true
            gTurnOnCleanAlert_Popup_Btn.isHidden = true
            
            if !isSupportCbord {
                if (isSupportAtriumAccount == "1" || isSupportTouchnetWallet == "1") && isOneCardAlreadyBind == "1" {
                    gCampusCardTitleLabel?.isHidden = false
                    gDeleteOneCardBtn?.isHidden = false
                    gOneCardSubTitleLabel?.isHidden = false
                    gCardNumberLabel?.isHidden = false

                    // 如果有一张卡绑定
                    gCampusCardTitleLabel?.mas_remakeConstraints { make in
                        make?.top.equalTo()(g_AddNew_LaundryCard_Btn.mas_bottom)?.offset()(sectionSeparateSpace)
                        make?.leading.equalTo()(contentView)?.offset()(edgeMargin)
                        make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
                    }
                    
                    gManageAccountTitleLabel.mas_remakeConstraints { make in
                        make?.top.equalTo()(gCardNumberLabel?.mas_bottom)?.offset()(sectionSeparateSpace)
                        make?.leading.equalTo()(contentView)?.offset()(edgeMargin)
                        make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
                    }

                }else {
                    gCampusCardTitleLabel?.isHidden = true
                    gDeleteOneCardBtn?.isHidden = true
                    gOneCardSubTitleLabel?.isHidden = true
                    gCardNumberLabel?.isHidden = true

                    // 如果是没有一张卡绑定
                    gManageAccountTitleLabel.mas_remakeConstraints { make in
                        make?.top.equalTo()(g_AddNew_LaundryCard_Btn.mas_bottom)?.offset()(sectionSeparateSpace)
                        make?.leading.equalTo()(contentView)?.offset()(edgeMargin)
                        make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
                    }
                }
            }else {
                gCampusCardTitleLabel?.isHidden = true
                gDeleteOneCardBtn?.isHidden = true
                gOneCardSubTitleLabel?.isHidden = true
                gCardNumberLabel?.isHidden = true
                // 没有张卡绑定
                gManageAccountTitleLabel.mas_remakeConstraints { make in
                    make?.top.equalTo()(g_AddNew_LaundryCard_Btn.mas_bottom)?.offset()(sectionSeparateSpace)
                    make?.leading.equalTo()(contentView)?.offset()(edgeMargin)
                    make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
                }
            }
        }else {
            gTurnOnCleanAlert_Checkbox_IV.isHidden = false
            gturnOnCleanAlert_Checkbox_Label.isHidden = false
            gTurnOnCleanAlert_Popup_Btn.isHidden = false

            if !isSupportCbord {
                if (isSupportAtriumAccount == "1" || isSupportTouchnetWallet == "1") && isOneCardAlreadyBind == "1" {
                    gCampusCardTitleLabel?.isHidden = false
                    gDeleteOneCardBtn?.isHidden = false
                    gOneCardSubTitleLabel?.isHidden = false
                    gCardNumberLabel?.isHidden = false

                    // 如果有一张卡绑定
                    gCampusCardTitleLabel?.mas_remakeConstraints { make in
                        make?.top.equalTo()(gTurnOnCleanAlert_Checkbox_IV.mas_bottom)?.offset()(sectionSeparateSpace)
                        make?.leading.equalTo()(contentView)?.offset()(edgeMargin)
                        make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
                    }
                    
                    gManageAccountTitleLabel.mas_remakeConstraints { make in
                        make?.top.equalTo()(gCardNumberLabel?.mas_bottom)?.offset()(sectionSeparateSpace)
                        make?.leading.equalTo()(contentView)?.offset()(edgeMargin)
                        make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
                    }

                }else {
                    gCampusCardTitleLabel?.isHidden = true
                    gDeleteOneCardBtn?.isHidden = true
                    gOneCardSubTitleLabel?.isHidden = true
                    gCardNumberLabel?.isHidden = true
                    
                    
                    
                    // 如果是没有一张卡绑定
                    gManageAccountTitleLabel.mas_remakeConstraints { make in
                        make?.top.equalTo()(gTurnOnCleanAlert_Checkbox_IV.mas_bottom)?.offset()(sectionSeparateSpace)
                        make?.leading.equalTo()(contentView)?.offset()(edgeMargin)
                        make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
                    }
                }
            }else {
                // 没有张卡绑定
                gCampusCardTitleLabel?.isHidden = true
                gDeleteOneCardBtn?.isHidden = true
                gOneCardSubTitleLabel?.isHidden = true
                gCardNumberLabel?.isHidden = true
                gManageAccountTitleLabel.mas_remakeConstraints { make in
                    make?.top.equalTo()(gTurnOnCleanAlert_Checkbox_IV.mas_bottom)?.offset()(sectionSeparateSpace)
                    make?.leading.equalTo()(contentView)?.offset()(edgeMargin)
                    make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
                }
            }
        }
        
        // 对Edit_Credit_Card 和 Add Campus Card两个各种组合情况
        if isSupportCbord == true && (UIApplication.shared.delegate as? AppDelegate)?.showEditCreditCard == false {
            // OK
            // 1. 当支持CBord, 不显示Edit_Credit_Card -- Edit_Credit_Card 和 Add Campus Card 两个按钮同时隐藏
            gAddCampusCardBtn?.isHidden = true
            gEditCreditCardBtn.isHidden = true
            
            // 让reset Password按钮 和 Deactive按钮上移，并更新约束
            gResetPassword_Btn.mas_remakeConstraints { make in
                //两边间距25+两个view间距10=60. 这是两个view 所以这里的偏移量是-30
                make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30)
                make?.height.equalTo()(26)
                make?.left.equalTo()(edgeMargin)
                make?.top.equalTo()(gManageAccountTitleLabel.mas_bottom)?.offset()(20)
            }
            
        }else if isSupportCbord == true && (UIApplication.shared.delegate as? AppDelegate)?.showEditCreditCard == true {
            // 2. 当支持CBord, 但显示Edit按钮时，即Edit_Credit_Card显示，Add Campus Card按钮隐藏时
            if ((isSupportAtriumAccount == "1" || isSupportTouchnetWallet == "1") && isOneCardAlreadyBind == "0") ||
                (isSupportAtriumAccount == "0" && isSupportTouchnetWallet == "0") {
                // 2.1 当Server支持Attrium卡或者Touchnet卡，但是没有绑定卡时
                // 2.2 当Server都不支持Attrium卡或者Touchnet卡，
                gAddCampusCardBtn?.isHidden = true
                gEditCreditCardBtn.isHidden = false
                gResetPassword_Btn.mas_remakeConstraints { make in
                    //两边间距25+两个view间距10=60. 这是两个view 所以这里的偏移量是-30
                    make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30)
                    make?.height.equalTo()(26)
                    make?.left.equalTo()(edgeMargin)
                    make?.top.equalTo()(gEditCreditCardBtn.mas_bottom)?.offset()(20)
                }
            }else if ((isSupportAtriumAccount == "1" || isSupportTouchnetWallet == "1") && isOneCardAlreadyBind == "1") {
                // 2.3 当Server支持Attrium卡或者Touchnet卡，有绑定卡时
                
                gAddCampusCardBtn?.isHidden = true
                gEditCreditCardBtn.isHidden = false
                
                gCampusCardTitleLabel?.isHidden = false
                gDeleteOneCardBtn?.isHidden = false
                gOneCardSubTitleLabel?.isHidden = false
                gCardNumberLabel?.isHidden = false

                gManageAccountTitleLabel.mas_remakeConstraints { make in
                    make?.top.equalTo()(gCardNumberLabel?.mas_bottom)?.offset()(20)
                    make?.left.equalTo()(contentView)?.offset()(edgeMargin)
                    make?.right.equalTo()(contentView)?.offset()(-edgeMargin)
                    make?.height.equalTo()(26)
                }
            }else {
                DDLogVerbose("Error!!! --- Error scenario (1). ")
            }
            
        }else if isSupportCbord == false && (UIApplication.shared.delegate as? AppDelegate)?.showEditCreditCard == false {
            // 3. 不是Cbord环境，EditCreditCard隐藏，Add Campus Card根据实际情况决定是否显示
            gEditCreditCardBtn.isHidden = true
            
            if ((isSupportAtriumAccount == "1" || isSupportTouchnetWallet == "1") && isOneCardAlreadyBind == "0") {
                // 3.1 当Server支持Attrium卡或者Touchnet卡，有绑定卡时
                // OK
                if gAddCampusCardBtn != nil {
                    gAddCampusCardBtn?.removeFromSuperview()
                    gAddCampusCardBtn = nil
                }
                gAddCampusCardBtn = {
                    let btn = UIButton(type: .custom)
                    btn.setTitle(LanguageHelper.getString(key: "Add_Campus_Card"), for: .normal)
                    btn.setTitleColor(UIColor.init(hexString: "404040"), for: .normal)
                    btn.titleLabel?.font = UIFont.systemFont(ofSize: fontBtnSize)
                    btn.titleLabel?.numberOfLines = 0
                    btn.layer.cornerRadius = 5
                    btn.layer.borderWidth = 1
                    btn.layer.borderColor = UIColor.init(hexString: "B3B3B3").cgColor
                    btn.addTarget(self, action: #selector(addNewCardBtnClicked), for: .touchUpInside)
                    return btn
                }()
                contentView.addSubview(gAddCampusCardBtn ?? UIButton())
                
                gAddCampusCardBtn?.isHidden = false
                
                gCampusCardTitleLabel?.isHidden = true
                gDeleteOneCardBtn?.isHidden = true
                gOneCardSubTitleLabel?.isHidden = true
                gCardNumberLabel?.isHidden = true
                
                gManageAccountTitleLabel.mas_remakeConstraints { make in
                    make?.top.equalTo()(gTurnOnCleanAlert_Checkbox_IV.mas_bottom)?.offset()(20)
                    make?.left.equalTo()(contentView)?.offset()(edgeMargin)
                    make?.right.equalTo()(contentView)?.offset()(-edgeMargin)
                    make?.height.equalTo()(26)
                }
                gAddCampusCardBtn?.mas_makeConstraints { make in
                    make?.top.equalTo()(gManageAccountTitleLabel.mas_bottom)?.offset()(10)
                    make?.left.equalTo()(contentView)?.offset()(edgeMargin)
                    make?.right.equalTo()(contentView)?.offset()(-edgeMargin)
                    make?.height.equalTo()(26)
                }
            }else if ((isSupportAtriumAccount == "1" || isSupportTouchnetWallet == "1") && isOneCardAlreadyBind == "1") {
                // 3.2 当Server支持Attrium卡或者Touchnet卡，但是没有绑定卡时
                if gAddCampusCardBtn != nil {
                    gAddCampusCardBtn?.removeFromSuperview()
                    gAddCampusCardBtn = nil
                }
                gAddCampusCardBtn = {
                    let btn = UIButton(type: .custom)
                    btn.setTitle(LanguageHelper.getString(key: "Add_Campus_Card"), for: .normal)
                    btn.setTitleColor(UIColor.init(hexString: "404040"), for: .normal)
                    btn.titleLabel?.font = UIFont.systemFont(ofSize: fontBtnSize)
                    btn.titleLabel?.numberOfLines = 0
                    btn.layer.cornerRadius = 5
                    btn.layer.borderWidth = 1
                    btn.layer.borderColor = UIColor.init(hexString: "B3B3B3").cgColor
                    btn.addTarget(self, action: #selector(addNewCardBtnClicked), for: .touchUpInside)
                    return btn
                }()
                contentView.addSubview(gAddCampusCardBtn ?? UIButton())
                
                gAddCampusCardBtn?.isHidden = false
                
                gCampusCardTitleLabel?.isHidden = false
                gDeleteOneCardBtn?.isHidden = false
                gOneCardSubTitleLabel?.isHidden = false
                gCardNumberLabel?.isHidden = false
                
                gManageAccountTitleLabel.mas_remakeConstraints { make in
                    make?.top.equalTo()(gCardNumberLabel?.mas_bottom)?.offset()(20)
                    make?.leading.equalTo()(contentView)?.offset()(edgeMargin)
                    make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
                }
                
                gAddCampusCardBtn?.mas_makeConstraints { make in
                    make?.top.equalTo()(gManageAccountTitleLabel.mas_bottom)?.offset()(10)
                    make?.left.equalTo()(contentView)?.offset()(edgeMargin)
                    make?.right.equalTo()(contentView)?.offset()(-edgeMargin)
                    make?.height.equalTo()(26)
                }
            }else if ((isSupportAtriumAccount == "0" && isSupportTouchnetWallet == "0")) {
                // 3.3 当Server都支持Attrium卡或者Touchnet卡
                gAddCampusCardBtn?.isHidden = true
                
                gCampusCardTitleLabel?.isHidden = true
                gDeleteOneCardBtn?.isHidden = true
                gOneCardSubTitleLabel?.isHidden = true
                gCardNumberLabel?.isHidden = true
                
                gResetPassword_Btn.mas_remakeConstraints { make in
                    //两边间距25+两个view间距10=60. 这是两个view 所以这里的偏移量是-30
                    make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30)
                    make?.height.equalTo()(26)
                    make?.left.equalTo()(edgeMargin)
                    make?.top.equalTo()(gManageAccountTitleLabel.mas_bottom)?.offset()(20)
                }
            }
        }else if isSupportCbord == false && (UIApplication.shared.delegate as? AppDelegate)?.showEditCreditCard == true {
            // 3. 不是Cbord环境，EditCreditCard按钮显示，Add Campus Card根据实际情况决定是否显示
            if (isSupportAtriumAccount == "1" || isSupportTouchnetWallet == "1") && isOneCardAlreadyBind == "0" {
                // 3.1 没有绑定卡，则Add Campus Card显示 各占一半
                
                if gAddCampusCardBtn != nil {
                    gAddCampusCardBtn?.removeFromSuperview()
                    gAddCampusCardBtn = nil
                }
                
                gAddCampusCardBtn = {
                    let btn = UIButton(type: .custom)
                    btn.setTitle(LanguageHelper.getString(key: "Add_Campus_Card"), for: .normal)
                    btn.setTitleColor(UIColor.init(hexString: "404040"), for: .normal)
                    btn.titleLabel?.font = UIFont.systemFont(ofSize: fontBtnSize)
                    btn.titleLabel?.numberOfLines = 0
                    btn.layer.cornerRadius = 5
                    btn.layer.borderWidth = 1
                    btn.layer.borderColor = UIColor.init(hexString: "B3B3B3").cgColor
                    btn.addTarget(self, action: #selector(addNewCardBtnClicked), for: .touchUpInside)
                    return btn
                }()
                contentView.addSubview(gAddCampusCardBtn ?? UIButton())
                
                // Edit_Credit_Card
                gEditCreditCardBtn.mas_remakeConstraints { make in
                    //两边间距25+两个view间距10=60. 这是两个view 所以这里的偏移量是-30
                    make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30)
                    make?.left.equalTo()(edgeMargin)
                    make?.top.equalTo()(gManageAccountTitleLabel.mas_bottom)?.offset()(10)
                }
                
                // Add_Campus_Card
                gAddCampusCardBtn?.mas_remakeConstraints { make in
                    make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30)
                    make?.left.equalTo()(gEditCreditCardBtn.mas_right)?.offset()(10)
                    make?.top.equalTo()(gEditCreditCardBtn)
                    make?.height.equalTo()(26)
                }
            } else if (isSupportAtriumAccount == "1" || isSupportTouchnetWallet == "1") && isOneCardAlreadyBind == "1" {
                // 3.1 有绑定卡，则Add Campus Card隐藏，Edit卡展示宽度为屏幕宽度
                if gAddCampusCardBtn != nil {
                    gAddCampusCardBtn?.removeFromSuperview()
                    gAddCampusCardBtn = nil
                }
                gAddCampusCardBtn?.isHidden = true
                
                debugPrint("--------1: \(String(describing: gAddCampusCardBtn))")
                gManageAccountTitleLabel.mas_remakeConstraints { make in
                    make?.top.equalTo()(gCardNumberLabel?.mas_bottom)?.offset()(20)
                    make?.leading.equalTo()(contentView)?.offset()(edgeMargin)
                    make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
                }
                gEditCreditCardBtn.mas_remakeConstraints { make in
                    make?.top.equalTo()(gManageAccountTitleLabel.mas_bottom)?.offset()(10)
                    make?.left.equalTo()(contentView)?.offset()(edgeMargin)
                    make?.right.equalTo()(contentView)?.offset()(-edgeMargin)
                    make?.height.equalTo()(26)
                }
            }else if (isSupportAtriumAccount == "0" && isSupportTouchnetWallet == "0") {
                // 3.2 不支持两卡 或者 Server不支持两种卡的绑定，则Add Campus Card根据实际情况决定是否显示
                if gAddCampusCardBtn != nil {
                    gAddCampusCardBtn?.removeFromSuperview()
                    gAddCampusCardBtn = nil
                }
                gAddCampusCardBtn?.isHidden = true
                
                debugPrint("--------1: \(String(describing: gAddCampusCardBtn))")
                gEditCreditCardBtn.mas_remakeConstraints { make in
                    make?.top.equalTo()(gManageAccountTitleLabel.mas_bottom)?.offset()(10)
                    make?.left.equalTo()(contentView)?.offset()(edgeMargin)
                    make?.right.equalTo()(contentView)?.offset()(-edgeMargin)
                    make?.height.equalTo()(26)
                }
            }
        }
        contentView.layoutIfNeeded()
    }
    
    func showErrorAndRetry() {
        let alertController = UIAlertController(title: "Error", message: "Failed to load account information. Please try again.", preferredStyle: .alert)
        let retryAction = UIAlertAction(title: "Retry", style: .default) { _ in
            self.getAccountLatestInfo()
        }
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.init(uptimeNanoseconds:100)) {
            self.getAccountLatestInfo()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationBar.backgroundColor = .white
    }
    
    private func initUI() {
        navigationBar.backgroundColor = UIColor.init(hexString: "ECECEC")
        
        firstNameView.myTextField.delegate = self
        lastNameView.myTextField.delegate = self
        aEmailView.myTextField.delegate = self

        self.view.addSubview(myScrollView)
        myScrollView.bounces = false
        myScrollView.alwaysBounceVertical = false
        myScrollView.alwaysBounceHorizontal = false
        myScrollView.showsVerticalScrollIndicator = false
        myScrollView.mas_makeConstraints { make in
            make?.top.mas_equalTo()(self.navigationBar.mas_bottom)
            make?.left.right().equalTo()(self.view)
            make?.bottom.equalTo()(self.view)?.offset()(-kIphoneTabH)
        }
        
        myScrollView.addSubview(contentView)
        contentView.mas_makeConstraints { make in
            make?.edges.equalTo()(myScrollView)
            make?.width.equalTo()(myScrollView)
        }
        
        // 创建椭圆形的背景视图
        let ovalBackgroundView = UIView()
        ovalBackgroundView.backgroundColor = .clear
        contentView.addSubview(ovalBackgroundView)
        ovalBackgroundView.mas_makeConstraints { make in
            make?.top.equalTo()(contentView)?.offset()(0)
            make?.left.right().equalTo()(contentView)
            make?.height.mas_equalTo()(200) // 根据需求调整高度
        }
        
        DispatchQueue.main.async {
            let ovalPath = UIBezierPath(ovalIn: CGRect(x: -150, y: -230, width: self.contentView.frame.width + 300, height: 400))
            
            // 绘制椭圆形的灰色背景
            let ovalShapeLayer = CAShapeLayer()
            ovalShapeLayer.path = ovalPath.cgPath
            ovalShapeLayer.fillColor = UIColor(hexString: "ECECEC").cgColor
            
            ovalBackgroundView.layer.addSublayer(ovalShapeLayer)
        }
        
        let locationCoreDataInstance = LocationInfoManagement()
        let locationInfoInstance = locationCoreDataInstance.getLocationInfo()
        
        // Part 1 - Header Info
        // 1 - 1. 头像部分
        let headIcon_IV = UIImageView(image: UIImage(named: "ic_account_head_Icon"))
        contentView.addSubview(headIcon_IV)
        gHeadIcon_IV = headIcon_IV
        headIcon_IV.mas_makeConstraints { make in
            make?.top.equalTo()(contentView)?.offset()(30)
            make?.leading.equalTo()(contentView)?.offset()(edgeMargin)
            make?.width.height().mas_equalTo()(100)
        }
        
        // 1 - 2. 邮箱
        headEmail_Label = {
            let label = UILabel()
            label.textColor = UIColor(hexString: "666666")
            label.font = UIFont.systemFont(ofSize: fontHeaderSize)
            label.numberOfLines = 1;
            return label
        }()
        contentView.addSubview(headEmail_Label)
        headEmail_Label.mas_makeConstraints { make in
            make?.leading.equalTo()(headIcon_IV.mas_trailing)?.offset()(10)
            make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
            make?.centerY.equalTo()(headIcon_IV)
        }
        
        // 1 - 3. phone
        headPhone_Label = {
            let label = UILabel()
            label.textColor = UIColor(hexString: "666666")
            label.font = UIFont.systemFont(ofSize: fontHeaderSize)
            label.numberOfLines = 0
            return label
        }()
        contentView.addSubview(headPhone_Label)
        headPhone_Label.mas_makeConstraints { make in
            make?.top.equalTo()(headEmail_Label.mas_bottom)?.offset()(8)
            make?.leading.equalTo()(headIcon_IV.mas_trailing)?.offset()(10)
            make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
        }
        
        // 1 - 4 Name
        headName_Label = {
            let label = UILabel()
            label.textColor = UIColor(hexString: "666666")
            label.font = UIFont.boldSystemFont(ofSize: fontHeaderLargeSize)
            label.numberOfLines = 2
            label.lineBreakMode = .byCharWrapping
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5
            label.lineBreakMode = .byTruncatingTail
            return label
        }()
        contentView.addSubview(headName_Label)
        headName_Label.mas_makeConstraints { make in
            make?.leading.equalTo()(headIcon_IV.mas_trailing)?.offset()(10)
            make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
            make?.bottom.equalTo()(headEmail_Label.mas_top)?.offset()(2)
            make?.height.equalTo()(40)
        }
        
        // 1 - 5 Location
        headLocation_Label = {
            let label = UILabel()
            label.textColor = UIColor(hexString: "666666")
            label.font = UIFont.boldSystemFont(ofSize: fontHeaderSize)
            label.text = " "
            label.numberOfLines = 2
            label.lineBreakMode = .byTruncatingTail
            return label
        }()
        contentView.addSubview(headLocation_Label)
        headLocation_Label.mas_makeConstraints { make in
            make?.top.equalTo()(headPhone_Label.mas_bottom)?.offset()(8)
            make?.leading.equalTo()(headIcon_IV.mas_trailing)?.offset()(10)
            make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
        }
        headLocation_Label.text = "\(locationInfoInstance?.location_name ?? " ")!"
        
        // Part 2 = Update Account Info
        // 2 - 1 title
        let UpAcc_Title_Label: UILabel = {
            let label = UILabel()
            label.textColor = UIColor(hexString: "404040")
            label.font = UIFont.boldSystemFont(ofSize: fontTitleSize)
            label.text = LanguageHelper.getString(key: "Update_Account_Info")
            label.numberOfLines = 0
            return label
        }()
        contentView.addSubview(UpAcc_Title_Label)
        
        // 2 - 2 Save Btn
        let save_Btn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setTitle(LanguageHelper.getString(key: "Save"), for: .normal)
            btn.setTitleColor(UIColor.init(hexString: "404040"), for: .normal)
            btn.backgroundColor = UIColor(hexString: "CCE1FF")
            btn.layer.cornerRadius = 5
            btn.titleLabel?.font = UIFont.systemFont(ofSize: fontBtnSize)
            btn.titleLabel?.numberOfLines = 0
            btn.addTarget(self, action: #selector(saveAccountInfoBtnClicked(sender:)), for: .touchUpInside)
            return btn
        }()
        contentView.addSubview(save_Btn)
        UpAcc_Title_Label.mas_makeConstraints { make in
            make?.top.equalTo()(headLocation_Label.mas_bottom)?.offset()(50)
            make?.leading.equalTo()(headIcon_IV.mas_leading)
            make?.trailing.equalTo()(save_Btn.mas_leading)?.offset()(-2)
        }
        save_Btn.mas_makeConstraints { make in
            make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
            make?.width.mas_equalTo()(64)
            make?.height.mas_equalTo()(22)
            make?.centerY.equalTo()(UpAcc_Title_Label)
        }
        
        // 2 - 3 first Name
        contentView.addSubview(firstNameView)
        firstNameView.mas_makeConstraints { make in
            //两边间距25+两个view间距10=60. 这是两个view 所以这里的偏移量是-30
            make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30)
            make?.left.equalTo()(edgeMargin)
            make?.top.equalTo()(UpAcc_Title_Label.mas_bottom)?.offset()(20)
        }
        
        // 2 - 4 last Name
        contentView.addSubview(lastNameView)
        lastNameView.mas_makeConstraints { make in
            make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30)
            make?.left.equalTo()(firstNameView.mas_right)?.offset()(10)
            make?.top.equalTo()(firstNameView)
        }
        
        // 2 - 5 email
        contentView.addSubview(aEmailView)
        aEmailView.mas_makeConstraints { make in
            make?.top.equalTo()(lastNameView.mas_bottom)?.offset()(15)
            make?.left.equalTo()(self.view)?.offset()(edgeMargin)
            make?.right.equalTo()(self.view)?.offset()(-edgeMargin)
        }
        aEmailView.myTextField.keyboardType = UIKeyboardType.emailAddress

        // 弹窗提示
        gEmailAlert_Popup_Btn = {
            let btn = UIButton(type: .custom)
            btn.setImage(UIImage.init(named: "ic_account_turnonalert_Icon"), for: .normal)
            btn.addTarget(self, action: #selector(emailAlertPopupBoxBtnClicked(sender:)), for: .touchUpInside)
            return btn
        }()
        aEmailView.addSubview(gEmailAlert_Popup_Btn)
        
        gEmailAlert_Popup_Btn.mas_makeConstraints { make in
            make?.leading.equalTo()(aEmailView.label.mas_trailing)
            make?.width.height().equalTo()(30)
            make?.centerY.equalTo()(aEmailView.label)
        }
        
        // 2 - 6 phone
        phoneView.textField.inputView = UIView()
        phoneView.textField.delegate = self
        contentView.addSubview(phoneView)
        phoneView.mas_makeConstraints { make in
            make?.top.equalTo()(aEmailView.mas_bottom)?.offset()(15)
            make?.left.right().equalTo()(aEmailView)
            make?.height.mas_equalTo()(50)
        }
        phoneView.selCountryButton.addTarget(self, action: #selector(countryClick), for: .touchUpInside)
        phoneView.itemBlock = { [weak self] index in
            if index == 0 {
                //                //复原scrollView的位置
                self?.adjustScrollView(up: false)
            }
        }
        
        // 2 - 7 apartment
        contentView.addSubview(apartmentSuiteView)
        apartmentSuiteView.mas_makeConstraints { make in
            make?.top.equalTo()(phoneView.mas_bottom)?.offset()(15)
            make?.left.equalTo()(self.view)?.offset()(edgeMargin)
            make?.right.equalTo()(self.view)?.offset()(-edgeMargin)
        }
        
        // Part 3 - Update Laundry Card(s)
        // 3 - 1 title
        let laundryCard_Title_Label: UILabel = {
            let label = UILabel()
            label.textColor = UIColor(hexString: "404040")
            label.font = UIFont.boldSystemFont(ofSize: fontTitleSize)
            label.text = LanguageHelper.getString(key: "Update_Laundry_Cards")
            label.numberOfLines = 0
            return label
        }()
        contentView.addSubview(laundryCard_Title_Label)
        
        // 3 - 2 Save Btn
        let save_LaundryCard_Btn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setTitle(LanguageHelper.getString(key: "Save"), for: .normal)
            btn.setTitleColor(UIColor.init(hexString: "404040"), for: .normal)
            btn.backgroundColor = UIColor(hexString: "CCE1FF")
            btn.layer.cornerRadius = 5
            btn.titleLabel?.font = UIFont.systemFont(ofSize: fontBtnSize)
            btn.titleLabel?.numberOfLines = 0
            btn.addTarget(self, action: #selector(saveLaundryCardInfoBtnClicked(sender:)), for: .touchUpInside)
            return btn
        }()
        contentView.addSubview(save_LaundryCard_Btn)
        laundryCard_Title_Label.mas_makeConstraints { make in
            make?.top.equalTo()(apartmentSuiteView.mas_bottom)?.offset()(sectionSeparateSpace)
            make?.leading.equalTo()(headIcon_IV.mas_leading)
            make?.trailing.equalTo()(save_LaundryCard_Btn.mas_leading)?.offset()(-2)
        }
        save_LaundryCard_Btn.mas_makeConstraints { make in
            make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
            make?.width.mas_equalTo()(64)
            make?.height.mas_equalTo()(22)
            make?.centerY.equalTo()(laundryCard_Title_Label)
        }
        
        // 3 - 3 sub Title
        let sub_LaundryCard_Title_Label: UILabel = {
            let label = UILabel()
            label.textColor = UIColor(hexString: "666666")
            label.font = UIFont.systemFont(ofSize: fontSubTitleSize)
            label.text = LanguageHelper.getString(key: "Users_can_add_up_to_five_5_cards_per_account")
            label.numberOfLines = 0
            return label
        }()
        contentView.addSubview(sub_LaundryCard_Title_Label)
        sub_LaundryCard_Title_Label.mas_makeConstraints { make in
            make?.top.equalTo()(laundryCard_Title_Label.mas_bottom)?.offset()(10)
            make?.leading.equalTo()(headIcon_IV.mas_leading)
            make?.trailing.equalTo()(save_LaundryCard_Btn.mas_trailing)
        }
        g_Sub_LaundryCard_Title_Label = sub_LaundryCard_Title_Label
        
        // 3 - 6 新增卡按钮
        g_AddNew_LaundryCard_Btn = {
            let btn = UIButton(type: .custom)
            btn.setTitle(LanguageHelper.getString(key: "Add_another"), for: .normal)
            btn.setTitleColor(UIColor.init(hexString: "3974C6"), for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: fontBtnSize)
            btn.titleLabel?.numberOfLines = 0
            btn.addTarget(self, action: #selector(addNewLaundryCardInfoBtnClicked(sender:)), for: .touchUpInside)
            return btn
        }()
        contentView.addSubview(g_AddNew_LaundryCard_Btn)
        g_AddNew_LaundryCard_Btn.mas_makeConstraints { make in
            make?.top.equalTo()(sub_LaundryCard_Title_Label.mas_bottom)?.offset()(10)
            make?.leading.equalTo()(self.view)?.offset()(edgeMargin)
        }
        addNewLaundryCardFields()
        
        // part 4 - Turn On CleanAlert
        // 给 ImageView 添加点击事件
        gTurnOnCleanAlert_Checkbox_IV = {
            let imageView = UIImageView()
            imageView.image = UIImage(named: "Ic_home_rememberme_unselected")
            imageView.isUserInteractionEnabled = true
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(turnOnCleanAlertTapped))
            imageView.addGestureRecognizer(tapGestureRecognizer)
            return imageView
        }()
        
        // 给 Label 添加点击事件
        gturnOnCleanAlert_Checkbox_Label = {
            let label = UILabel()
            label.textColor = UIColor(hexString: "8C8C8C")
            label.font = UIFont.boldSystemFont(ofSize: fontBtnSize)
            label.text = LanguageHelper.getString(key: "Turn_On_CleanAlert")
            label.isUserInteractionEnabled = true // 启用用户交互
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(turnOnCleanAlertTapped))
            label.addGestureRecognizer(tapGestureRecognizer)
            return label
        }()
        
        // i 点击弹窗
        gTurnOnCleanAlert_Popup_Btn = {
            let btn = UIButton(type: .custom)
            btn.setImage(UIImage.init(named: "ic_account_turnonalert_Icon"), for: .normal)
            btn.addTarget(self, action: #selector(turnOnCleanAlertPopupBoxBtnClicked(sender:)), for: .touchUpInside)
            return btn
        }()
        
        contentView.addSubview(gTurnOnCleanAlert_Checkbox_IV)
        contentView.addSubview(gturnOnCleanAlert_Checkbox_Label)
        contentView.addSubview(gTurnOnCleanAlert_Popup_Btn)
        gTurnOnCleanAlert_Checkbox_IV.mas_makeConstraints { make in
            make?.leading.equalTo()(headIcon_IV.mas_leading)
            make?.width.height().equalTo()(20)
            make?.top.equalTo()(g_AddNew_LaundryCard_Btn.mas_bottom)?.offset()(10)
        }
        gturnOnCleanAlert_Checkbox_Label.mas_makeConstraints { make in
            make?.leading.equalTo()(gTurnOnCleanAlert_Checkbox_IV.mas_trailing)?.offset()(5)
            make?.centerY.equalTo()(gTurnOnCleanAlert_Checkbox_IV)
            make?.height.equalTo()(30)
        }
        gTurnOnCleanAlert_Popup_Btn.mas_makeConstraints { make in
            make?.leading.equalTo()(gturnOnCleanAlert_Checkbox_Label.mas_trailing)?.offset()(3)
            make?.width.height().equalTo()(30)
            make?.centerY.equalTo()(gTurnOnCleanAlert_Checkbox_IV)
        }
        
        if (isSupportAtriumAccount == "1" || isSupportTouchnetWallet == "1") && isOneCardAlreadyBind == "1" {
            // part 5 - OneCard
            gCampusCardTitleLabel = {
                let label = UILabel()
                label.textColor = UIColor(hexString: "404040")
                label.font = UIFont.boldSystemFont(ofSize: fontTitleSize)
                label.text = LanguageHelper.getString(key: "key_CampusCard")
                label.numberOfLines = 0
                return label
            }()
            contentView.addSubview(gCampusCardTitleLabel ?? UILabel())
            gCampusCardTitleLabel?.mas_makeConstraints { make in
                make?.top.equalTo()(gTurnOnCleanAlert_Checkbox_IV.mas_bottom)?.offset()(sectionSeparateSpace)
                make?.leading.equalTo()(headIcon_IV.mas_leading)
                make?.trailing.equalTo()(self.view)
            }
            
            // 5 - 2 Deleted BTN
            gDeleteOneCardBtn = {
                let btn = UIButton(type: .custom)
                btn.setTitle(LanguageHelper.getString(key: "MulT_Delete"), for: .normal)
                btn.setTitleColor(UIColor.init(hexString: "404040"), for: .normal)
                btn.backgroundColor = UIColor(hexString: "F7A1A1")
                btn.layer.cornerRadius = 5
                btn.titleLabel?.font = UIFont.systemFont(ofSize: fontBtnSize)
                btn.titleLabel?.numberOfLines = 0
                btn.addTarget(self, action: #selector(deleteOneCardBtnClicked(sender:)), for: .touchUpInside)
                return btn
            }()
            contentView.addSubview(gDeleteOneCardBtn ?? UIButton())
            gDeleteOneCardBtn?.mas_makeConstraints { make in
                make?.trailing.equalTo()(contentView)?.offset()(-edgeMargin)
                make?.width.mas_equalTo()(64)
                make?.height.mas_equalTo()(22)
                make?.centerY.equalTo()(gCampusCardTitleLabel)
            }
            
            // 5 - 3 sub Title
            gOneCardSubTitleLabel = {
                let label = UILabel()
                label.textColor = UIColor(hexString: "666666")
                label.font = UIFont.systemFont(ofSize: fontSubTitleSize)
                label.text = LanguageHelper.getString(key: "Users_can_only_add_one_card_per_account")
                label.numberOfLines = 0
                return label
            }()
            contentView.addSubview(gOneCardSubTitleLabel ?? UILabel())
            gOneCardSubTitleLabel?.mas_makeConstraints { make in
                make?.top.equalTo()(gCampusCardTitleLabel?.mas_bottom)?.offset()(10)
                make?.leading.equalTo()(headIcon_IV.mas_leading)
                make?.trailing.equalTo()(gDeleteOneCardBtn?.mas_trailing)
            }
            
            // 5 - 4 Card Number
            gCardNumberLabel = {
                let label = UILabel()
                label.textColor = UIColor(hexString: "666666")
                label.font = UIFont.systemFont(ofSize: fontTitleSize)
                label.text = LanguageHelper.getString(key: "Card_Number")
                label.numberOfLines = 0
                return label
            }()
            contentView.addSubview(gCardNumberLabel ?? UILabel())
            gCardNumberLabel?.mas_makeConstraints { make in
                make?.top.equalTo()(gOneCardSubTitleLabel?.mas_bottom)?.offset()(15)
                make?.leading.equalTo()(headIcon_IV.mas_leading)
                make?.trailing.equalTo()(gDeleteOneCardBtn?.mas_trailing)
            }
            gCardNumberLabel?.text = LanguageHelper.getString(key: "Card_Number") + self.gOneCardNumber
        }
        
        // part 6 - Manage Account
        // 6 - 1 title
        gManageAccountTitleLabel = {
            let label = UILabel()
            label.textColor = UIColor(hexString: "404040")
            label.font = UIFont.boldSystemFont(ofSize: fontTitleSize)
            label.text = LanguageHelper.getString(key: "Manage_Account")
            label.numberOfLines = 0
            return label
        }()
        contentView.addSubview(gManageAccountTitleLabel)
        gManageAccountTitleLabel.mas_makeConstraints { make in
            if (isSupportAtriumAccount == "1" || isSupportTouchnetWallet == "1") && isOneCardAlreadyBind == "1" {
                make?.top.equalTo()(gCardNumberLabel?.mas_bottom)?.offset()(sectionSeparateSpace)
            }else {
                make?.top.equalTo()(gTurnOnCleanAlert_Checkbox_IV.mas_bottom)?.offset()(sectionSeparateSpace)
            }
            make?.leading.equalTo()(headIcon_IV.mas_leading)
            make?.trailing.equalTo()(self.view)
        }
        
        gEditCreditCardBtn = UIButton(type: .custom)
        gEditCreditCardBtn.setTitle(LanguageHelper.getString(key: "Edit_Credit_Card"), for: .normal)
        gEditCreditCardBtn.setTitleColor(UIColor(hexString: "404040"), for: .normal)
        gEditCreditCardBtn.backgroundColor = UIColor(hexString: "CCE1FF")
        gEditCreditCardBtn.titleLabel?.font = UIFont.systemFont(ofSize: fontBtnSize)
        gEditCreditCardBtn.layer.cornerRadius = 5
        gEditCreditCardBtn.addTarget(self, action: #selector(editCreditCardBtnClick), for: .touchUpInside)
        contentView.addSubview(gEditCreditCardBtn)
        
        if isSupportAtriumAccount == "1" || isSupportTouchnetWallet == "1" {
            if gAddCampusCardBtn != nil {
                gAddCampusCardBtn?.removeFromSuperview()
                gAddCampusCardBtn = nil
            }
            gAddCampusCardBtn = {
                let btn = UIButton(type: .custom)
                btn.setTitle(LanguageHelper.getString(key: "Add_Campus_Card"), for: .normal)
                btn.setTitleColor(UIColor.init(hexString: "404040"), for: .normal)
                btn.titleLabel?.font = UIFont.systemFont(ofSize: fontBtnSize)
                btn.titleLabel?.numberOfLines = 0
                btn.layer.cornerRadius = 5
                btn.layer.borderWidth = 1
                btn.layer.borderColor = UIColor.init(hexString: "B3B3B3").cgColor
                btn.addTarget(self, action: #selector(addNewCardBtnClicked), for: .touchUpInside)
                return btn
            }()
            contentView.addSubview(gAddCampusCardBtn ?? UIButton())
            
            // Edit_Credit_Card
            gEditCreditCardBtn.mas_makeConstraints { make in
                //两边间距25+两个view间距10=60. 这是两个view 所以这里的偏移量是-30
                make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30)
                make?.left.equalTo()(edgeMargin)
                make?.top.equalTo()(gManageAccountTitleLabel.mas_bottom)?.offset()(10)
                make?.height.equalTo()(26)
            }
            
            // Add_Campus_Card
            gAddCampusCardBtn?.mas_makeConstraints { make in
                make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30)
                make?.left.equalTo()(gEditCreditCardBtn.mas_right)?.offset()(10)
                make?.top.equalTo()(gEditCreditCardBtn)
                make?.height.equalTo()(26)
            }
        }else {
            if gAddCampusCardBtn != nil {
                gAddCampusCardBtn?.removeFromSuperview()
                gAddCampusCardBtn = nil
            }
            gAddCampusCardBtn?.isHidden = true
            
            
            gEditCreditCardBtn.mas_makeConstraints { make in
                make?.top.equalTo()(gManageAccountTitleLabel.mas_bottom)?.offset()(10)
                make?.left.equalTo()(contentView)?.offset()(25)
                make?.right.equalTo()(contentView)?.offset()(-25)
                make?.height.equalTo()(26)
            }
        }
        
        // 6 - 2
        gResetPassword_Btn = {
            let btn = UIButton(type: .custom)
            btn.setTitle(LanguageHelper.getString(key: "Reset_Password"), for: .normal)
            btn.setTitleColor(UIColor.init(hexString: "404040"), for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: fontBtnSize)
            btn.titleLabel?.numberOfLines = 0
            btn.layer.cornerRadius = 5
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.init(hexString: "B3B3B3").cgColor
            btn.addTarget(self, action: #selector(resetPasswordBtnClicked(sender:)), for: .touchUpInside)
            return btn
        }()
        contentView.addSubview(gResetPassword_Btn)
        gResetPassword_Btn.mas_makeConstraints { make in
            //两边间距25+两个view间距10=60. 这是两个view 所以这里的偏移量是-30
            make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30)
            make?.height.equalTo()(26)
            make?.left.equalTo()(edgeMargin)
            make?.top.equalTo()(gEditCreditCardBtn.mas_bottom)?.offset()(20)
        }
        
        // 6 - 2
        let deactivate_Btn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setTitle(LanguageHelper.getString(key: "Deactivate"), for: .normal)
            btn.setTitleColor(UIColor.init(hexString: "404040"), for: .normal)
            //            btn.backgroundColor = UIColor(hexString: "CCE1FF")
            btn.layer.cornerRadius = 5
            btn.titleLabel?.font = UIFont.systemFont(ofSize: fontBtnSize)
            btn.titleLabel?.numberOfLines = 0
            btn.backgroundColor = UIColor.init(hexString: "F7A1A1")
            btn.addTarget(self, action: #selector(deactivateBtnClicked(sender:)), for: .touchUpInside)
            return btn
        }()
        contentView.addSubview(deactivate_Btn)
        deactivate_Btn.mas_makeConstraints { make in
            make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30)
            make?.height.equalTo()(26)
            make?.left.equalTo()(gResetPassword_Btn.mas_right)?.offset()(10)
            make?.top.equalTo()(gResetPassword_Btn)
        }
        
        contentView.mas_makeConstraints { make in
            make?.bottom.equalTo()(gResetPassword_Btn.mas_bottom)?.offset()(30)
        }
    }
    
    @objc func turnOnCleanAlertTapped() {
        print("turnOnCleanAlertTapped!")
        
        // 根据当前的图片状态切换图片
        if gTurnOnCleanAlert_Checkbox_IV.image == UIImage(named: "Ic_home_rememberme_unselected") {
            gTurnOnCleanAlert_Checkbox_IV.image = UIImage(named: "Ic_home_rememberme_selected")
            turnOnAlertFlag = "1"
        } else {
            gTurnOnCleanAlert_Checkbox_IV.image = UIImage(named: "Ic_home_rememberme_unselected")
            turnOnAlertFlag = "0"
        }
    }
    
    
    
    @objc func emailAlertPopupBoxBtnClicked(sender: UIButton) {
        debugPrint("emailAlertPopupBoxBtnClicked")
        
        if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            
            //添加背景遮罩view
            let bgView = UIView(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
            bgView.backgroundColor = UIColor.black
            bgView.alpha = 0.4
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pwdTagBGViewClick(_:)))
            bgView.addGestureRecognizer(tapGesture)
            bgView.isUserInteractionEnabled = true
            
            keyWindow.addSubview(bgView)
            
            var curRect = gEmailAlert_Popup_Btn.bounds
            curRect.size.width = 260
            curRect.origin.x = curRect.origin.x - 40
            let convertedFrame = gEmailAlert_Popup_Btn.convert(curRect, to: keyWindow)
            
            //提示的view
            let promptView = UIView.init(frame: CGRect(x: convertedFrame.origin.x, y: convertedFrame.origin.y - 60, width: convertedFrame.size.width, height: 50))
            promptView.backgroundColor = .white
            promptView.layer.cornerRadius = 10
            promptView.tag = 300
            keyWindow.addSubview(promptView)
            
            let primptLabel = UILabel.init()
            promptView.addSubview(primptLabel)
            primptLabel.font = UIFont.systemFont(ofSize: fontSubTitleSize)
            primptLabel.numberOfLines = 0
            primptLabel.textColor = UIColor(hexString: "404040")
            primptLabel.text = LanguageHelper.getString(key: "You_will_need_to_login_again_once_email_address_is")
            primptLabel.mas_makeConstraints { make in
                make?.left.equalTo()(promptView)?.offset()(10)
                make?.right.equalTo()(promptView)?.offset()(-10)
                make?.centerY.equalTo()(promptView)
            }
        }
    }

    
    func bindTouchnetCampusCard() {
        debugPrint("bindTouchnetCampusCard")
        
        let title:String = LanguageHelper.getString(key: "Add_Campus_Card")
        let message:String = LanguageHelper.getString(key: "Login_to_your_campus_account_account_below_to_add_your_new_card")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancel:String = LanguageHelper.getString(key: "Cancel")
        
        alert.addTextField { (textField) in
            textField.placeholder = LanguageHelper.getString(key: "Username")
            self.alertAddCampusCardUserNameTextField = textField
            textField.delegate = self
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = LanguageHelper.getString(key: "Password")
            textField.isSecureTextEntry = true
            self.alertAddCampusCardPasswordTextField = textField
            textField.delegate = self
        }
        
        let actOK = UIAlertAction(title: LanguageHelper.getString(key: "Confirm"), style: .default, handler: { [weak alert] (_) in
            let usernameTextField = alert?.textFields![0] // 第一个 TextField
            let passwordTextField = alert?.textFields![1] // 第二个 TextField
            
            if !ReachabilitySwift.isConnectedToNetwork() {
                let title = LanguageHelper.getString(key: "No_Internet_Connection")
                let msg = LanguageHelper.getString(key: "Make_sure_your_device_is_connected_to_the_internet")
                let actionOK = UIAlertAction.init(title: LanguageHelper.getString(key: "OK"), style: .default) { [weak self] (action) in
                    self?.navigationController?.popViewController(animated: true)
                }
                CommonUtil.showAlert(sender: self, title: title, message: msg, button1: actionOK, button2: nil)
                return
            }
            
            if let username = usernameTextField?.text, let password = passwordTextField?.text {
                debugPrint("Username: \(username), Password: \(password)")
                
                let APICon = APIConnectionWithTimeOut();
                CommonUtil.showActivityIndicator(sourceView: self.view, spinner: self.spinner, loadingView: self.loadingView)
                APICon.bindTouchnetCardAPI(sender: self, cardNumber: username, password: password, completionHandler: {(responseObject, error, errorJson) in
                    CommonUtil.hideActivityIndicator(spinner: self.spinner, loadingView: self.loadingView)
                    
                    debugPrint("deactivateBtnClicked - closeAccountInfoAPI - responseObject: \(String(describing: responseObject))")
                    
                    if let jsonResponse = responseObject{
                        let jsonObject = JSON(jsonResponse)
                        let status = jsonObject["status"].intValue
                        if status == 200 {
                            self.getAccountLatestInfo()
                            self.contentView.layoutIfNeeded()
                        }else {
                            // TODO: 需要提示不？
                            // CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Profile_Update_Failed"), message: LanguageHelper.getString(key: "Your_profile_was_unable_to_update_at_this_time_Please_try"), button1: LanguageHelper.getString(key: "OK"), button2: nil)
                        }
                    }
                    if error != nil {
                        guard let errMsg = errorJson!["message"].string else {
                            // TODO: 如果账户密码错误, Server不返回错误
                            return
                        }
                        CommonUtil.showAlert(sender: self, title: errMsg, message: "", button1: LanguageHelper.getString(key: "OK"), button2: nil)
                    }
                })
            }
        })
        addCampusCardNamePasswordAAction = actOK
        addCampusCardNamePasswordAAction?.isEnabled = false
        
        alert.addAction(actOK)
        let actCancel = UIAlertAction(title: cancel, style: .cancel, handler:nil)
        alert.addAction(actCancel)
        alert.preferredAction = actOK
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func addNewCardBtnClicked() {
        debugPrint("addNewCardBtnClicked ----- ")
        
        if isSupportTouchnetWallet == "1" {
            isSupportAddCampusCardUserName = false
            isSupportAddCampusCardPassword = false
            // 如果是touchnet校园卡
            bindTouchnetCampusCard()
        }else if isSupportAtriumAccount == "1" && self.gAttriumBindUrl != "" {
            // 如果是Atrium校园卡
            let myAccountWebVC = MobieAccessWebViewController()
            myAccountWebVC.setValues(WithParameters: self.gAttriumBindUrl, title: "", fromType: .back)
            self.navigationController?.pushViewController(myAccountWebVC, animated: true)
        }else {
            print("Error! - addNewCardBtnClicked Unkown Campus Payment！！！！！")
        }
    }
    
    @objc func editCreditCardBtnClick() {
        debugPrint("editCreditCardBtnClick")
        self.view.endEditing(true)
        if !ReachabilitySwift.isConnectedToNetwork() {
            ReachabilitySwift.showConnectivityWarningDialog(sender: self)
            return
        }
        
        self.bandCreditCard(isBack: true)
    }
    
    @objc func saveAccountInfoBtnClicked(sender: UIButton) {
        debugPrint("saveAccountInfoBtnClicked")
        self.view.endEditing(true)
        
        if !ReachabilitySwift.isConnectedToNetwork() {
            let title = LanguageHelper.getString(key: "No_Internet_Connection")
            let msg = LanguageHelper.getString(key: "Make_sure_your_device_is_connected_to_the_internet")
            let actionOK = UIAlertAction.init(title: LanguageHelper.getString(key: "OK"), style: .default) {(action) in }
            CommonUtil.showAlert(sender: self, title: title, message: msg, button1: actionOK, button2: nil)
            return
        }
        
        // 1. 检验邮箱和电话是否合法
        if(!CommonUtil.isValidEmail(testStr: aEmailView.myTextField.text ?? "")) {
            //判断邮箱格式
            let alertAction = UIAlertAction(title: LanguageHelper.getString(key: "Mul_OK"), style: UIAlertAction.Style.default, handler: {
                (action:UIAlertAction!) -> Void in
                self.aEmailView.myTextField.becomeFirstResponder()
            })
            alertAction.setValue(Configuration.shared.signInBtnColor(), forKey:"titleTextColor")
            let Please_enter_valid_email_address:String = LanguageHelper.getString(key: "Please_enter_valid_email_address")
            CommonUtil.showAlert(sender: self, title: Please_enter_valid_email_address, message: "", button1: alertAction, button2: nil)
            return
        }else if !self.validMobile() {
            //手机号验证
            return
        }
        if let text = apartmentSuiteView.myTextField.text, text.count > 10 {
            apartmentSuiteView.myTextField.becomeFirstResponder()
            let no_more_than_10:String = LanguageHelper.getString(key: "Please_enter_no_more_than_10_characters")
            CommonUtil.showAlert(sender: self, title: no_more_than_10, message: "", button1: LanguageHelper.getString(key: "OK"), button2: nil)
            return
        }
        
        let APICon = APIConnectionWithTimeOut();
        CommonUtil.showActivityIndicator(sourceView: self.view, spinner: spinner, loadingView: loadingView)
        
        APICon.updateAccountInfoAPI(sender: self, first_name: firstNameView.myTextField.text ?? "", last_name: lastNameView.myTextField.text ?? "", email: aEmailView.myTextField.text ?? "", suite: apartmentSuiteView.myTextField.text ?? "") { (responseObject, error, errorJson) in
            
            CommonUtil.hideActivityIndicator(spinner: self.spinner, loadingView: self.loadingView)
            
            debugPrint("saveAccountInfoBtnClicked - updateAccountInfoAPI - responseObject: \(String(describing: responseObject))")
            
            if let jsonResponse = responseObject{
                let jsonObject = JSON(jsonResponse)
                let status = jsonObject["status"].intValue
                if status == 200 {
                    let alertTitle = LanguageHelper.getString(key: "Profile_Updated")
                    let alertMsg = LanguageHelper.getString(key: "You_have_successfully_updated_your_profile")
                    CommonUtil.showAlert_2BtnHandler(sender: self, title: alertTitle, message: alertMsg, button1: LanguageHelper.getString(key: "OK"), button2: nil) { action in
                        self.getAccountLatestInfo()
                        self.contentView.layoutIfNeeded()
                    }
                }else {
                    CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Profile_Update_Failed"), message: LanguageHelper.getString(key: "Your_profile_was_unable_to_update_at_this_time_Please_try"), button1: LanguageHelper.getString(key: "OK"), button2: nil)
                }
            }
            if error != nil {
                if let errorMessage = errorJson {
                    DDLogVerbose("Error saveAccountInfoBtnClicked errorMessage:errorCode:\(String(describing: error?.code)), message:\(errorMessage))")
                    CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Profile_Update_Failed"), message: LanguageHelper.getString(key: "Your_profile_was_unable_to_update_at_this_time_Please_try"), button1: LanguageHelper.getString(key: "OK"), button2: nil)
                }
            }
        }
    }
    
    @objc func countryClick() {
        self.adjustScrollView(up: true)
    }
    
    //MARK: - logic
    func adjustScrollView(up:Bool){
        if up{
            //升高
            originalContentOffset = self.myScrollView.contentOffset
            let newContentOffset = CGPoint(x: originalContentOffset.x, y: originalContentOffset.y + 150)
            self.myScrollView.setContentOffset(newContentOffset, animated: true)
            self.phoneView.optionsView.show()
        }else{
            //降低 选择国家的view消失有个动画 这里加个延时调整一下
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.myScrollView.setContentOffset(self.originalContentOffset, animated: true)
            }
        }
    }
    
    @objc func saveLaundryCardInfoBtnClicked(sender: UIButton) {
        debugPrint("saveLaundryCardInfoBtnClicked")
        self.view.endEditing(true)
        
        if !ReachabilitySwift.isConnectedToNetwork() {
            let title = LanguageHelper.getString(key: "No_Internet_Connection")
            let msg = LanguageHelper.getString(key: "Make_sure_your_device_is_connected_to_the_internet")
            let actionOK = UIAlertAction.init(title: LanguageHelper.getString(key: "OK"), style: .default) {(action) in }
            CommonUtil.showAlert(sender: self, title: title, message: msg, button1: actionOK, button2: nil)
            return
        }
        
        var card_list: [[String: String]] = []
        
        // 获取每个 LC 和 CVC 的值
        var laundryCards: [(lc: String, cvc: String)] = []
        for (index, lcView) in LC_Optional_Views.enumerated() {
            let lcText = lcView.myTextField.text ?? ""
            let cvcText = CVC_Optional_Views[index].myTextField.text ?? ""
            laundryCards.append((lc: lcText, cvc: cvcText))
        }
        
        // 检查是否有任何一对 LC 和 CVC 中只有一个为空
        for card in laundryCards {
            if (card.lc.isEmpty && !card.cvc.isEmpty) || (!card.lc.isEmpty && card.cvc.isEmpty) {
                CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Both_laundry_card_number_and_CVC_are_required"), message: "", button1: LanguageHelper.getString(key: "OK"), button2: nil)
                return
            }
        }
  
        for card in laundryCards {
            if !card.lc.isEmpty && !card.cvc.isEmpty {
                let cardDict: [String: String] = [
                    "card_number": card.lc,
                    "cvc": card.cvc
                ]
                card_list.append(cardDict)
            }
        }
        
        let APICon = APIConnectionWithTimeOut();
        CommonUtil.showActivityIndicator(sourceView: self.view, spinner: spinner, loadingView: loadingView)
        APICon.updateLaundryCardAPI(sender: self, alert: turnOnAlertFlag, card_list: card_list) { (responseObject, error, errorJson) in
            CommonUtil.hideActivityIndicator(spinner: self.spinner, loadingView: self.loadingView)
            
            debugPrint("saveLaundryCardInfoBtnClicked - updateLaundryCardAPI - responseObject: \(String(describing: responseObject))")
            
            if let jsonResponse = responseObject{
                let jsonObject = JSON(jsonResponse)
                let status = jsonObject["status"].intValue
                if status == 200 {
                    let alertTitle = LanguageHelper.getString(key: "Profile_Updated")
                    let alertMsg = LanguageHelper.getString(key: "You_have_successfully_updated_your_profile")
                    CommonUtil.showAlert_2BtnHandler(sender: self, title: alertTitle, message: alertMsg, button1: LanguageHelper.getString(key: "OK"), button2: nil) { action in
                        self.getAccountLatestInfo()
                        self.contentView.layoutIfNeeded()
                    }
                }else {
                    CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Profile_Update_Failed"), message: LanguageHelper.getString(key: "Your_profile_was_unable_to_update_at_this_time_Please_try"), button1: LanguageHelper.getString(key: "OK"), button2: nil)
                }
            }
            if error != nil {
                if let errorMessage = errorJson {
                    DDLogVerbose("Error saveAccountInfoBtnClicked errorMessage:errorCode:\(String(describing: error?.code)), message:\(errorMessage))")
                    CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Profile_Update_Failed"), message: LanguageHelper.getString(key: "Your_profile_was_unable_to_update_at_this_time_Please_try"), button1: LanguageHelper.getString(key: "OK"), button2: nil)
                }
            }
        }
    }
    
    @objc func deleteOneCardBtnClicked(sender: UIButton) {
        debugPrint("deleteOneCardBtnClicked")
        
        if !ReachabilitySwift.isConnectedToNetwork() {
            let title = LanguageHelper.getString(key: "No_Internet_Connection")
            let msg = LanguageHelper.getString(key: "Make_sure_your_device_is_connected_to_the_internet")
            let actionOK = UIAlertAction.init(title: LanguageHelper.getString(key: "OK"), style: .default) {(action) in }
            CommonUtil.showAlert(sender: self, title: title, message: msg, button1: actionOK, button2: nil)
            return
        }
        
        let deleteOneCardStr:String = LanguageHelper.getString(key: "Delete_Campus_Card")
        let message:String = LanguageHelper.getString(key: "Are_you_sure_to_delete_the_Campus_Card")
        let alert = UIAlertController(title: deleteOneCardStr, message: message, preferredStyle: .alert)
        
        let cancel:String = LanguageHelper.getString(key: "Cancel")
        let actOK = UIAlertAction(title: LanguageHelper.getString(key: "Confirm"), style: .default, handler: { [weak alert] (_) in
            
            var cardType = "0"
            if self.isSupportAtriumAccount == "1" {
                cardType = "0"
            }else if self.isSupportTouchnetWallet == "1" {
                cardType = "1"
            }
            
            let APICon = APIConnectionWithTimeOut();
            CommonUtil.showActivityIndicator(sourceView: self.view, spinner: self.spinner, loadingView: self.loadingView)
            APICon.delCampusCardAPI(sender: self, cardNumber: self.gOneCardNumber, cardType: cardType, completionHandler: {(responseObject, error, errorJson) in
                CommonUtil.hideActivityIndicator(spinner: self.spinner, loadingView: self.loadingView)
                
                debugPrint("deactivateBtnClicked - closeAccountInfoAPI - responseObject: \(String(describing: responseObject))")
                
                if let jsonResponse = responseObject{
                    let jsonObject = JSON(jsonResponse)
                    let status = jsonObject["status"].intValue
                    if status == 200 {
                        self.isOneCardAlreadyBind = "0"
                        self.getAccountLatestInfo()
                        self.contentView.layoutIfNeeded()
                    }else {
                        // TODO: 这里需要提示不？
                        // CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Profile_Update_Failed"), message: LanguageHelper.getString(key: "Your_profile_was_unable_to_update_at_this_time_Please_try"), button1: LanguageHelper.getString(key: "OK"), button2: nil)
                    }
                }
                if error != nil {
                    guard let errMsg = errorJson!["message"].string else {
                        return
                    }
                    CommonUtil.showAlert(sender: self, title: errMsg, message: "", button1: LanguageHelper.getString(key: "OK"), button2: nil)
                }
            })
        })
        alert.addAction(actOK)
        let actCancel = UIAlertAction(title: cancel, style: .cancel, handler:nil)
        alert.addAction(actCancel)
        alert.preferredAction = actOK
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func addNewLaundryCardInfoBtnClicked(sender: UIButton) {
        debugPrint("addNewLaundryCardInfoBtnClicked")
        
        guard LC_Optional_Views.count < maxLaundryCards else { return }
        addNewLaundryCardFields()
    }
    
    @objc func turnOnCleanAlertPopupBoxBtnClicked(sender: UIButton) {
        debugPrint("turnOnCleanAlertPopupBoxBtnClicked")
        
        if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            
            //添加背景遮罩view
            let bgView = UIView(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
            bgView.backgroundColor = UIColor.black
            bgView.alpha = 0.4
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pwdTagBGViewClick(_:)))
            bgView.addGestureRecognizer(tapGesture)
            bgView.isUserInteractionEnabled = true
            
            keyWindow.addSubview(bgView)
            
            var curRect = gTurnOnCleanAlert_Popup_Btn.bounds
            curRect.size.width = 260
            curRect.origin.x = curRect.origin.x - 110
            let convertedFrame = gTurnOnCleanAlert_Popup_Btn.convert(curRect, to: keyWindow)
            
            //提示的view
            let promptView = UIView.init(frame: CGRect(x: convertedFrame.origin.x, y: convertedFrame.origin.y - 60, width: convertedFrame.size.width, height: 50))
            promptView.backgroundColor = .white
            promptView.layer.cornerRadius = 10
            promptView.tag = 300
            keyWindow.addSubview(promptView)
            
            let primptLabel = UILabel.init()
            promptView.addSubview(primptLabel)
            primptLabel.font = UIFont.systemFont(ofSize: fontSubTitleSize)
            primptLabel.numberOfLines = 0
            primptLabel.textColor = UIColor(hexString: "404040")
            primptLabel.text = LanguageHelper.getString(key: "Receive_an_SMS_alert_when_your_laundry_cycle_is_complete")
            primptLabel.mas_makeConstraints { make in
                make?.left.equalTo()(promptView)?.offset()(10)
                make?.right.equalTo()(promptView)?.offset()(-10)
                make?.centerY.equalTo()(promptView)
            }
            
        }
    }
    
    //遮罩背景的点击方法
    @objc func pwdTagBGViewClick(_ gesture: UITapGestureRecognizer) {
        if let tappedView = gesture.view {
            
            //删除背景图
            tappedView.removeFromSuperview()
            
            //删除显示在window上面的view
            if let promptView = UIApplication.shared.keyWindow?.viewWithTag(300) {
                promptView.removeFromSuperview()
            }
            
        }
    }
    
    @objc func resetPasswordBtnClicked(sender: UIButton) {
        debugPrint("resetPasswordBtnClicked")
        
        self.navigationController?.pushViewController(KSResetPasswordViewController.init(), animated: true)
    }
    
    @objc func deactivateBtnClicked(sender: UIButton) {
        debugPrint("deactivateBtnClicked")
        
        let deactivateAccount:String = LanguageHelper.getString(key: "Deactivate_Account")
        let enterPasswordDetivate:String = LanguageHelper.getString(key: "Please_enter_your_password_below_to_deactivate")
        let alert = UIAlertController(title: deactivateAccount, message: enterPasswordDetivate, preferredStyle: .alert)
        
        let cancel:String = LanguageHelper.getString(key: "Cancel")
        
        alert.addTextField(configurationHandler: {(textField) -> Void in
            // textField.placeholder = "Enter your password"
            textField.isSecureTextEntry = true
            textField.keyboardType = UIKeyboardType.default
            // textField.borderStyle = .roundedRect
            textField.translatesAutoresizingMaskIntoConstraints = false
            self.alertDeactAccTextField = textField
            textField.delegate = self
        })
        let actOK = UIAlertAction(title: LanguageHelper.getString(key: "Confirm"), style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            if var labelcontent = textField!.text {
                debugPrint("---labelcontent: \(labelcontent)")
                
                if !ReachabilitySwift.isConnectedToNetwork() {
                    let title = LanguageHelper.getString(key: "No_Internet_Connection")
                    let msg = LanguageHelper.getString(key: "Make_sure_your_device_is_connected_to_the_internet")
                    let actionOK = UIAlertAction.init(title: LanguageHelper.getString(key: "OK"), style: .default) {(action) in }
                    CommonUtil.showAlert(sender: self, title: title, message: msg, button1: actionOK, button2: nil)
                    return
                }
                
                let APICon = APIConnectionWithTimeOut();
                CommonUtil.showActivityIndicator(sourceView: self.view, spinner: self.spinner, loadingView: self.loadingView)
                APICon.closeAccountInfoAPI(sender: self, password: labelcontent) { (responseObject, error, errorJson) in
                    CommonUtil.hideActivityIndicator(spinner: self.spinner, loadingView: self.loadingView)
                    
                    debugPrint("deactivateBtnClicked - closeAccountInfoAPI - responseObject: \(String(describing: responseObject))")
                    
                    if let jsonResponse = responseObject{
                        let jsonObject = JSON(jsonResponse)
                        let status = jsonObject["status"].intValue
                        if status == 200 {
                            let alertTitle = LanguageHelper.getString(key: "Deactivation_Success")
                            let alertMsg = LanguageHelper.getString(key: "You_have_successfully_deactivated_your_CleanPay_Mobile")
                            CommonUtil.showAlert_2BtnHandler(sender: self, title: alertTitle, message: alertMsg, button1: LanguageHelper.getString(key: "OK"), button2: nil) { action in
                                self.logout()
                            }
                        }else {
                            // TODO: 需要提示不？
                            // CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Profile_Update_Failed"), message: LanguageHelper.getString(key: "Your_profile_was_unable_to_update_at_this_time_Please_try"), button1: LanguageHelper.getString(key: "OK"), button2: nil)
                        }
                    }
                    if error != nil {
                        guard let errMsg = errorJson!["message"].string else {
                            return
                        }
                        CommonUtil.showAlert(sender: self, title: errMsg, message: "", button1: LanguageHelper.getString(key: "OK"), button2: nil)
                    }
                }
            }
        })
        deactAccountAAction = actOK
        deactAccountAAction?.isEnabled = false
        alert.addAction(actOK)
        let actCancel = UIAlertAction(title: cancel, style: .cancel, handler:nil)
        alert.addAction(actCancel)
        alert.preferredAction = actOK
        self.present(alert, animated: true, completion: nil)
    }
    
    private func addNewLaundryCardFields() {
        let LC_Number_View = KSTextFieldView.init(labelText: LanguageHelper.getString(key: "Key_LC_Number"), isName: true, isReadeOnlyTextFiled: true, fontSize: fontSubTitleSize)
        let CVC_Optional = KSTextFieldView.init(labelText: LanguageHelper.getString(key: "Key_CVC"), isName: true, isReadeOnlyTextFiled: true, fontSize: fontSubTitleSize)
        let deleteButton = UIButton(type: .custom)
        
        // Configure delete button
        deleteButton.setImage(UIImage(named: "delete_icon"), for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
        
        // Add validation and focus management to LC_Number_View
        LC_Number_View.myTextField.addTarget(self, action: #selector(textFieldDidEndEditing(_:)), for: .editingDidEnd)
        LC_Number_View.myTextField.addTarget(self, action: #selector(limitInputLength(_:)), for: .editingChanged)
        LC_Number_View.myTextField.keyboardType = .numberPad
        
        CVC_Optional.myTextField.addTarget(self, action: #selector(limitInputLength(_:)), for: .editingChanged)
        CVC_Optional.myTextField.keyboardType = .numberPad
        
        // Set delegate for new text fields
        LC_Number_View.myTextField.delegate = self
        CVC_Optional.myTextField.delegate = self
        
        contentView.addSubview(LC_Number_View)
        contentView.addSubview(CVC_Optional)
        contentView.addSubview(deleteButton)
        
        LC_Optional_Views.append(LC_Number_View)
        CVC_Optional_Views.append(CVC_Optional)
        deleteButtons.append(deleteButton)
        
        let index = LC_Optional_Views.count - 1
        
        LC_Number_View.mas_makeConstraints { make in
            make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30)
            make?.left.equalTo()(self.view)?.offset()(25)
            if index == 0 {
                make?.top.equalTo()(g_Sub_LaundryCard_Title_Label.mas_bottom)?.offset()(20)
            } else {
                make?.top.equalTo()(LC_Optional_Views[index - 1].mas_bottom)?.offset()(20)
            }
        }
        
        if index > 0 {  // 第一行
            CVC_Optional.mas_makeConstraints { make in
                make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30-44)
                make?.left.equalTo()(LC_Number_View.mas_right)?.offset()(10)
                make?.top.equalTo()(LC_Number_View)
            }
        }else {
            CVC_Optional.mas_makeConstraints { make in
                make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30)
                make?.left.equalTo()(LC_Number_View.mas_right)?.offset()(10)
                make?.top.equalTo()(LC_Number_View)
            }
        }
        
        if index > 0 {  // 第一行没有删除按钮，其余行添加删除按钮
            deleteButton.mas_makeConstraints { make in
                make?.left.equalTo()(CVC_Optional.mas_right)?.offset()(10)
                make?.bottom.equalTo()(LC_Number_View)
                make?.width.mas_equalTo()(24)
                make?.height.mas_equalTo()(32)
                make?.right.equalTo()(self.view)?.offset()(-25)  // 删除按钮的右侧与第一行的CVC_Optional对齐
            }
        }
        
        if let lastView = LC_Optional_Views.last {
            g_AddNew_LaundryCard_Btn.mas_remakeConstraints { make in
                make?.top.equalTo()(lastView.mas_bottom)?.offset()(10)
                make?.leading.equalTo()(self.view)?.offset()(25)
            }
        }
    }
    
    func updateTextFieldPairs(with cards: [[String: String]]) {
        
        // 遍历返回的卡片数据
        for (index, card) in cards.enumerated() {
            // 确保索引不超出现有控件的范围
            if index < self.LC_Optional_Views.count && index < self.CVC_Optional_Views.count {
                let lcNumberTextField = self.LC_Optional_Views[index].myTextField
                let cvcTextField = self.CVC_Optional_Views[index].myTextField
                
                // 根据数据字典设置 LC_Number_View 和 CVC_Optional 的文本
                lcNumberTextField.text = card["lcNumber"]
                cvcTextField.text = card["cvcNumber"]
            }
        }
    }
    
    @objc func textFieldDidEndEditing(_ textField: UITextField) {
        guard let cardNumber = textField.text, !cardNumber.isEmpty else { return }
        
        // 在 LC_Optional_Views 中查找 textField
        if let lcIndex = LC_Optional_Views.firstIndex(where: { $0.myTextField == textField }) {
            // LC_Number_View 验证
            if cardNumber.count < 7 {
                showAlert(message: LanguageHelper.getString(key: "Card_number_should_be_7_digits")) {
                    textField.becomeFirstResponder()
                }
            } else {
                // 完成的 7 位数字，限制输入长度
                if cardNumber.count == 7 {
                    // 限制输入长度为7
                    textField.text = String(cardNumber.prefix(7))
                    textField.addTarget(self, action: #selector(limitInputLength(_:)), for: .editingChanged)
                }
                validateLaundryCardNumber(cardNumber, textField: textField)
            }
        }
        // 在 CVC_Optional_Views 中查找 textField
        else if let cvcIndex = CVC_Optional_Views.firstIndex(where: { $0.myTextField == textField }) {
            // CVC_Optional 验证
            if cardNumber.count < 3 {
                showAlert(message: LanguageHelper.getString(key: "CVC_should_be_3_digits")) {
                    textField.becomeFirstResponder()
                }
            } else {
                // 完成的 3 位数字，限制输入长度
                if cardNumber.count == 3 {
                    // 限制输入长度为3
                    textField.text = String(cardNumber.prefix(3))
                    textField.addTarget(self, action: #selector(limitInputLength(_:)), for: .editingChanged)
                }
            }
        }
    }
    
    @objc func limitInputLength(_ textField: UITextField) {
        if let text = textField.text {
            // 对于 LC_Number_View 和 CVC_Optional，限制长度为7和3
            if LC_Optional_Views.contains(where: { $0.myTextField == textField }) {
                textField.text = String(text.prefix(7))
            } else if CVC_Optional_Views.contains(where: { $0.myTextField == textField }) {
                textField.text = String(text.prefix(3))
            }
        }
    }
    
    private func showAlert(message: String, completion: @escaping () -> Void) {
        let alert = UIAlertController(title: message, message: "", preferredStyle: .alert)
        let okAction = UIAlertAction(title: LanguageHelper.getString(key: "OK"), style: .default) { _ in
            completion()
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    private func validateLaundryCardNumber(_ cardNumber: String, textField: UITextField) {
        let APICon = APIConnectionWithTimeOut()
        CommonUtil.showActivityIndicator(sourceView: self.view, spinner: spinner, loadingView: loadingView)
        // TODO: 这个忽略键盘好像没起作用
        UIApplication.shared.beginIgnoringInteractionEvents()
        APICon.checkOneLaundryCardAPI(sender: self, cardNumber: cardNumber) { [weak self] responseObject, error, errorJson in
            guard let self = self else { return }
            CommonUtil.hideActivityIndicator(spinner: self.spinner, loadingView: self.loadingView)
            if UIApplication.shared.isIgnoringInteractionEvents {
                UIApplication.shared.endIgnoringInteractionEvents()
            }
            debugPrint("checkOneLaundryCardAPI -- response -: \(String(describing: responseObject))")
            if let jsonResponse = responseObject {
                let jsonObject = JSON(jsonResponse)
                let status = jsonObject["status"].intValue
                if status == 200 {
                    // Handle valid response
                } else {
                    // Handle other statuses if necessary
                }
            }
            
            if errorJson != nil {
                guard let errMsg = errorJson?["message"].string else { return }
                CommonUtil.showAlert(sender: self, title: errMsg, message: "", button1: LanguageHelper.getString(key: "OK"), button2: nil) {
                    // TODO: 完善跳回上一个TextField
                    // textField.becomeFirstResponder()
                }
            }
        }
    }
    
    @objc func deleteButtonTapped(_ sender: UIButton) {
        guard let index = deleteButtons.firstIndex(of: sender) else { return }
        
        // Remove views
        LC_Optional_Views[index].removeFromSuperview()
        CVC_Optional_Views[index].removeFromSuperview()
        deleteButtons[index].removeFromSuperview()
        
        // Remove from data arrays
        LC_Optional_Views.remove(at: index)
        CVC_Optional_Views.remove(at: index)
        deleteButtons.remove(at: index)
        
        // Update layout
        updateLayoutAfterDeletion()
    }
    
    private func updateLayoutAfterDeletion() {
        for (index, lcView) in LC_Optional_Views.enumerated() {
            lcView.mas_remakeConstraints { make in
                make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30)
                make?.left.equalTo()(self.view)?.offset()(25)
                if index == 0 {
                    make?.top.equalTo()(g_Sub_LaundryCard_Title_Label.mas_bottom)?.offset()(20)
                } else {
                    make?.top.equalTo()(LC_Optional_Views[index - 1].mas_bottom)?.offset()(20)
                }
            }
            
            CVC_Optional_Views[index].mas_remakeConstraints { make in
                if index == 0 {
                    make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30)
                } else {
                    make?.width.equalTo()(self.view)?.dividedBy()(2)?.offset()(-30-44)
                }
                make?.left.equalTo()(lcView.mas_right)?.offset()(10)
                make?.top.equalTo()(lcView)
            }
            
            // 只有 index > 0 的时候，才设置删除按钮的布局
            if index > 0 {
                deleteButtons[index].mas_remakeConstraints { make in
                    make?.left.equalTo()(CVC_Optional_Views[index].mas_right)?.offset()(10)
                    make?.bottom.equalTo()(lcView)
                    make?.width.mas_equalTo()(24)
                    make?.height.mas_equalTo()(32)
                    make?.right.equalTo()(self.view)?.offset()(-25)
                }
            }
            
            // 确保删除按钮在第一行被移除或隐藏
            if index == 0 {
                deleteButtons[index].isHidden = true
            } else {
                deleteButtons[index].isHidden = false
            }
        }
        
        if let lastView = LC_Optional_Views.last {
            g_AddNew_LaundryCard_Btn.mas_remakeConstraints { make in
                make?.top.equalTo()(lastView.mas_bottom)?.offset()(10)
                make?.leading.equalTo()(self.view)?.offset()(25)
            }
        }
        
        self.view.layoutIfNeeded()
    }
    
    func sendSMSAction(newPhoneNum: String ) {
        
        var apiParam = [String:String]()
        let mobile = newPhoneNum.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        apiParam["phone"] = mobile
        let countryCode = self.phoneView.phoneLabel.text
        apiParam["country_code"] = CommonUtil.cleanCountryCode(countryCode ?? "1")
        
        if let currentTitle = self.phoneView.selCountryButton.title(for: .normal) {
            apiParam["country"] = currentTitle
        } else {
            apiParam["country"] = "USA"
        }
        
        DDLogVerbose("sendSMSAction -- parameters:\(apiParam)")
        
        let APICon = APIConnectionWithTimeOut()
        APICon.postSendSMSApi(paramDictionary: apiParam as NSDictionary){
            responseObject, error, errorJson in
            debugPrint("responseObject - \(String(describing: responseObject))")
        }
    }
    
    // MARK: - 短信倒计时
    func showPhoneNumberAlert(newPhoneNum: String ){
        let alertController = KSPhoneNumberAlert()
        alertController.showPhoneCodeModel(phoneNumber: newPhoneNum, viewController: self)
        alertController.itemBlock = { [weak self] index,codeText in
            if index == 1{
                // 更新手机号
                self?.updatePhoneNumberToServer(phoneVerCode: codeText, phoneNum: newPhoneNum)
            }else if index == 2{
                //重新发送 cleanCountryCode
                self?.sendSMSAction(newPhoneNum: codeText)
            }
        }
    }
    
    // 实现 UITextFieldDelegate 方法
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == phoneView.textField {
            debugPrint("phoneView.textField tapped")
            
            // 原来调用方法
            showPhoneUpdateAlert()
            
            // 返回 false 禁止键盘弹出
            return false
        }
        return true
    }
    
    func updatePhoneNumberToServer(phoneVerCode:String, phoneNum:String) {
        debugPrint("updatePhoneNumberToServer")
        
        let lancode = CurrentAppUserLanguageEnum.englishLanguage.languageNumString(language: UserDefaults.standard.string(forKey: UserLanguage) ?? "en")
        let countryCodeSrc = self.phoneView.phoneLabel.text
        let countryCode = CommonUtil.cleanCountryCode(countryCodeSrc ?? "1")
        
        var userCountry = "USA"
        if let countryNa = self.phoneView.selCountryButton.title(for: .normal) {
            userCountry = countryNa
        }
        
        let APICon = APIConnectionWithTimeOut();
        CommonUtil.showActivityIndicator(sourceView: self.view, spinner: self.spinner, loadingView: self.loadingView)
        APICon.updateMobileAPI(sender: self, countryCode: countryCode, userCountry: userCountry, mobile: phoneNum, language: lancode, verifyCode: phoneVerCode) {(responseObject, error, errorJson) in
            CommonUtil.hideActivityIndicator(spinner: self.spinner, loadingView: self.loadingView)
            
            debugPrint("updatePhoneNumberToServer - responseObject: \(String(describing: responseObject))")
            
            if let jsonResponse = responseObject{
                let jsonObject = JSON(jsonResponse)
                let message = jsonObject["message"].string
                let status = jsonObject["status"].intValue
                if status == 200 {
                    
                    if message != "" {
                        CommonUtil.showAlert(sender: self, title: message ?? "", message: "", button1: LanguageHelper.getString(key: "OK"), button2: nil)
                    }else {
                        CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Profile_Updated"), message: LanguageHelper.getString(key: "You_have_successfully_updated_your_profile"), button1: LanguageHelper.getString(key: "OK"), button2: nil)
                    }
                    self.getAccountLatestInfo()
                    self.contentView.layoutIfNeeded()
                }else {
                    if message != "" {
                        CommonUtil.showAlert(sender: self, title: message ?? "", message: "", button1: LanguageHelper.getString(key: "OK"), button2: nil)
                    }else {
                        CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Profile_Update_Failed"), message: LanguageHelper.getString(key: "Your_profile_was_unable_to_update_at_this_time_Please_try"), button1: LanguageHelper.getString(key: "OK"), button2: nil)
                    }
                }
            }
            if error != nil {
                guard let errMsg = errorJson!["message"].string else {
                    CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Profile_Update_Failed"), message: LanguageHelper.getString(key: "Your_profile_was_unable_to_update_at_this_time_Please_try"), button1: LanguageHelper.getString(key: "OK"), button2: nil)
                    return
                }
                CommonUtil.showAlert(sender: self, title: errMsg, message: "", button1: LanguageHelper.getString(key: "OK"), button2: nil)
            }
        }
    }
    
    // 实现 UITextFieldDelegate 方法来限制输入
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == self.alertUpdatePhoneNumTextField {
            
            // 获取当前文本框的文本
            guard let text = textField.text else {
                return true
            }
            
            // 获取国家代码
            let countryCodeSrc = self.phoneView.phoneLabel.text
            let countryCode = CommonUtil.cleanCountryCode(countryCodeSrc ?? "1")
            
            // 计算输入后的文本长度
            let newLength = text.count + string.count - range.length
            
            // 如果是美国国家代码，进行特殊处理
            if countryCode == "1" {
                // 如果新文本长度超过14字符，直接返回false
                if newLength >= 15 {
                    return false
                }
                
                if newLength == 14 {
                    // 设置updatePhoneNumConfirmAAction的可用性
                    updatePhoneNumConfirmAAction?.isEnabled = true
                }
                
                // 删除字符的处理
                if string.isEmpty {
                    if newLength == 6 {
                        let startIndex = text.index(text.startIndex, offsetBy: 1)
                        let endIndex = text.index(startIndex, offsetBy: 3)
                        textField.text = String(text[startIndex..<endIndex])
                        return false
                    } else if newLength == 10 {
                        let startIndex = text.startIndex
                        let endIndex = text.index(startIndex, offsetBy: 9)
                        textField.text = String(text[startIndex..<endIndex])
                        return false
                    } else {
                        textField.text = String(text.dropLast())
                        return false
                    }
                } else {
                    // 添加字符的处理
                    if newLength == 4 {
                        textField.text = "(\(text)) \(string)"
                    } else if newLength == 10 {
                        textField.text = "\(text)-\(string)"
                    } else {
                        textField.text = text + string
                    }
                    return false
                }
            } else if countryCode == "63" {
                // 设置updatePhoneNumConfirmAAction的可用性
                if text.hasPrefix("0") {
                    updatePhoneNumConfirmAAction?.isEnabled = newLength >= 11
                }else {
                    updatePhoneNumConfirmAAction?.isEnabled = newLength >= 10
                }
                
                // 其他国家手机号最大限制14位
                return newLength <= 14
            } else {
                // 设置updatePhoneNumConfirmAAction的可用性
                updatePhoneNumConfirmAAction?.isEnabled = newLength >= 3
                // 其他国家手机号最大限制14位
                return newLength <= 14
            }
        }else if textField == alertDeactAccTextField {
            // 获取当前文本框的文本
            guard let text = textField.text else {
                return true
            }
            
            // 计算输入后的文本长度
            let newLength = text.count + string.count - range.length
                
            //设置alert 能否被点击
            if newLength >= 6 {
                deactAccountAAction?.isEnabled = true
            }else{
                deactAccountAAction?.isEnabled = false
            }
            
            return true
        }else if textField == firstNameView.myTextField || textField == lastNameView.myTextField {

            let currentText = textField.text ?? ""
            let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
            
            // 检查文本的长度是否超过20
            return newText.count <= 20
        }else if textField == aEmailView.myTextField {

            let currentText = textField.text ?? ""
            let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
            
            // 检查文本的长度是否超过100
            return newText.count <= 100
        }else if textField == alertAddCampusCardUserNameTextField {
            // 获取当前文本框的文本
            guard let text = textField.text else {
                return true
            }
            
            // 计算输入后的文本长度
            let newLength = text.count + string.count - range.length
                
            //设置alert 能否被点击
            if newLength >= 1 {
//                deactAccountAAction?.isEnabled = true
                isSupportAddCampusCardUserName = true
            }else{
//                deactAccountAAction?.isEnabled = false
                isSupportAddCampusCardUserName = false
            }
            
            if isSupportAddCampusCardUserName && isSupportAddCampusCardPassword {
                addCampusCardNamePasswordAAction?.isEnabled = true
            }else {
                addCampusCardNamePasswordAAction?.isEnabled = false
            }
            
            return true
        }else if textField == alertAddCampusCardPasswordTextField {
            // 获取当前文本框的文本
            guard let text = textField.text else {
                return true
            }
            
            // 计算输入后的文本长度
            let newLength = text.count + string.count - range.length
                
            //设置alert 能否被点击
            if newLength >= 6 {
//                deactAccountAAction?.isEnabled = true
                isSupportAddCampusCardPassword = true
            }else{
//                deactAccountAAction?.isEnabled = false
                isSupportAddCampusCardPassword = false
            }
            
            if isSupportAddCampusCardUserName && isSupportAddCampusCardPassword {
                addCampusCardNamePasswordAAction?.isEnabled = true
            }else {
                addCampusCardNamePasswordAAction?.isEnabled = false
            }
            
            return true
        }else {
            
            // 获取当前输入的文本
            let currentText = textField.text ?? ""
            // 计算新文本
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            
            if textField == LC_Optional_Views.last?.myTextField {
                // 限制 LC_Number_View 为 7 位数字
                if updatedText.count > 7 {
                    return false
                }
            } else if textField == CVC_Optional_Views.last?.myTextField {
                // 限制 CVC_Optional 为 3 位数字
                if updatedText.count > 3 {
                    return false
                }
            }
            
            return true
        }
    }
    
    func showPhoneUpdateAlert() {
        let updateMobileNumber = LanguageHelper.getString(key: "Update_Mobile_Number")
        let enter_your_updated_Mobile_Phone = LanguageHelper.getString(key: "Enter_your_updated_Mobile_Phone_Number_for_your_account")
        
        let alert = UIAlertController(title: updateMobileNumber, message: enter_your_updated_Mobile_Phone, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.keyboardType = .numberPad
            self.alertUpdatePhoneNumTextField = textField
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.delegate = self
        }
        
        let actOK = UIAlertAction(title: LanguageHelper.getString(key: "Confirm"), style: .default) { [weak alert] (_) in
            if let textField = alert?.textFields?.first {
                let inputText = textField.text ?? ""
                debugPrint("User entered: \(inputText)")
                //发送验证码
                self.sendSMSAction(newPhoneNum: inputText)
                //show alert
                self.showPhoneNumberAlert(newPhoneNum: inputText)
            }
        }
        updatePhoneNumConfirmAAction = actOK
        updatePhoneNumConfirmAAction?.isEnabled = false
        
        let actCancel = UIAlertAction(title: LanguageHelper.getString(key: "Cancel"), style: .cancel, handler: nil)
        
        alert.addAction(actOK)
        alert.addAction(actCancel)
        alert.preferredAction = actOK
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func validMobile() -> Bool{
        
        if let mobile = phoneView.textField.text
        {
            if mobile == ""
            {
                let Please_enter_your_valid_mobile_number:String = LanguageHelper.getString(key: "Please_enter_your_valid_mobile_number")
                CommonUtil.showAlert(sender: self, title: Please_enter_your_valid_mobile_number, message: "", button1: LanguageHelper.getString(key: "Mul_OK"), button2: nil)
                return false
            }
            
            let selCountry = self.phoneView.selCountry
            let selCodeCountry = selCountry?["code"] as? String
            var mobileNumberValue = mobile
            
            if(CommonUtil.supportWashboardApril()) {
                if mobile.count > 0 {
                    //手机号码的校验
                    DDLogVerbose("mobile:" + mobileNumberValue)
                    
                    if (selCodeCountry == "1") {
                        if ((mobile as NSString).length < 14) {
                            CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Please_enter_valid_phone_number"), message: "", button1: LanguageHelper.getString(key: "Mul_OK"), button2: nil)
                            return false
                        }
                    }else if selCodeCountry == "63" {
                        if mobileNumberValue.hasPrefix("0") {
                            mobileNumberValue.remove(at: mobileNumberValue.startIndex)
                            if mobileNumberValue.count < 10 {
                                CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Please_enter_valid_phone_number"), message: "", button1: LanguageHelper.getString(key: "Mul_OK"), button2: nil)
                                return false
                            }
                        }else {
                            if mobileNumberValue.count < 10 {
                                CommonUtil.showAlert(sender: self, title: LanguageHelper.getString(key: "Please_enter_valid_phone_number"), message: "", button1: LanguageHelper.getString(key: "Mul_OK"), button2: nil)
                                return false
                            }
                        }
                    }
                    return true
                }
            }else{
                let realMobile = mobile.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
                
                if realMobile.count == 10 {
                    //手机号码的校验
                    mobileNumberValue = mobile
                    
                    debugPrint("mobile:" + mobileNumberValue)
                    
                    return true
                }
            }
        }
        
        let Please_enter_your_valid_mobile_number:String = LanguageHelper.getString(key: "Please_enter_your_valid_mobile_number")
        CommonUtil.showAlert(sender: self, title: Please_enter_your_valid_mobile_number, message: "", button1: LanguageHelper.getString(key: "Mul_OK"), button2: nil)
        phoneView.textField.becomeFirstResponder()
        return false
        
    }
    
    private func logout() {
        let vc = self.navigationController?.viewControllers.first
        self.navigationController?.popToViewController(vc!, animated: false)
        CommonUtil.signOut(sender: vc!)
    }
}

