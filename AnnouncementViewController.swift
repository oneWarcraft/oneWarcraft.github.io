//
//  AnnouncementViewController.swift
//  kiosoft
//
//  Created by Carl on 2018/7/23.
//  Copyright © 2018年 Ubix Innovations. All rights reserved.
//

import UIKit
import SwiftyJSON

class AnnouncementViewController: UIViewController, UITextViewDelegate {
    var spinner = UIActivityIndicatorView(style: .whiteLarge)
    var messageID:String?
    
    var loadingView: UIView = UIView()
    let titleLab:UILabel = UILabel()
    let dateLab:UILabel = UILabel()
    let textLab:UITextView = UITextView()
    let backScrView:UIScrollView = UIScrollView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let height = self.view.bounds.size.height
        let width = self.view.bounds.size.width
        
        self.navigationItem.title = LanguageHelper.getString(key: "Announcements")
        
        self.navigationController?.navigationBar.topItem?.title = ""
        self.view.backgroundColor = UIColor.white
        
        backScrView.frame = self.view.bounds
        backScrView.backgroundColor = UIColor.white
//        backScrView.contentSize = CGSize(width: screenw-60, height: 2500)
        backScrView.isScrollEnabled = true
        self.view.addSubview(backScrView)
        
        titleLab.frame = CGRect(x: 80, y: 10, width: width-80, height: 60)
        titleLab.numberOfLines = 2
        titleLab.font = UIFont.boldSystemFont(ofSize: 17)
        backScrView.addSubview(titleLab)
        
        dateLab.textColor = UIColor.lightGray
        dateLab.font = UIFont.systemFont(ofSize: 15)
        dateLab.frame = CGRect(x: width-200, y: 60, width: 180, height: 20)
        dateLab.textAlignment = .right
        backScrView.addSubview(dateLab)
        
        textLab.textColor = UIColor.black
        textLab.font = UIFont.systemFont(ofSize: 17)
//        textLab.numberOfLines = 0;
//        textLab.lineBreakMode = .byWordWrapping
        textLab.isUserInteractionEnabled = true
        textLab.delegate = self
        textLab.isEditable = false
        textLab.isScrollEnabled = false
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let Announcements:String = LanguageHelper.getString(key: "Announcements")
        self.navigationItem.title = Announcements
        self.getMessageDetailHelper()
        //self.navigationController?.setNavigationBarHidden(false, animated: animated)

    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getMessageDetailHelper(){
        let accountCoreDataInstance = AccountInfoManagement()
        let accountInfo = accountCoreDataInstance.getAccountInfo()!
        
        if let account_num = accountInfo.account_num{
            
            CommonUtil.showActivityIndicator(sourceView: self.view, spinner: spinner, loadingView: loadingView)
            let APICon = APIConnectionWithTimeOut();
            
            
            APICon.getMessageDetailApi(sender: self, account_number: account_num, messageID:self.messageID!){responseObject, error, errorJson in
                
                //Authentication ok
                if let jsonResponse = responseObject{
                    var transjson = JSON(jsonResponse)
                    
                    let width = self.view.bounds.size.width
                    
                    DDLogVerbose(transjson)
                    let id = transjson["id"].string
                    let body = transjson["body"].string
                    let title = transjson["title"].string
                    let updateTime = transjson["updated_time"].string
                    
                    let imgView:UIImageView = UIImageView.init(frame: CGRect(x: 35, y: 25, width: 32, height: 36))
                    imgView.image = UIImage.init(named: "Announcements2")
                    self.backScrView.addSubview(imgView)
                    
                    let line:UILabel = UILabel()
                    line.frame = CGRect(x: 0, y: 82, width: width, height: 0.5)
                    line.alpha = 0.6
                    line.backgroundColor = UIColor.lightGray
                    self.backScrView.addSubview(line)
                    
                    self.titleLab.text = title
                    self.dateLab.text = updateTime
                    
                    //                    let textStr:NSMutableAttributedString = NSMutableAttributedString(string: body!)
                    let string:NSString = body! as NSString
                    //                    let paragraphStyle = NSMutableParagraphStyle()
                    //                    paragraphStyle.lineSpacing = 8
                    
                    //                    textStr.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, string.length))
//                    self.textLab.text = body
                    let boundingRect1 = string.boundingRect(with: CGSize(width: width-60, height: 0), options: .usesLineFragmentOrigin, attributes:[NSAttributedString.Key.font:self.textLab.font], context: nil)
//                    boundingRect1.height + 40
                    self.textLab.frame = CGRect(x: 0, y: 90, width: width, height: self.view.frame.height - 90)
  
                    self.backScrView.addSubview(self.textLab)
                    self.textLab.setTextWithLinkAttribute(string as String)
                    
//                    if (IPHONEX) {
//                        self.titleLab.center = CGPoint(x: self.titleLab.center.x, y: self.titleLab.center.y+20)
//                        self.textLab.center = CGPoint(x: self.textLab.center.x, y: self.textLab.center.y+20)
//                        self.dateLab.center = CGPoint(x: self.dateLab.center.x, y: self.dateLab.center.y+20)
//                        imgView.center = CGPoint(x: imgView.center.x, y: imgView.center.y+20)
//                        line.center = CGPoint(x: line.center.x, y: line.center.y+20)
//                    }
                    
                    self.backScrView.contentSize = CGSize(width: width, height: boundingRect1.maxY+90)

                }
                
                //Authentication fail
                
                if let errorMessage = errorJson{
                    
                    DDLogVerbose("transaction api failed")
                    DDLogVerbose(errorMessage)
                    if errorMessage.isEmpty
                    {
//                        CommonUtil.showAlert(sender: self, title: "Washboard Server unavailable", message: "check your Internet connection\nError code: Er05", button1: "OK", button2: nil)
                    }
                }
                
                CommonUtil.hideActivityIndicator(spinner: self.spinner, loadingView: self.loadingView)
            }
        }
    }
    
    //MARK: - textviewDelegate
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        if URL.absoluteString.lowercased().hasPrefix("http://") ||  URL.absoluteString.lowercased().hasPrefix("https://") {
            return true;
        }else{
            UIApplication.shared.open(NSURL(string: "https://\(URL.absoluteString)")! as URL)
            return false
        }
    }
    
}
