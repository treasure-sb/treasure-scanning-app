import { View, Text, TextInput, KeyboardTypeOptions } from 'react-native'
import React from 'react'
import { styled } from 'nativewind'
const StyledView = styled(View)
const StyledText = styled(Text)
const StyledTextInput = styled(TextInput)

export type Props = {
    title?: string;
    placeholder: string;
    placeholderTextColor?: string;
    value: string;
    keyboardType: KeyboardTypeOptions;
    handleChangeText: (text: string) => void;
    //autoComplete: autoComplete type string doesn't work
        
}
const FormField: React.FC<Props> = ({
    title,
    placeholder,
    placeholderTextColor = "#535252",
    value,
    keyboardType,
    handleChangeText,
    //autoComplete
 }) =>{
    const [text, onChangeText] = React.useState('');
  return (
    <StyledView className = "space-y-2 mt-7 items-center">
      <StyledView
        style={{
            alignItems: "flex-start",
            borderBottomColor: "#535252",
            borderBottomWidth: 1,
            width:"50%",
            height: 30
          }}
          >
        <StyledTextInput 
          className='flex-1 text-white font-semibold text-base' 
          style={{
            color:"white",
            fontWeight:"300",
            fontSize:18,
            textAlign:"left",
            width:"100%",
            
            
            
        }}
          value={value}
          placeholder={placeholder}
          placeholderTextColor={placeholderTextColor}
          keyboardType = {keyboardType}
          onChangeText={handleChangeText}
          //autoComplete={autoComplete}

          />
      </StyledView>
    </StyledView>
  )
}

export default FormField