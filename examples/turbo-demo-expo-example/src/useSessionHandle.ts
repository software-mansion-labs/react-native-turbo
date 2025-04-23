import {
  NavigationState,
  PartialState,
  useNavigation,
} from '@react-navigation/native';

function unpackState(
  state: NavigationState | PartialState<NavigationState> | undefined
) {
  const nestedState = state?.routes[0]?.state;
  if (nestedState) {
    return unpackState(nestedState);
  }

  return state;
}

export function useSessionHandle() {
  const navigation = useNavigation();
  const state = unpackState(navigation.getState());
  if (!state?.routeNames || (!state.index && state.index !== 0)) {
    return 'Default';
  }
  return state.routeNames[state.index];
}
