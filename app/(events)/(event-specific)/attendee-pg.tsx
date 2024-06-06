import { View, Text, SafeAreaView, FlatList } from 'react-native'
import React, { useEffect, useState } from 'react'
import { styled } from 'nativewind';
import Header from '@/components/header';
import { Ticket, supabase } from '@/lib/supabase';
import { useLocalSearchParams } from 'expo-router';
import { Database } from '../../../types/supabase'

const StyledView = styled(View);
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);

type ticketsState = {
    data: Ticket[] | null;
    error: string | null;
  };
  

const attendees = () => {
    const {eventID} = useLocalSearchParams()
    const [ticketsState, setticketsState] = useState<ticketsState>({ data: null, error: null });
    useEffect(() => {
        const fetchAttendees = async () => {
            try {
              const { data, error } = await supabase
                        .from('event_tickets')
                        .select('profiles(first_name, last_name), tickets("name"), id, valid')
                        .eq('event_id', eventID as NonNullable<string | string[] | undefined>)

      
              if (error) {
                setticketsState({ data: null, error: error.message })
              } else {
                const tickets: Ticket[] = data.map((item) => ({
                  userName: `${item.profiles?.first_name} ${item.profiles?.last_name}`,
                  ticketType: item.tickets?.name as string,
                  ticketId: item.id as string,
                  isValid: item.valid
              }));
                setticketsState({ data:tickets, error: null });
              }
            } catch (err: any) {
              setticketsState({ data: null, error: err.message })
            }
          }
        
        fetchAttendees()
    }, [])
  return (
    <StyledSafeAreaView 
      className="flex-1"
      style={{
        backgroundColor: "#0D0F0E",
        flex:1
      }}>
        <Header backButton={true}/>
        <StyledView className=" justify-center w-full items-center px-4 mt-4">
        <StyledText className="text-[#73D08D] text-2xl font-bold mb-0 text-center w-[75%]">
            Attendees
        </StyledText>
        </StyledView>
        <StyledView className='flex-row width-full'>
          <StyledText className='font-bold w-[33%] text-white text-sm pl-3'>Name</StyledText>
          <StyledText className='font-bold w-[33%] text-center text-white text-sm'>Ticket Type</StyledText>
          <StyledText className='font-bold w-[33%] text-right text-white text-sm pr-3'>Check In</StyledText>
        </StyledView>
        
          <FlatList
          data = {ticketsState.data}
          scrollToOverflowEnabled = {true}
          style = {{flexGrow:1}}
          
          renderItem = {( {item }) =>
            <StyledView className='pt-2 pb-[1px] justify-center pl-[3px]' style={{height:75}}>
              <StyledView className = "flex-row w-[99%] h-full bg-[#2A2424] items-center pl-1" style={{borderRadius:25}}>
                <StyledText className='w-[33%] text-white text-left text-ellipsis align-middle text-md pl-[2px]' >{item.userName}</StyledText>
                <StyledText className='w-[33%] text-white text-center text-ellipsis align-middle text-md pl-[2px]' >{item.ticketType}</StyledText>        
              </StyledView>
            </StyledView>
            
          }
          keyExtractor = {(item) => item.ticketId}
           />
      </StyledSafeAreaView>
    
  )
}

export default attendees