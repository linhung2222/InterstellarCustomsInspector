import SwiftUI

/// 應用程式進入點：定義《星際海關審查員》的主視窗場景與起始畫面
@main struct MyApp: App {
    /// 應用程式的主場景結構
    var body: some Scene {
        WindowGroup {
            // 載入主遊戲終端機介面
            ContentView()
        }
    }
}
