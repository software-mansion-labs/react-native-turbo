//
//  RNTTurboWebviewManager.m
//  HotwireRNDemo
//
//  Created by Bartłomiej Fryz on 22/06/2022.
//

#pragma clang diagnostic ignored "-Wstrict-prototypes"

#import <React/RCTViewManager.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RNVisitableViewManager, NSObject)

  RCT_EXPORT_VIEW_PROPERTY(url, NSString)
  RCT_EXPORT_VIEW_PROPERTY(sessionHandle, NSString)
  RCT_EXPORT_VIEW_PROPERTY(applicationNameForUserAgent, NSString)
  RCT_EXPORT_VIEW_PROPERTY(pullToRefreshEnabled, BOOL)
  RCT_EXPORT_VIEW_PROPERTY(scrollEnabled, BOOL)
  RCT_EXPORT_VIEW_PROPERTY(contentInset, NSDictionary)
  RCT_EXPORT_VIEW_PROPERTY(refreshControlTopAnchor, NSNumber)
  RCT_EXPORT_VIEW_PROPERTY(webViewDebuggingEnabled, BOOL)
  RCT_EXPORT_VIEW_PROPERTY(allowsInlineMediaPlayback, BOOL)
  RCT_EXPORT_VIEW_PROPERTY(onVisitProposal, RCTDirectEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onOpenExternalUrl, RCTDirectEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onMessage, RCTDirectEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onLoad, RCTDirectEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onWebAlert, RCTDirectEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onWebConfirm, RCTDirectEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onFormSubmissionStarted, RCTDirectEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onFormSubmissionFinished, RCTDirectEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onShowLoading, RCTDirectEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onHideLoading, RCTDirectEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onContentProcessDidTerminate, RCTDirectEventBlock)

  RCT_EXTERN_METHOD(injectJavaScript: (nonnull NSNumber) node
                    code: (nonnull NSString) code)
  RCT_EXTERN_METHOD(reload: (nonnull NSNumber) node)
  RCT_EXTERN_METHOD(refresh: (nonnull NSNumber) node)
  RCT_EXTERN_METHOD(sendAlertResult: (nonnull NSNumber) node)
  RCT_EXTERN_METHOD(sendConfirmResult: (nonnull NSNumber) node
                    result: (nonnull NSString) code)


@end

