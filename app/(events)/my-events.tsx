import Header from "@/components/header";
import { View, Text, TouchableWithoutFeedback, Keyboard, FlatList, Image, ScrollView } from 'react-native'
import React, { useEffect, useState } from 'react'
import { SafeAreaView } from "react-native-safe-area-context";
import { styled } from "nativewind";
import { supabase, userID } from "@/lib/supabase";
import { createClient } from "@supabase/supabase-js";

const StyledView = styled(View);
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);
const StyledImage = styled(Image)

const myEvents = () => {
    const [events, getEvents] = useState([])
    const fetchEvents = async () => {supabase.from("events").select('title').eq('organizer_id', userID)}
    useEffect(() => {fetchEvents()}, [])
  return (
    <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
      <StyledSafeAreaView 
        className="flex-1"
        style={{
          backgroundColor: "#0D0F0E"
        }}
      >
        <Header />
        <StyledView className="w-full items-center px-4 mt-2 mb-0">
          <StyledText className="text-white text-2xl font-bold mb-0">
            My Events
          </StyledText>
        </StyledView>
        <StyledView className='items-center mb-4 w-auto'>
            <StyledText className='text-base' style={{color:"#535252", lineHeight:20}}>Click an event to start scanning tickets!</StyledText>
        </StyledView>
        <ScrollView>
        <FlatList
            data={events}
            renderItem={({ item }) => <Text>{item}</Text>}
            keyExtractor={(item) => item}
        />
        </ScrollView>
    </StyledSafeAreaView>
    </TouchableWithoutFeedback>
  )
}

export default myEvents