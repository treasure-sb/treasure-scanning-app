import { View, Text, SafeAreaView, TouchableWithoutFeedback, Keyboard } from 'react-native';
import React, { useState } from 'react';
import { styled } from 'nativewind';
import FormField from '@/components/FormField';
import CustomButton from '@/components/CustomButton';
import { supabase, handleInfoSubmit } from '@/lib/supabase';
import { router, useLocalSearchParams } from 'expo-router';
import Toast from 'react-native-toast-message';
const StyledView = styled(View);
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);

const SignIn = () => {
  const [form, setForm] = useState({
    phoneNum: '',
    email: ''
  });

  const handleChangeText = (text: string) => {
    useEmail ? setForm({...form, email:text}) : setForm({ ...form, phoneNum: text });
    setEmailVerify(false)
    setPhoneVerify(false)
    setPrintBadFormat(false)
    if(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(text)){
      setEmailVerify(true)
    }
    if(/^\d{10}$/.test(text)){
      setPhoneVerify(true)
    }
  };
  
  const [useEmail, setUseEmail] = useState(false);

  const handleChangeInputType = () => {
    setUseEmail((prev) => !prev)
  };
  
  const [emailVerify, setEmailVerify] = useState(false)
  const [phoneVerify, setPhoneVerify] = useState(false)
  const [printBadFormat, setPrintBadFormat] = useState(false)
  const [badFormatString, setBadFormatString] = useState('')
  const params = useLocalSearchParams()

  return (
    <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
      <StyledSafeAreaView 
        className="flex-1"
        style={{
          backgroundColor: "#0D0F0E"
        }}
      >
        <StyledView className="w-full items-center px-4 mt-6 mb-4">
          <StyledText className="text-white text-2xl font-bold mb-12">
            Welcome to Treasure
          </StyledText>
        </StyledView>
        
        <StyledView className='flex-1 w-full'>
          <FormField 
            title='Phone Number'
            value={useEmail ? form.email : form.phoneNum}
            placeholder={useEmail ? 'Email Address' : 'Phone Number'}
            placeholderTextColor='#535252'
            keyboardType={useEmail ? 'email-address':"numeric"}
            handleChangeText={handleChangeText}
          />
          <StyledText className="text-gray-400 mt-1 relative pl-[25%] pt-[0.3%] text-sm mb-12" onPress={handleChangeInputType}>
            {useEmail ? 'Use phone number instead':'Use email instead'}
          </StyledText>
          <StyledView style={{alignItems: "center"}}>
            
            <CustomButton title="Continue" handlePress={() => {
              if (useEmail){
                if(!emailVerify){
                  setBadFormatString('Email has incorrect format... ex: email@company.com')
                  setPrintBadFormat(true)
                }
                else{
                  handleInfoSubmit(form.email, useEmail)
                  router.push({pathname:'./otp-code', params: {input:form.email, type: "email"} })
                }
                
              }
              if(!useEmail){
                if (!phoneVerify){
                  setBadFormatString('Phone number has incorrect format.. ex: 5555555555')
                  setPrintBadFormat(true)

                }
                else{
                  handleInfoSubmit(form.phoneNum, useEmail)
                  router.push({pathname:'./otp-code', params: {info:form.phoneNum, type: "phone"} })
                }
              }
            }} />
            <StyledText className='text-red-600 text-sm pt-6'>{printBadFormat ? badFormatString : null} </StyledText>
          </StyledView>
        </StyledView>
      
      </StyledSafeAreaView>
    </TouchableWithoutFeedback>
    
  );
}

export default SignIn;
