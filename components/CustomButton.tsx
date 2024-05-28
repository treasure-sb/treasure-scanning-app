import { TouchableOpacity, Text, View } from "react-native"
import React from 'react'
import { styled } from "nativewind";
const StyledTouchableOpacity = styled(TouchableOpacity)
const StyledText = styled(Text)
const StyledView = styled(View)

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
        <StyledView className="w-full items-center">
            <StyledTouchableOpacity 
                onPress={handlePress}
                activeOpacity={0.7}
                className = {`bg-white rounded-xl h-[62px] justify-center items-center ${containerStyles} ${isLoading ? 'opacity-50':''}`}
                disabled={isLoading}
                style = {{
                    borderRadius: 25,
                    backgroundColor: "#73D08D",
                    width: "35%",
                    height: 50,
                }}
                >
                <StyledText style={{
                    color: "black",
                    fontWeight: "bold",
                    fontSize: 20
                }}>{title}</StyledText>
            </StyledTouchableOpacity>
        </StyledView>
        

    )
}

export default CustomButton