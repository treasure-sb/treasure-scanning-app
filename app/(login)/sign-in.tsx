import { View, Text, SafeAreaView, TouchableWithoutFeedback, Keyboard } from 'react-native';
import React, { useState } from 'react';
import { styled } from 'nativewind';
import FormField from '@/components/FormField';
import CustomButton from '@/components/CustomButton';
import { Link } from 'expo-router';

const StyledView = styled(View);
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);

const SignIn = () => {
  const [form, setForm] = useState({
    phoneNum: ''
  });

  const handleChangeText = (text: string) => {
    setForm({ ...form, phoneNum: text });
  };



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
            value={form.phoneNum}
            placeholder='Phone Number'
            placeholderTextColor='#535252'
            keyboardType="numeric"
            handleChangeText={handleChangeText}
          />
          <Link replace href="/email-sign-in" className="text-gray-400 mt-1 relative pl-[25%] pt-[0.3%] text-sm mb-12">
            Use email instead
          </Link>
          <CustomButton title="Continue" handlePress={() => {}} />
        </StyledView>
      </StyledSafeAreaView>
    </TouchableWithoutFeedback>
    
  );
}

export default SignIn;
