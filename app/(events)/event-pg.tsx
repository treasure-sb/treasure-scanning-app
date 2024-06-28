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
            {eventName}
        </StyledText>
        </StyledView>
        <StyledView className='f flex-row h-52 mb-4'>
          <TouchableWithoutFeedback onPress={async ()=>{
                  router.push({pathname:"../../scanner", params:{userID: userId}})
                  }   
              } style={{}}>
              <StyledView className="w-[45%] h-[95%] items-center ml-4 mr-2 bg-[#2A2424] bg-opacity-60 justify-start" style={{borderRadius:12}}>
                  <Image source={require("../../assets/images/scan-icon.png")} style={{width:55, height: 55, alignSelf:"center", marginTop:50}}/>
                  <StyledText className='font-bold text-2xl text-white absolute bottom-10'>Scan Tickets</StyledText>
              </StyledView>
            </TouchableWithoutFeedback>
            <TouchableWithoutFeedback onPress={async ()=>{
                  router.push({pathname:"./(event-specific)/attendee-pg", params:{eventID: eventId}})
                  }   
              }>
              <StyledView className="w-[45%] h-[95%] items-center mx-2 bg-[#2A2424] bg-opacity-60 justify-start" style={{borderRadius:12}}>
                  <Image source={require("../../assets/images/attendees.png")} style={{width:60, height: 60, alignSelf:"center", marginTop:47}}/>
                  <StyledText className='font-bold text-2xl text-white absolute bottom-10'>Attendees</StyledText>
              </StyledView>
            </TouchableWithoutFeedback>
        </StyledView>
        <StyledView className='flex-row h-52'>
          <TouchableWithoutFeedback onPress={async ()=>{
              router.push({pathname:"./(event-specific)/vendor-pg", params:{eventID: eventId}})
            }   
          }>
              <StyledView className="w-[45%] h-[95%] items-center mx-4 bg-[#2A2424] bg-opacity-60 justify-start" style={{borderRadius:12}}>
                  <Image source={require("../../assets/images/vendor.png")} style={{width:65, height: 65, alignSelf:"center", marginTop:45}}/>
                  <StyledText className='font-bold text-2xl text-white absolute bottom-10'>Vendors</StyledText>
              </StyledView>
          </TouchableWithoutFeedback>
        </StyledView>
      </StyledSafeAreaView>
)}

export default eventPg