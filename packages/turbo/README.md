# React Native Turbo

React Native [Hotwired Turbo](https://turbo.hotwired.dev/handbook/introduction) support for creating hybrid apps with a single shared web view session.

<p>
  <a aria-label="NPM version" href="https://www.npmjs.com/package/react-native-turbo" target="_blank">
    <img alt="NPM version" src="https://img.shields.io/npm/v/react-native-turbo?color=red&label=npm%20version" />
  </a>
  <a aria-label="Licence MIT" href="https://www.npmjs.com/package/react-native-web-screen" target="_blank">
    <img alt="Licence MIT" src="https://img.shields.io/github/license/software-mansion-labs/react-native-turbo-demo" />
  </a>
</p>

---

## Installation

First step is to install `react-native-turbo` as a dependency to your project:

```
yarn add react-native-turbo
```

For Android you need to adjust your SDK version in your `build.gradle`.

> [_Turbo Documentation:_](https://github.com/hotwired/turbo-android#requirements)
>
> Android SDK 28+ is required as the minSdkVersion in your build.gradle.

For iOS, you need to set the deployment target to 15.6 or higher.

## Example

Turbo `webview` can be rendered using native view `VisitableView`.

```jsx
import {
  VisitableView,
  OnLoadEvent,
  VisitProposal,
  Session,
} from 'react-native-turbo';
import { useNavigation } from '@react-navigation/native';

const TurboScreen = () => {
  const navigation = useNavigation();

  const onVisitProposal = ({ action: actionType, url }) => {
    // Handle opening new screen e.g. using react-navigation
    navigation.push('TurboScreen', { url });
  };

  return (
    <VisitableView
      url="https://turbo-native-demo.glitch.me"
      onVisitProposal={onVisitProposal}
    />
  );
};
```

You can use `onVisitProposal()` to handle turbo visits.

# API Reference

## VisitableView Component

Turbo manages a single webview instance, shared between multiple view controllers. It also automatically shows a screenshot of web page content when the web view is not focused. The `Visitable` views are rendered as a native view from React `RNVisitable`.

The library implements a native view `RNVisitable` component for React Native. This view is equivalent to the [Turbo Visitable](https://github.com/hotwired/turbo-ios/blob/main/Docs/Overview.md#visitable).

### Props:

### `url`

URL for the WKWebview to open. Changing the url should result in view replacing opening different page.

### `sessionHandle`

Session handle for the webview. If not provided, the default session will be used. It can be used to create separate webview instances for different parts of the app.

### `applicationNameForUserAgent`

The name of the application as used in the user agent string. Please note that changing this value after the session initialization will not change the user agent string.

### `pullToRefreshEnabled`

Enables pull to refresh functionality. Default value is `true`.

### `scrollEnabled`

Enables scrolling in the webview. Default value is `true`.

### `contentInset`

The amount by which the web view content is inset from the edges of the scroll view.

Note: available only on iOS.

### `refreshControlTopAnchor`

This property enables setting custom `topAnchor` for the native refresh control. If the value is set, the refresh control will be anchored to the top of the web view with the specified offset. By default, this value is set to the safe area top anchor.

Note: available only on iOS.

### `progressViewOffset`

The refresh indicator starting and resting position is always positioned near the top of the refreshing content. This position is a consistent location, but can be adjusted in either direction based on whether or not there is a header or other content that should be visible when the refresh indicator is shown.

Note: available only on Android.

### `webViewDebuggingEnabled`

Enables debugging in the webview. Default value is `false`.

### `allowsInlineMediaPlayback`

Controls whether HTML5 videos and audio can play inline automatically without user interaction. Default value is `false`.

Note: available only on iOS.

### `stradaComponents`

`VisitableView` supports defining [Strada components](https://strada.hotwired.dev/) that receive and reply to messages from web components that are present on the page within one session. This prop accepts an array of Strada components that will be registered in the webview.

You can define a Strada component by extending `BridgeComponent` class and implementing `onReceive` method and static `componentName` property.

```jsx
import { BridgeComponent } from 'react-native-turbo';

export default class FormComponent extends BridgeComponent {
  static componentName = 'form';

  onReceive(message: StradaMessage) {

    // Here you can catch events from webview and respond to them
    if (message.event === 'connect'){
      this.replyTo(message.event, { status: 'connected' });
    }
    ...
  }
}
```

In the WebView component, you should pass the array of Strada components to the `stradaComponents` prop.

```jsx
const stradaComponents = [FormComponent];

...

<VisitableView
  ...
  stradaComponents={stradaComponents}
/>
```

### `renderLoading`

Function that returns a loading indicator, which will be shown when the webview is loading.

Example:

```jsx
<VisitableView
  ...
  renderLoading={() => <Loading />}
/>
```

### `renderError`

Function that returns a view, which will be shown when error occurs.

Example:

```jsx
<VisitableView
  ...
  renderError={(errorObject, reloadFunction) => <Error error={errorObject} reload={reloadFunction} />}
/>
```

### `onVisitProposal`

Callback called when the webview detects turbo visit action.

- url
- action – e.g "replace"

### `onOpenExternalUrl`

Callback called when the webview detects non-turbo visit action (e.g. opening external link).

- url

### `onLoad`

Callback called with screen title and URL when the webview successfully loads.

- url
- title – web page

Note: When the title of a webpage is empty, the native WebView on Android resolves the title to the URL. This is not the case with WKWebView on iOS, which properly sets the title value. To override this behavior, you can set the title to a special whitespace character, for example, to [\&#65279;](https://stackoverflow.com/questions/42365138/empty-html-page-title).

### `onError`

Callback called when the webview fails to load.

- statusCode
- url
- description

`SystemStatusCode` enum is exported to help you interpret the status code. Every status code that is a positive number is an HTTP Error.

### `onMessage`

Function that is invoked when the webview calls `postMessage`. Setting this property will inject this global into your webview.

Currently you need to individually call this function for android and for ios separately.

```

AndroidInterface.postMessage(JSON.stringify({message}));
webkit.messageHandlers.nativeApp.postMessage(message);

```

### `onAlert`

Function called when website inside WebView is calling `alert` function. By default React Native's `Alert` is displayed.

Note that after handling alert display, `callback` function must be called.

- message
- callback

### `onConfirm`

Function called when website inside WebView is calling `confirm` function. By default React Native's `Alert` is displayed (with two buttons).

Note that after handling confirm dialog display, `callback` function must be called with result (`true`/`false`)

- message
- callback

### `onFormSubmissionStarted`

Callback called when website inside WebView started submitting form.

- url

### `onFormSubmissionFinished`

Callback called when website inside WebView finished submitting form.

- url

Note: The form submission handlers are triggered for the _session_ in which the form was submitted. A URL argument is available in these handlers, which can be used for granular control over the cache clearing process. For example, you might choose to clear the cache only for the specific URL that the form was submitted from.

### `onContentProcessDidTerminate`

Callback called when the webview content process is terminated.

### Methods:

### `injectJavaScript(jsCode)`

Executes the javascript code in the webview js runtime.

Supports async methods and promises.

```ts
const jsCode = "console.warn('foo')";

injectJavaScript(jsCode);
```

### `reload()`

Reloads the webview.

### `refresh()`

Refreshes the page. This method is equivalent to making a Turbo `replace` visit to the current URL.

## Session Component

Session component has been deprecated. To use multiple [sessions](https://github.com/hotwired/turbo-ios/blob/main/Docs/Overview.md#session), you can use `sessionHandle` prop on `VisitableView` component.

## Other utilities

Functions below might be useful in a scenario when a form submission is completed in the modal session - we need to manually clear the snapshot cache in the default session to avoid the use of potentially outdated cached snapshots.

### `getSessionHandles()`

Returns an array of all registered session handles.

### `reloadSession(sessionHandle)`

Reloads the page for the given `sessionHandle`.

### `refreshSession(sessionHandle)`

Refreshes the page for the given `sessionHandle`. This method is equivalent to making a Turbo `replace` visit to the current URL.

### `clearSessionSnapshotCache(sessionHandle)`

Clears the snapshot cache for the given `sessionHandle`.

---

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
