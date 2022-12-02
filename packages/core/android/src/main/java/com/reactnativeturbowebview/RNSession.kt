package com.reactnativeturbowebview

import android.content.Context
import android.util.Log
import android.webkit.JavascriptInterface
import android.widget.FrameLayout
import androidx.appcompat.app.AppCompatActivity
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.RCTEventEmitter
import dev.hotwire.turbo.session.TurboSession
import dev.hotwire.turbo.views.TurboWebView
import kotlinx.coroutines.*
import kotlin.coroutines.suspendCoroutine
import java.util.*
import org.json.JSONObject
import kotlin.coroutines.resume

class RNSession(context: Context) : FrameLayout(context) {

  private val reactContext = context as ReactContext
  private val registeredVisitableViews = mutableListOf<SessionSubscriber>()

  val turboSession: TurboSession = run {
    val activity = reactContext.currentActivity as AppCompatActivity
    val webView = TurboWebView(context, null)

    val sessionName = UUID.randomUUID().toString()
    webView.getSettings().setJavaScriptEnabled(true)
    webView.addJavascriptInterface(JavaScriptInterface(), "AndroidInterface")

    TurboSession(sessionName, activity, webView)
  }

  fun sendEvent(event: RNSessionEvent, params: WritableMap) {
    reactContext.getJSModule(RCTEventEmitter::class.java).receiveEvent(id, event.name, params)
  }

  internal fun registerVisitableView(newView: SessionSubscriber) {
    MainScope().launch {
      registeredVisitableViews.map { view ->
        async {
          suspendCoroutine { continuation ->
            view.detachWebView {
              continuation.resume(0)
            }
          }
        }
      }.awaitAll()
        if(!registeredVisitableViews.contains(newView)) {
        registeredVisitableViews.add(newView)
      }
      newView.attachWebViewAndVisit()
    }



  }

  internal fun removeVisitableView(view: SessionSubscriber) {
    registeredVisitableViews.remove(view)
  }

  inner class JavaScriptInterface {
    @JavascriptInterface
    fun postMessage(messageStr: String) {
      Log.d("RNVisitableView", "postMessage ${messageStr}")
      // Android interface works only with primitive types, that's why we need to use JSON
      val messageObj =
        Utils.convertJsonToBundle(JSONObject(messageStr)) // TODO remove double conversion
      sendEvent(RNSessionEvent.RECEIVED_JS_MESSAGE, Arguments.fromBundle(messageObj))
    }
  }
}
