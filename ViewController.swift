//
//  ViewController.swift
//  chat
//
//  Created by David Bachor on 10/29/17.
//  Copyright © 2017 David Bachor. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        requiredLable.isHidden = true
        
        let _ = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(ViewController.getChat), userInfo: nil, repeats: true)
        
    }
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return formatter
    }()
    
    // initialize the date when the app starts
    let startDateTime: NSDate = {
        let date = NSDate() //formated like: "2017-10-29 03:49:48 +00000"
        //var dayte: String = "\(date)"
        
        //// strip off the +00000 from the end ofr the UTC date
        //let index = dayte.index(dayte.startIndex, offsetBy: 19)
        //dayte = dayte.substring(to: index)
        return date
    }()

    @IBOutlet var chatBox: UITextView!
    @IBOutlet var chatToSend: UITextField!
    @IBOutlet var userNameTextBox: UITextField!
    @IBOutlet var requiredLable: UILabel!
    
    @IBAction func sendChat(_ sender: UIButton) {
        
        guard let userName = userNameTextBox.text, !userName.isEmpty else {

            requiredLable.isHidden = false
            self.userNameTextBox.becomeFirstResponder()
            return
        }
        
        guard let chat = chatToSend.text, !chat.isEmpty else {
            
            self.chatToSend.becomeFirstResponder()
            return
        }
        
        requiredLable.isHidden = true

        //let baseURL = "http://dbachor.dev/NCC/setChat.php"
        let baseURL = "http://dbachor.com/NCC/setChat.php"
        
        let post_data: NSDictionary = NSMutableDictionary()
        post_data.setValue(userName, forKey: "user")
        post_data.setValue(chat, forKey: "message")
        
        var paramString = ""
        
        for (key, value) in post_data
        {
            var v: String
            v = value as! String
            v = v.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            paramString = paramString + (key as! String) + "=" + v + "&"
        }
        
        let login_url = baseURL + "?" + paramString
        
        let url:URL = URL(string: login_url)!
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in // this is a closure
            
            guard let _:Data = data, let _:URLResponse = response  , error == nil else {
                return
            }
            
            DispatchQueue.main.async(execute: {() -> Void in
                self.chatToSend.text = ""
            })
            
        }) // dataTask
        
        task.resume()

        
        getChat(); // may need to move this to the closure - if so set to main thread
        
    } //sendChat
 
    
    func getChat() -> Void {
        
        //let baseURL = "http://dbachor.dev/NCC/getChatLogJSON.php"
        let baseURL = "http://dbachor.com/NCC/getChatLogJSON.php"

        let post_data: NSDictionary = NSMutableDictionary()
        // var dayte = startDateTime // "2017-10-29 20:49:48"
        
        let dayte = dateFormatter.string(from: startDateTime as Date)
        
        
        post_data.setValue(dayte, forKey: "startDateTime")

        var paramString = ""
        
        for (key, value) in post_data
        {
            var v: String
            v = value as! String
            v = v.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            paramString = paramString + (key as! String) + "=" + v + "&"
        }
        
        let login_url = baseURL + "?" + paramString
    
        let url:URL = URL(string: login_url)!
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
            
            guard let _:Data = data, let _:URLResponse = response  , error == nil else {
                return
            }
            print("RAW DATA")
            print(NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!)

            
            var allChats = ""
            do
            {
                if let json = try JSONSerialization.jsonObject(with: data!) as? [String: Any] {
                    
                    if let chats = json["chats"] as? [[String: Any]] {
                        for chat in chats {
                            print("chat: \(chat)")
                            
                            if let username = chat["user"] as? String,
                                let dayte = chat["dayte"] as? String,
                                let messsage = chat["message"] as? String {
                                
                                allChats += dayte + " " + username + " " + messsage + "\n"
                            }
                        }
                    }
                    
                    // print("chatBox.text \(self.chatBox.text)")
                    
                    // reqeusting this be called by the main thread
                    DispatchQueue.main.async(execute: {() -> Void in
                        self.chatBox.text = allChats
                        let bottom = NSMakeRange(self.chatBox.text.characters.count - 1, 1)
                        self.chatBox.scrollRangeToVisible(bottom)
                    })
                    
                    if let errors = json["error"] as? [[String: Any]] {
                        for error in errors {
                            print("Error: \(String(describing: error["message"]))")
                        }
                    }
                }
            }
            catch
            {
                print("json error: likey failed login attempt. \(error.localizedDescription)")
                
                return
            }
        }) // dataTask
        
        task.resume()
    } // end getchat

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

