package kh.gov.interior.core.prod

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Prevent screen capture, recording, and task-switcher previews of confidential government data
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
