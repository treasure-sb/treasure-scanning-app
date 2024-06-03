import Header from "@/components/header";
import { View, Text, TouchableWithoutFeedback, Keyboard, FlatList, Image, ScrollView } from 'react-native'
import React, { useEffect, useState } from 'react'
import { SafeAreaView } from "react-native-safe-area-context";
import { styled } from "nativewind";
import { supabase, userID } from "@/lib/supabase";
import { createClient } from "@supabase/supabase-js";
import { useLocalSearchParams } from "expo-router";

const StyledView = styled(View);
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);
const StyledImage = styled(Image)

type Event = {
  name: string;
  poster_url: string;
  date: string;
};
type EventsState = {
  data: Event[] | null;
  error: string | null;
};
const myEvents = () => {
  const [eventsState, setEventsState] = useState<EventsState>({ data: null, error: null });
  const {ID} = useLocalSearchParams()
  useEffect(() => {
    const fetchEvents = async () => {
      try {
        const { data, error } = await supabase
          .from('events')
          .select('name, poster_url, date')
          .eq('organizer_id', ID);

        if (error) {
          setEventsState({ data: null, error: error.message });
        } else {
          setEventsState({ data, error: null });
        }
      } catch (err: any) {
        setEventsState({ data: null, error: err.message });
      }
    };
    
    fetchEvents();
  }, []);
  return (
      <StyledSafeAreaView 
        className="flex-1"
        style={{
          backgroundColor: "#0D0F0E",
          flex:1
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
        <StyledView className="p-1 items-center flex-1">
          <FlatList
              data={eventsState.data}
              numColumns={2}
              scrollEnabled={true}
              scrollToOverflowEnabled={true}
              style={{flexGrow: 1}}
              renderItem={({ item }) => 
              <StyledView style={{
                width:'50%',
                height: "auto",
                alignItems:"center",
                justifyContent:"space-evenly"

              }}
              >
                <Image source={{uri:"https://qkdlfshzugzeqlznyqfv.supabase.co/storage/v1/object/public/posters/" + item.poster_url}} style={{
                  width:180,
                  height:180,
                  resizeMode:"center",
                  borderRadius:40,
                  overflow:"hidden"
                }}/>
                <Text style={{color:"white", paddingBottom:20}} numberOfLines={2}>{item.name}</Text>
                <>{console.log("https://qkdlfshzugzeqlznyqfv.supabase.co/storage/v1/object/public/posters/" + item.poster_url)}</>
              </StyledView>
              
            }
              keyExtractor={(item) => item.name + item.date}
          />
        </StyledView>
        
    </StyledSafeAreaView>
  )
}

export default myEvents