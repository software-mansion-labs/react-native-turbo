import React from 'react';
import {
  LoadEvent,
  VisitableView,
  VisitProposal,
  OnErrorCallback,
  VisitableViewProps,
} from 'react-native-turbo';
import { useCurrentUrl, useWebviewNavigate } from 'react-native-web-screen';
import { Routes } from './webScreenRoutes';
import Form from './Strada/Form';

export type Props = {
  navigation: any;
  baseURL?: string;
} & VisitableViewProps;

const sessionHandle = 'TurboWebviewExample';
const stradaComponents = [Form];

const WebView: React.FC<Props> = ({ baseURL, navigation, ...props }) => {
  const navigateTo = useWebviewNavigate();

  const currentUrl = useCurrentUrl(baseURL);

  const onVisitProposal = ({ action: actionType, url }: VisitProposal) => {
    navigateTo(url, actionType);
  };

  const onLoad = ({ title }: LoadEvent) => {
    navigation.setOptions({ title });
  };

  const onVisitError: OnErrorCallback = (error) => {
    const notLoggedIn = error.statusCode === 401;
    if (notLoggedIn) {
      navigation.navigate(Routes.SignIn, { path: 'signin' });
    }
  };

  return (
    <VisitableView
      {...props}
      sessionHandle={sessionHandle}
      url={currentUrl}
      applicationNameForUserAgent="Turbo Native"
      stradaComponents={stradaComponents}
      onVisitProposal={onVisitProposal}
      onLoad={onLoad}
      onVisitError={onVisitError}
    />
  );
};

export default WebView;
