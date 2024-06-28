import Header from "@/components/header";
import { View, Text, FlatList, Image, TouchableHighlight } from 'react-native'
import React, { useEffect, useState } from 'react'
import { SafeAreaView } from "react-native-safe-area-context";
import { styled } from "nativewind";
import { supabase, userID } from "@/lib/supabase";
import { createClient } from "@supabase/supabase-js";
import { router, useLocalSearchParams, useRouter } from "expo-router";
import { format } from "date-fns";

const StyledView = styled(View);
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);
const StyledImage = styled(Image)

type Event = {
  name: string;
  poster_url: string;
  date: string;
  id: string
};
type EventsState = {
  data: Event[] | null;
  error: string | null;
};
const myEvents = () => {
  const [eventsState, setEventsState] = useState<EventsState>({ data: null, error: null });
  const {userID} = useLocalSearchParams()
  const router = useRouter();
  useEffect(() => {
    const fetchEvents = async () => {
      try {
        const {data : role, error : adminError} = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userID as NonNullable<string | string[] | undefined>).single();
        let tempData;
        if (role?.role === "admin"){
          const { data, error } = await supabase
          .from('events')
          .select('name, poster_url, date, id');
          tempData = {data, error}
        }
        else{
        const { data, error } = await supabase
        .from('events')
        .select('name, poster_url, date, id')
        .eq('organizer_id', userID as NonNullable<string | string[] | undefined>);
        tempData = {data, error}
      }
      const { data, error } = tempData

        if (error) {
          setEventsState({ data: null, error: error.message });
        } else {
          const sortedData = data?.sort((a, b) => (b.date as string).localeCompare(a.date as string));
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
                
                <TouchableHighlight onPress={()=>{router.push({pathname:"event-pg", params:{eventId: item.id, userId: userID, eventName:item.name, eventDate:item.date} })}}>
                <Image source={{uri:"https://qkdlfshzugzeqlznyqfv.supabase.co/storage/v1/object/public/posters/" + item.poster_url}} style={{
                  width:180,
                  height:180,
                  resizeMode:"center",
                  borderRadius:40,
                  overflow:"hidden"
                }}
                />
                </TouchableHighlight>
                <Text style={{color:"white", paddingBottom:0}} numberOfLines={1}>{item.name}
                </Text>
                <StyledView className="bg-[#535252] justify-bottom self-end justify-self-end w-max rounded-xl p-1 mb-5 mr-5">
                <Text style={{color:"white", textAlign:"right", width:"100%"}}>{new Date(item.date as string).toLocaleDateString(undefined,{day: "numeric",month: "short",timeZone: "UTC"})}</Text>
                </StyledView>
              </StyledView>
              
            }
              keyExtractor={(item) => item.name + item.date}
          />
        </StyledView>
        
    </StyledSafeAreaView>
  )
}

export default myEvents