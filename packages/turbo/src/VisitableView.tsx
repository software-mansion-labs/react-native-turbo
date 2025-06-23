import React, {
  useCallback,
  useImperativeHandle,
  useRef,
  useMemo,
  Component,
} from 'react';
import {
  NativeMethods,
  NativeSyntheticEvent,
  StyleProp,
  StyleSheet,
  ViewStyle,
} from 'react-native';

import RNVisitableView, {
  RNVisitableViewProps,
  dispatchCommand,
  openExternalURL,
} from './RNVisitableView';
import { useMessageQueue } from './hooks/useMessageQueue';
import { useStradaBridge } from './hooks/useStradaBridge';
import {
  type OnAlert,
  type OnConfirm,
  useWebViewDialogs,
} from './hooks/useWebViewDialogs';
import {
  type RenderLoading,
  type RenderError,
  useWebViewState,
} from './hooks/useWebViewState';
import type {
  OnErrorCallback,
  LoadEvent,
  SessionMessageCallback,
  VisitProposal,
  ErrorEvent,
  OpenExternalUrlEvent,
  StradaComponent,
  FormSubmissionEvent,
  ContentProcessDidTerminateEvent,
  ContentInsetObject,
  ProgressViewOffsetObject,
} from './types';
import { nextEventLoopTick } from './utils/nextEventLoopTick';

export interface Props {
  url: string;
  sessionHandle?: string;
  applicationNameForUserAgent?: string;
  stradaComponents?: StradaComponent[];
  pullToRefreshEnabled?: boolean;
  scrollEnabled?: boolean;
  contentInset?: ContentInsetObject;
  progressViewOffset?: ProgressViewOffsetObject;
  refreshControlTopAnchor?: number;
  webViewDebuggingEnabled?: boolean;
  allowsInlineMediaPlayback?: boolean;
  renderLoading?: RenderLoading;
  renderError?: RenderError;
  onVisitProposal: (proposal: VisitProposal) => void;
  onLoad?: (params: LoadEvent) => void;
  onOpenExternalUrl?: (proposal: OpenExternalUrlEvent) => void;
  onFormSubmissionStarted?: (e: FormSubmissionEvent) => void;
  onFormSubmissionFinished?: (e: FormSubmissionEvent) => void;
  onContentProcessDidTerminate?: (e: ContentProcessDidTerminateEvent) => void;
  onError?: OnErrorCallback;
  onMessage?: SessionMessageCallback;
  onAlert?: OnAlert;
  onConfirm?: OnConfirm;
  style?: StyleProp<ViewStyle>;
}

export interface RefObject {
  injectJavaScript: (callbackStringified: string) => void;
  reload: () => void;
  refresh: () => void;
}

