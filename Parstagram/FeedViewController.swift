//
//  FeedViewController.swift
//  Parstagram
//
//  Created by Autumn Y Ngoc on 3/7/22.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBAction func onLogoutButton(_ sender: Any) {
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "LoginViewController") //"LoginViewController" is the storyboard ID of the view controller that we set in the right side bar under the driver license tab
        
        // Because window is only in the scope of SceneDelegate
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let delegate = windowScene.delegate as? SceneDelegate else {return}
        delegate.window?.rootViewController = loginViewController
    }
    
    var posts = [PFObject]()
    var selectedPost : PFObject!
    let commentBar = MessageInputBar()
    var showCommentBar = false

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewdidload")
        
        // the default text in the addcomment bar when there's no text
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // make the keyboard follow the drag of our finger
        tableView.keyboardDismissMode = .interactive
        
        let center = NotificationCenter.default
        // Observing an event in the Notification Center.
        // When that event happens, call the selector in where the observer is
        // In this case, the observer is self - the FeedViewController
        // The selector is the hideKeyboard function we define below
        // The event is keyboardWillHideNotification, which is when the keyboard is going to be dismissed
        center.addObserver(self, selector: #selector(hideKeyboard(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func hideKeyboard (note: Notification) {
        // clear the text in the comment bar
        commentBar.inputTextView.text = nil
        
        showCommentBar = false
        
        // toggle becomeFirstResponder back
        becomeFirstResponder()
    }
    
    override var inputAccessoryView: UIView? {
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return showCommentBar
    }
    
    // called everytime the view is visible
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewdidappear!")
        let query = PFQuery(className: "Posts")
        
        // make the query include the PFobjects that have their reference stored at the "author" key and the "Comments" key
        query.includeKey("author")
        query.includeKey("Comments")
        // note that inside the Comments object, the key "author" also doesn't store the object directly but the referenced, so we must include this includeKey() line
        query.includeKey("Comments.author")
        query.limit = 20
        
        query.order(byDescending: "createdAt")
        
        query.findObjectsInBackground { posts, error in
            // if successfully get the posts
            if posts != nil {
                // store the data into the posts array defined in line 13
                self.posts = posts!
                self.tableView.reloadData()
                print("Successfully reloaded!")
            }
        }
    }
    
    // Each post, including its image and comments, is a section
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    // Inside each section, the number of rows is made up by one row for the image and the rows for the comments
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        print(section)
        // ?? [] -> if the "Comments" array is nil, set it as the default value which is [] - an empty array
        // Make sure to use the right capitalization for the key name or it won't retrieve any data. In this case, it is "Comments", not "comments".
        let comments = (post["Comments"] as? [PFObject]) ?? []
        print("comments.count is \(comments.count)")
        // The total number of rows is the total comments plus the row for the post with the image plus the row for the AddComment cell
        return (comments.count + 2)
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let postData = posts[indexPath.section]
        // Make sure to use the right capitalization for the key name or it won't retrieve any data. In this case, it is "Comments", not "comments".
        let comments = (postData["Comments"] as? [PFObject]) ?? []
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
            
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
        // do some test cases, e.g. there are 3 comments, to figure out the relationship (equal/less than/less than or equal/...) between the rows
        else if indexPath.row <= comments.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            // the first comment is row 1 in indexPath and item 0 in the comments array
            let comment = comments[indexPath.row - 1]
            cell.usernameLabel.text = (comment["author"] as! PFUser).username
            cell.commentLabel.text = comment["text"] as! String
            
            return cell
        }
        // the row with the index equal to comments.count is the last row, which is the addComment cell
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            // we don't write this part `as! AddCommentCell` at the end of the line above because we didn't create a file for it, which we don't need to do because we're not going to dynamically modify the cell
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        let comments = (post["Comments"] as? [PFObject]) ?? []
        print("This is row \(indexPath.row) and comments.count is \(comments.count)")
        if indexPath.row == comments.count + 1 {
            showCommentBar = true
            becomeFirstResponder()
            commentBar.inputTextView.becomeFirstResponder()
            selectedPost = post
        }
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        // Create the comment
        let comment = PFObject(className: "Comments")
        comment["author"] = PFUser.current()
        comment["text"] = text
        comment["post"] = selectedPost

        // Add this comment to an array named "Comments" belonged to the selected post (=the selected row)
        selectedPost.add(comment, forKey: "Comments")

        // When the post is saved, the comment added to that post will also be saved
        selectedPost.saveInBackground { success, error in
            if success {
                print("Comment saved.")
            } else{
                print("Error saving comment")
            }
        }
        tableView.reloadData()
        
        // Clear and dismiss the input
        commentBar.inputTextView.text = nil
        showCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
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
