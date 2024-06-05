import { View, Text, SafeAreaView, Image} from 'react-native'
import React from 'react'
import { styled } from 'nativewind';
import Header from "@/components/header";
import {format } from 'date-fns'
import { useLocalSearchParams } from 'expo-router';

const StyledView = styled(View);
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);
const StyledImage = styled(Image)

const eventPg = () => {
    const {eventId, userId, eventName, eventDate} = useLocalSearchParams()
    const d = new Date(eventDate as string)
    const formattedDate = format(d, "MMMM do")
    
  return (
    <StyledSafeAreaView 
      className="flex-1"
      style={{
        backgroundColor: "#0D0F0E",
        flex:1
      }}>
        <Header backButton={true} buttonTitle='My Events'/>
        <StyledView className=" justify-center w-full items-center px-4 mt-2 mb-10">
        <StyledText className="text-white text-2xl font-bold mb-0 text-center w-[75%]">
            {eventName + " " + formattedDate}
        </StyledText>
        </StyledView>
        <StyledView className='f flex-row'>
            <StyledView className="w-[50%] items-center px-4 mt-8 mb-0">
                <Image source={require("../../assets/images/scan-icon.png")} style={{width:120, height: 120}}/>
                <StyledText className='font-bold mt-6 text-lg text-white'>Scan Tickets</StyledText>
            </StyledView>

            <StyledView className="w-[50%] items-center px-4 mt-8 mb-0">
                <Image source={require("../../assets/images/attendees.png")} style={{width:120, height: 120}}/>
                <StyledText className='font-bold mt-6 text-lg text-white'>Attendees</StyledText>
            </StyledView>
            
        </StyledView>
        
      </StyledSafeAreaView>
)}

export default eventPg