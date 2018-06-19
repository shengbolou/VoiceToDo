//
//  DetailViewController.swift
//  VoiceRecognition
//
//  Created by Shengbo Lou on 6/15/18.
//  Copyright © 2018 Shengbo Lou. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController{
    

    @IBOutlet var titleLabel: UILabel!
    var titleString: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.title = "Detail"
        self.titleLabel.text = titleString
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
