import { View, Text, SafeAreaView, Image, TouchableWithoutFeedback} from 'react-native'
import React from 'react'
import { styled } from 'nativewind';
import {format } from 'date-fns'
import { router, useLocalSearchParams } from 'expo-router';
import Header from "@/components/header";

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
        <TouchableWithoutFeedback onPress={async ()=>{
                router.push({pathname:"../../scanner", params:{userID: userId}})
                }   
            }>
            <StyledView className="w-[50%] items-center px-4 mt-8 mb-0">
                <Image source={require("../../assets/images/scan-icon.png")} style={{width:120, height: 120}}/>
                <StyledText className='font-bold mt-6 text-lg text-white'>Scan Tickets</StyledText>
            </StyledView>
          </TouchableWithoutFeedback>
            <TouchableWithoutFeedback onPress={async ()=>{
                router.push({pathname:"./(event-specific)/attendee-pg", params:{eventID: eventId}})
                }   
            }>
            <StyledView className="w-[50%] items-center px-4 mt-8 mb-0">
                <Image source={require("../../assets/images/attendees.png")} style={{width:120, height: 120}}/>
                <StyledText className='font-bold mt-6 text-lg text-white'>Attendees</StyledText>
            </StyledView>
            </TouchableWithoutFeedback>
            
            
        </StyledView>
        
      </StyledSafeAreaView>
)}

export default eventPg