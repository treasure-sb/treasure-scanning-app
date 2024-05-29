import { View, Text, Keyboard, SafeAreaView } from 'react-native'
import React, { useEffect, useState } from 'react'
import { TouchableWithoutFeedback } from 'react-native'
import { styled } from 'nativewind';
import { OtpInput } from "react-native-otp-entry";
import { useLocalSearchParams } from 'expo-router';
import { supabase, verifyMessageData } from '@/lib/supabase';
import Toast from 'react-native-toast-message';
import Header from '@/components/header';

const StyledView = styled(View);
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);

const formatPhoneNumber = (phoneNumber: any) => {
    // Ensure the input is a string and contains exactly 10 digits
    if (typeof phoneNumber !== 'string' || phoneNumber.length !== 10 || !/^\d{10}$/.test(phoneNumber)) {
      throw new Error('Input must be a 10-digit phone number string.');
    }
  
    // Use a regular expression to capture the parts of the phone number
    const formattedPhoneNumber = phoneNumber.replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3');
  
    return formattedPhoneNumber;
  };

const asyncisVerified = async (info: any, code:string, type:any) => {
    const  verificationResult = await verifyMessageData(info, code, type)
    console.log(verificationResult)
    console.log(code)
    setTimeout(()=>{
        {verificationResult.user ? Toast.show({
            type: 'success',
            text1: 'OTP Success!',
            text2: 'Your OTP verification was a succes!',
            position:'bottom'
        }) : Toast.show({
            type: 'error',
            text1: "OTP Error",
            text2: 'Your OTP verification failed, likely due to a wrong code',
            position:'bottom',
            
        })}
    }, 500)
    
} 


const otpCode = () => {
    const [code, setCode] = useState('')
    const {info, type} = useLocalSearchParams()

  return (
    <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
      <StyledSafeAreaView 
        className="flex-1"
        style={{
          backgroundColor: "#0D0F0E"
        }}
      >
        <Header />
        <StyledView className="w-full items-center px-4 mt-6 mb-2">
          <StyledText className="text-white text-2xl font-bold mb-6">
            Enter Code
          </StyledText>
        </StyledView>
        <StyledView className='items-start px-[72px] mb-4 w-auto'>
            <StyledText className='text-base justify-start' style={{color:"#535252", lineHeight:20}}>Enter the code we sent to</StyledText>
            <StyledText className='justify-start text-lg' style={{color:"white", lineHeight:20}}>{formatPhoneNumber(info)}</StyledText>
          </StyledView>
        <OtpInput numberOfDigits={6} onTextChange={(text) => setCode(text)} 
            blurOnFilled={true}
            theme={{
                containerStyle: {width:"auto", transform:[{scale:.66}]},
                pinCodeContainerStyle:{borderBottomColor: "#535252",
                    borderBottomWidth: 2, borderLeftWidth:0, borderRightWidth: 0, borderTopWidth:0, borderRadius: 0, width:55 },
                focusedPinCodeContainerStyle:{
                    borderBottomColor: "#73D08D"
                },
                pinCodeTextStyle:{
                    color:"white",
                }}
                }
                onFilled={async (text)=>asyncisVerified(info,text,type)} />
        <Toast />
      </StyledSafeAreaView>
    </TouchableWithoutFeedback>
  )
}

export default otpCode