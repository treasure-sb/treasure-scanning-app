import { StyleSheet, Text, View } from "react-native";
import { Slot, Stack } from "expo-router";
import Toast from "react-native-toast-message";

export default function RootLayout() {
  return (
    <>
      <Stack>
        <Stack.Screen name="index" options={{headerShown: false}} />
      </Stack>
      <Toast />
    </>
    

  )
}
