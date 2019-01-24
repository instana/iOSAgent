//  Created by Nikola Lajic on 12/10/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import UIKit
import Instana

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(forName: Instana.Notification.crashReported, object: nil, queue: nil) { _ in
            
        }
    }


}

