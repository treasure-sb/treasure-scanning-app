// EmailSignIn.js
import React from 'react';
import { SafeAreaView } from 'react-native';
import { styled } from 'nativewind';
import SignInForm from '../../components/SignInForm';

const StyledSafeAreaView = styled(SafeAreaView);

const EmailSignIn = () => {
  const handleSwitch = () => {
    // Handle navigation to the other page here
  };

  return (
    <StyledSafeAreaView 
      className="flex-1"
      style={{
        backgroundColor: "#0D0F0E"
      }}
    >
      <SignInForm 
        placeholder="Email"
        switchEmailOrPhoneText="Use phone number instead"
        keyboardType='default'
        switchHref='sign-in'
        switchAction={handleSwitch}
      />
    </StyledSafeAreaView>
  );
};

export default EmailSignIn;
