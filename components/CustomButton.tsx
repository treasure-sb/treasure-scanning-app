import { TouchableOpacity, Text } from "react-native"
import React from 'react'
import { styled } from "nativewind";
const StyledTouchableOpacity = styled(TouchableOpacity)
const StyledText = styled(Text)

export type Props = {
    title: string;
    handlePress?: ()=>void;
    containerStyles?: string;
    textStyles?: string;
    isLoading?: boolean;
        
}

const CustomButton: React.FC<Props> = ({
   title,
   handlePress,
   containerStyles,
   textStyles,
   isLoading
}) =>{
    return (

        <StyledTouchableOpacity 
            onPress={handlePress}
            activeOpacity={0.7}
            className = {`bg-white rounded-xl min-h-[62px] justify-center items-center ${containerStyles} ${isLoading ? 'opacity-50':''}`}
            disabled={isLoading}
            style = {{
                borderRadius: 25,
                backgroundColor: "#73D08D",
                width: "40%",
                height: "10%"
            }}
            >
            <StyledText style={{
                color: "black",
                fontWeight: "bold",
                fontSize: 20
            }}>{title}</StyledText>
        </StyledTouchableOpacity>

    )
}

export default CustomButton