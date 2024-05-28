import React, { useState } from 'react';
import { View, Text, TouchableWithoutFeedback, Keyboard, SafeAreaView, KeyboardTypeOptions } from 'react-native';
import { styled } from 'nativewind';
import FormField from '@/components/FormField';
import CustomButton from '@/components/CustomButton';
import { Link } from 'expo-router';

const StyledView = styled(View);
const StyledLink = styled(Link)
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);
export type Props = {
    placeholder: string;
    switchEmailOrPhoneText: string;
    keyboardType: KeyboardTypeOptions;
    switchHref: string;
    switchAction: () => void;

        
}

const SignInForm:React.FC<Props> = ({placeholder, keyboardType, switchEmailOrPhoneText, switchHref, switchAction }) => {
  const [form, setForm] = useState({
    value: ''
  });

  const handleChangeText = (text: string) => {
    setForm({ value: text });
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
          title={placeholder}
          value={form.value}
          placeholder={placeholder}
          placeholderTextColor='#535252'
          keyboardType={keyboardType}
          handleChangeText={handleChangeText}
        />
        <StyledLink replace href= {switchHref}className="text-gray-400 mt-1 relative pl-[25%] pt-[0.3%] text-sm mb-12">
          {switchEmailOrPhoneText}
        </StyledLink>
        <CustomButton title="Continue" handlePress={() => {}} />
      </StyledView>

     {/* button at bottom of screen, something to think about
      <StyledView className="w-full items-center justify-center">
        <CustomButton title="Continue" handlePress={() => {}} />
      </StyledView>
    */}
    </StyledSafeAreaView>
  </TouchableWithoutFeedback>
  );
};

export default SignInForm;