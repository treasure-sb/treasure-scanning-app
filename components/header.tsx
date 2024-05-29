import { View, Text, Image } from 'react-native'
import React from 'react'
import { styled } from 'nativewind'


const StyledView = styled(View)
const StyledImage = styled(Image)
const Header = () => {
  return (
    <StyledView className='h-[10%] align-top' style={{
        height:"10%",
        
    }}>
        <StyledView className='h-[10%] align-top' style={{
        paddingRight:20,
        paddingTop:15,
        alignItems:"flex-end",
        justifyContent:"flex-start"
    }}>
        <StyledImage resizeMode='contain' source={require('../assets/images/emerald.png')} style={{
            paddingRight:10
        }}/>
    </StyledView>
    <StyledView className='h-[10%] align-top' style={{
        paddingRight:20,
        paddingTop:15,
        alignItems:"flex-start",
        justifyContent:"flex-start"
    }}>

    </StyledView>
        
    </StyledView>
  )
}

export default Header