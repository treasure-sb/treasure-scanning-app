import { View, Text } from 'react-native'
import React from 'react'
import { Stack } from 'expo-router'
import { StatusBar } from 'expo-status-bar'
import Toast from 'react-native-toast-message'

const AuthLayout = () => {
  return (
    <>
        <Stack screenOptions={{headerShown: false, animation:"none"}}>
            <Stack.Screen
              name="sign-in"
              options={{
                headerShown: false,
                animation:"none"
              }}>
            </Stack.Screen>
        </Stack>
        
        <StatusBar backgroundColor="#161622" style='light'/>
        <Toast />
    </>
  )
}

export default AuthLayout