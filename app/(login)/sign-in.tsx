import { View, Text, SafeAreaView, TouchableWithoutFeedback, Keyboard } from 'react-native';
import React, { useState } from 'react';
import { styled } from 'nativewind';
import FormField from '@/components/FormField';
import CustomButton from '@/components/CustomButton';
import { supabase } from '@/lib/supabase';
import { router } from 'expo-router';

const StyledView = styled(View);
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);
const countryCode = "+1";

/*const { data, error } = await supabase.auth.signInWithOtp({
  email: '',
  options: {
    shouldCreateUser: false
  }
})

const { data: { session }, error } = await supabase.auth.verifyOtp({
  email: '',
  token: '',
  type: 'email',
})
*/

/*const handlePhoneSubmit = async(phoneNumber: string) =>{
  const formattedPhoneNumber = `${countryCode}${phoneNumber}`
  const sendMsgData = await supabase.auth.signInWithOtp({
    phone: formattedPhoneNumber,
  })
const verifyMessageData = await supabase.auth.verifyOtp({
  phone: '+13334445555',
  token: '123456',
  type: 'sms',
})
}*/
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
                  router.push('./otp-code')
                }
                
              }
              if(!useEmail){
                if (!phoneVerify){
                  setBadFormatString('Phone number has incorrect format.. ex: 5555555555')
                  setPrintBadFormat(true)
                }
                else{
                  router.push('./otp-code')
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
