import React from 'react'
import { Slot, Stack } from 'expo-router'
import { StatusBar } from 'expo-status-bar'
import Toast from 'react-native-toast-message'

const AuthLayout = () => {
  return (
    <>
        < Slot />
        <Toast />
    </>
  )
}

export default AuthLayout