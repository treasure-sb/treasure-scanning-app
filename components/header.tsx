import { View, Text, Image, TouchableWithoutFeedback } from 'react-native';
import React from 'react';
import { styled } from 'nativewind';
import { router } from 'expo-router';

const StyledView = styled(View);
const StyledImage = styled(Image);

export type Props = {
  backButton?: boolean;
  buttonTitle?: string;
};

const Header: React.FC<Props> = ({
  backButton = false,
  buttonTitle = ''
}) => {

  return (
    <StyledView
      className='h-[10%] align-top'
      style={{
        height: '10%',
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 20,
        paddingTop: 0,
      }}
    >
        <TouchableWithoutFeedback onPress={()=>{router.back()}}>
            <StyledView
                className='align-top'
                style={{
                flexDirection: 'row',
                alignItems: 'center',
                }}
            >
                
                    {backButton ? (
                    <Image
                        source={require('../assets/images/back-btn.png')}
                    />
                    ) : null}
                    {buttonTitle ? (
                    <Text style={{ color: 'white', fontSize: 18, marginLeft:3}}>{buttonTitle}</Text>
                    ) : null}
            </StyledView>
      </TouchableWithoutFeedback>
      <StyledView
        className='align-top'
        style={{
          alignItems: 'center',
        }}
      >
        <StyledImage
          resizeMode='contain'
          source={require('../assets/images/emerald.png')}
          style={{
            width: 30, // Adjust width as needed
            height: 30, // Adjust height as needed
          }}
        />
      </StyledView>
    </StyledView>
  );
};

export default Header;
