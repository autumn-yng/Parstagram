//
//  FeedViewController.swift
//  Parstagram
//
//  Created by Autumn Y Ngoc on 3/7/22.
//

import UIKit
import Parse
import AlamofireImage

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var posts = [PFObject]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self

        // Do any additional setup after loading the view.
    }
    
    // called everytime the view is visible
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let query = PFQuery(className: "Posts")
        
        // make the query include the PFobjects that have their reference stored at the "author" key
        query.includeKey("author")
        query.limit = 20
        
        query.findObjectsInBackground { posts, error in
            // if successfully get the posts
            if posts != nil {
                // store the data into the posts array defined in line 13
                self.posts = posts!
                self.tableView.reloadData()
            }
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
        let postData = posts[indexPath.row]
        
        // configuring the outlets of the PostCell
        cell.usernameLabel.text = (postData["author"] as! PFUser).username
        cell.captionLabel.text = postData["caption"] as! String
        
        let imageFile = postData["image"] as! PFFileObject
        let urlString = imageFile.url!
        
        // creating an actual url using the URL() constructor
        let url = URL(string: urlString)!
        cell.photoView.af.setImage(withURL: url)
        
        return cell
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
