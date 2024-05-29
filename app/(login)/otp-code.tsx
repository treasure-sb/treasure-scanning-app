import { View, Text, Keyboard, SafeAreaView } from 'react-native'
import React, { useState } from 'react'
import { TouchableWithoutFeedback } from 'react-native'
import { styled } from 'nativewind';
import { OtpInput } from "react-native-otp-entry";

const StyledView = styled(View);
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);
const info = "email@company.com"
//make this a component w info: string paramenter
const otpCode = () => {
  return (
    <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
      <StyledSafeAreaView 
        className="flex-1"
        style={{
          backgroundColor: "#0D0F0E"
        }}
      >
        <StyledView className="w-full items-center px-4 mt-6 mb-2">
          <StyledText className="text-white text-2xl font-bold mb-6">
            Enter Code
          </StyledText>
        </StyledView>
        <StyledView className='items-start px-[72px] mb-4'>
            <StyledText className='text-base justify-start' style={{color:"#535252"}}>Enter the code we sent to</StyledText>
            <StyledText className='justify-start text-base' style={{color:"white"}}>{info}</StyledText>
          </StyledView>
        <OtpInput numberOfDigits={6} onTextChange={(text) => console.log(text)} 
            blurOnFilled={true}
            theme={{
                containerStyle: {width:"auto", transform:[{scale:.66}]},
                pinCodeContainerStyle:{borderBottomColor: "#535252",
                    borderBottomWidth: 2, borderLeftWidth:0, borderRightWidth: 0, borderTopWidth:0, borderRadius: 0, },
                focusedPinCodeContainerStyle:{
                    borderBottomColor: "#73D08D"
                },
                pinCodeTextStyle:{
                    color:"white",
                }}
                } />
      </StyledSafeAreaView>
    </TouchableWithoutFeedback>
  )
}

export default otpCode