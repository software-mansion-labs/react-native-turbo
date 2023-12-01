import React from 'react';
import { createMaterialTopTabNavigator } from '@react-navigation/material-top-tabs';
import { webScreens } from 'example/src/webScreen';
import { NativeScreen } from 'react-native-screens';
import { Routes } from 'example/src/webScreenRoutes';

const Tab = createMaterialTopTabNavigator();

const NestedTab: React.FC = () => {
  return (
    <Tab.Navigator
      screenOptions={{
        tabBarActiveTintColor: '#00094a',
      }}
    >
      <Tab.Screen {...webScreens.screens.NestedTabWeb!} />
      <Tab.Screen
        name={Routes.NestedTabNative}
        component={NativeScreen}
        options={{ title: 'Nested Native' }}
      />
    </Tab.Navigator>
  );
};

export default NestedTab;
