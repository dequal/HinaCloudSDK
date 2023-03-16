//
// ViewController.swift
// HinaDataSwift
//
// Created by hina on 2022/11/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


import UIKit

class ViewController: UIViewController{

    var tableView:UITableView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "ViewController"
        self.navigationController?.navigationBar.backgroundColor = UIColor.blue
        self.view.backgroundColor = UIColor.white
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
 
}

extension ViewController:UITableViewDelegate{
    
    
}