const VisitableView = React.forwardRef<RefObject, React.PropsWithRef<Props>>(
  (props, ref) => {
    const {
      url,
      sessionHandle = 'Default',
      applicationNameForUserAgent,
      stradaComponents,
      pullToRefreshEnabled = true,
      scrollEnabled = true,
      contentInset = { top: 0, left: 0, right: 0, bottom: 0 },
      progressViewOffset,
      refreshControlTopAnchor = 0,
      webViewDebuggingEnabled = false,
      allowsInlineMediaPlayback = false,
      renderLoading,
      renderError,
      onLoad,
      onError: onErrorCustomHandler,
      onMessage,
      onVisitProposal,
      onOpenExternalUrl: onOpenExternalUrlCallback = openExternalURL,
      onAlert,
      onConfirm,
      onFormSubmissionStarted,
      onFormSubmissionFinished,
      onContentProcessDidTerminate,
      style = styles.container,
    } = props;
    const visitableViewRef = useRef<
      Component<RNVisitableViewProps> & NativeMethods
    >(null);

    const { registerMessageListener, handleOnMessage } =
      useMessageQueue(onMessage);

    const { initializeStradaBridge, stradaUserAgent, sendToBridge } =
      useStradaBridge(visitableViewRef, dispatchCommand, stradaComponents);

    const reloadVisitableView = useCallback(
      () => dispatchCommand(visitableViewRef, 'reload'),
      []
    );

    const {
      webViewStateComponent,
      handleShowLoading,
      handleHideLoading,
      handleRenderError,
    } = useWebViewState(reloadVisitableView, renderLoading, renderError);

    const resolvedApplicationNameForUserAgent = useMemo(
      () =>
        [applicationNameForUserAgent, stradaUserAgent]
          .filter(Boolean)
          .join(' '),
      [applicationNameForUserAgent, stradaUserAgent]
    );

    useImperativeHandle(
      ref,
      () => ({
        injectJavaScript: (callbackStringified) =>
          dispatchCommand(
            visitableViewRef,
            'injectJavaScript',
            callbackStringified
          ),
        reload: reloadVisitableView,
        refresh: () => dispatchCommand(visitableViewRef, 'refresh'),
      }),
      [reloadVisitableView]
    );

    const onErrorCombinedHandlers = useCallback(
      ({ nativeEvent }: NativeSyntheticEvent<ErrorEvent>) => {
        onErrorCustomHandler?.(nativeEvent);
        handleRenderError(nativeEvent);
      },
      [handleRenderError, onErrorCustomHandler]
    );

    const handleOnLoad = useCallback(
      ({ nativeEvent }: NativeSyntheticEvent<LoadEvent>) => {
        initializeStradaBridge();
        onLoad?.(nativeEvent);
      },
      [initializeStradaBridge, onLoad]
    );

    const handleVisitProposal = useCallback(
      ({ nativeEvent }: NativeSyntheticEvent<VisitProposal>) => {
        // Using nextEventLoopTick helps prevent a potential race condition
        // that might occur between onFormSubmissionFinished and onVisitProposal
        nextEventLoopTick(() => onVisitProposal(nativeEvent));
      },
      [onVisitProposal]
    );

    const handleOnOpenExternalUrl = useCallback(
      ({ nativeEvent }: NativeSyntheticEvent<OpenExternalUrlEvent>) =>
        onOpenExternalUrlCallback(nativeEvent),
      [onOpenExternalUrlCallback]
    );

    const handleOnFormSubmissionStarted = useCallback(
      ({ nativeEvent }: NativeSyntheticEvent<FormSubmissionEvent>) =>
        onFormSubmissionStarted?.(nativeEvent),
      [onFormSubmissionStarted]
    );

    const handleOnFormSubmissionFinished = useCallback(
      ({ nativeEvent }: NativeSyntheticEvent<FormSubmissionEvent>) =>
        onFormSubmissionFinished?.(nativeEvent),
      [onFormSubmissionFinished]
    );

    const { handleAlert, handleConfirm } = useWebViewDialogs(
      visitableViewRef,
      onAlert,
      onConfirm
    );

    const handleOnContentProcessDidTerminate = useCallback(
      ({
        nativeEvent,
      }: NativeSyntheticEvent<ContentProcessDidTerminateEvent>) =>
        onContentProcessDidTerminate
          ? onContentProcessDidTerminate(nativeEvent)
          : reloadVisitableView(),
      [onContentProcessDidTerminate]
    );

    return (
      <>
        {stradaComponents?.map((StradaComponent, i) => (
          <StradaComponent
            key={`${url}-${i}`}
            url={url}
            sessionHandle={sessionHandle}
            name={StradaComponent.componentName}
            registerMessageListener={registerMessageListener}
            sendToBridge={sendToBridge}
          />
        ))}
        <RNVisitableView
          ref={visitableViewRef}
          url={props.url}
          sessionHandle={sessionHandle}
          applicationNameForUserAgent={resolvedApplicationNameForUserAgent}
          pullToRefreshEnabled={pullToRefreshEnabled}
          scrollEnabled={scrollEnabled}
          contentInset={contentInset}
          progressViewOffset={progressViewOffset}
          refreshControlTopAnchor={refreshControlTopAnchor}
          webViewDebuggingEnabled={webViewDebuggingEnabled}
          allowsInlineMediaPlayback={allowsInlineMediaPlayback}
          onError={onErrorCombinedHandlers}
          onVisitProposal={handleVisitProposal}
          onMessage={handleOnMessage}
          onOpenExternalUrl={handleOnOpenExternalUrl}
          onLoad={handleOnLoad}
          onWebAlert={handleAlert}
          onWebConfirm={handleConfirm}
          onFormSubmissionStarted={handleOnFormSubmissionStarted}
          onFormSubmissionFinished={handleOnFormSubmissionFinished}
          onShowLoading={handleShowLoading}
          onHideLoading={handleHideLoading}
          onContentProcessDidTerminate={handleOnContentProcessDidTerminate}
          style={style}
        />
        {webViewStateComponent}
      </>
    );
  }
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});

export default VisitableView;
