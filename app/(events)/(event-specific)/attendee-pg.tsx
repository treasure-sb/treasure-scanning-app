import { View, Text, SafeAreaView, FlatList, TouchableOpacity, TextInput, TouchableWithoutFeedback, Keyboard } from 'react-native'
import Icon from 'react-native-vector-icons/EvilIcons'
import React, { useEffect, useState } from 'react'
import { styled } from 'nativewind'
import Header from '@/components/header'
import { Ticket, supabase } from '@/lib/supabase'
import { useLocalSearchParams } from 'expo-router'
import Toast from 'react-native-toast-message'
import ParticipantModal from '@/components/ParticipantModal'
import { formatPhoneNumber } from '@/components/formattedPhoneNumber'


const StyledView = styled(View);
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);
const StyledTouchableOpacity = styled(TouchableOpacity)
const StyledTextInput = styled(TextInput)

type ticketsState = {
    data: Ticket[] | null;
    error: string | null;
  }
  


const attendees = () => {
    const {eventID} = useLocalSearchParams()
    const [refresh, setRefresh] = useState(0);
    const [ticketsState, setticketsState] = useState<ticketsState>({ data: null, error: null });
    const [searchQuery, setSearchQuery] = useState('');
    const [filteredData, setFilteredData] = useState<Ticket[] | null>(null);
    const [modalVisible, setModalVisible] = useState(false)
    const [selectedTicket, setSelectedTicket] = useState<Ticket | null>(null);
    const [isRefreshing, setIsRefreshing] = useState(false)
    const fetchAttendees = async () => {
      try {
        const { data, error } = await supabase
                  .from('event_tickets')
                  .select('profiles(first_name, last_name, email, phone), tickets("name"), id, valid')
                  .eq('event_id', eventID as NonNullable<string | string[] | undefined>)
        console.log({data, error})

        if (error) {
          setticketsState({ data: null, error: error.message })
        } else {
          const tickets: Ticket[] = data.map((item) => ({
            userName: `${item.profiles?.first_name} ${item.profiles?.last_name}`,
            ticketType: item.tickets?.name as string,
            ticketId: item.id as string,
            email: item.profiles?.email,
            phone: item.profiles?.phone,
            isValid: item.valid
        }));
          setticketsState({ data:tickets, error: null });
          setFilteredData(tickets); // Set the initial filtered data
        }
      } catch (err: any) {
        setticketsState({ data: null, error: err.message })
      }
    }
    useEffect(() => {
        fetchAttendees()
    }, [])
    useEffect(() => {
      if (searchQuery) {
        const filtered = ticketsState.data?.filter((ticket) =>
          ticket.userName.toLowerCase().includes(searchQuery.toLowerCase()) ||
          ticket.email?.toLowerCase().includes(searchQuery.toLowerCase()) ||
          ticket.phone?.toLowerCase().includes(searchQuery.toLowerCase())
        );
        setFilteredData(filtered || []);
      } else {
        setFilteredData(ticketsState.data);
      }
    }, [searchQuery, ticketsState.data]);
  return (
    
      <StyledSafeAreaView 
      className="flex-1"
      style={{
        backgroundColor: "#0D0F0E",
        flex:1
      }}
      >
        
        <Header backButton={true}/>
        <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
        <StyledView className=" justify-center w-full items-center px-4 mt-4">
        <StyledText className="text-[#73D08D] text-2xl font-bold mb-0 text-center w-[75%]">
            Attendees
        </StyledText>
        </StyledView>
        </TouchableWithoutFeedback>
        <StyledView className="flex-row justify-center w-full px-2 mt-4 mb-4 items-center self-center" style={{
          borderRadius: 30,
          width: "98%",
          flexDirection: "row",
          backgroundColor: "#2A2424",
          height: 30,

        }}>
          <Icon name="search" size={30} color= "#535252" />
          <StyledTextInput
            style={{
              flex:1,
              height:25,
              color:"white",

            }}
            placeholder="Search by name, email, or phone..."
            
            value={searchQuery}
            onChangeText={(text) => setSearchQuery(text)}
          />
      </StyledView>
        <StyledView className='flex-row width-full mt-4'>
          <StyledText className='font-bold w-[33%] text-white text-sm pl-6'>Name</StyledText>
          <StyledText className='font-bold w-[33%] text-center text-white text-sm'>Ticket Type</StyledText>
          <StyledText className='font-bold w-[33%] text-right text-white text-sm pr-8'>Check In</StyledText>
        </StyledView>
        
          <FlatList
          data = {filteredData}
          scrollToOverflowEnabled = {true}
          style = {{flexGrow:1}}
          extraData={[refresh, filteredData]}
          onScrollBeginDrag={Keyboard.dismiss}
          renderItem = {( {item }) =>
            <StyledView className='pt-2 pb-[1px] justify-center pl-[3px]' style={{height:75}}>
              <TouchableOpacity onPress={() => {
                    setSelectedTicket(item)
                    setModalVisible(true)
                }}>
              <StyledView className = "flex-row w-[99%] h-full bg-[#2A2424] items-center pl-1" style={{borderRadius:30}}>
                <StyledText className='w-[33%] text-white text-left text-ellipsis align-middle text-md pl-4' >{item.userName}</StyledText>
                <StyledText className='w-[33%] text-white text-center text-ellipsis align-middle text-md pl-[2px]' >{item.ticketType}</StyledText> 
                <TouchableOpacity 
                    onPress={async () => {
                      if (item.isValid) {
                        await supabase.from('event_tickets').update({ valid: false }).eq('id', item.ticketId);
                        item.isValid = false;
                      } else {
                        await supabase.from('event_tickets').update({ valid: true }).eq('id', item.ticketId);
                        Toast.show({
                          type: 'success',
                          text1: "Attendee Was Checkout Out",
                          text2: item.userName + " is checked out",
                          position:'bottom',
                          visibilityTime:2000
                          
                        })
                        item.isValid = true;
                      }
                      setRefresh((prev) => prev + 1);
                    }}
                    activeOpacity={0.7}
                    style = {{
                      flex:1,
                      borderRadius: 30,
                      backgroundColor: item.isValid ? "#73D08D" : "#535252",
                      width: 80,
                      height: 50,
                      marginLeft:15,
                      marginRight:4,
                      alignItems:"center",
                      justifyContent:"center"
                    }}
                    >
                    <StyledText style={{
                        color: item.isValid ? "black": "white",
                        fontWeight: "bold",
                        fontSize: 16
                    }}>{item.isValid ? "Check In" : "Checked In"}</StyledText>
                </TouchableOpacity>
                
                
      
              </StyledView>
              </TouchableOpacity>
            </StyledView>
            
          }
          refreshing={isRefreshing}
          onRefresh={() => {setIsRefreshing(true)
            fetchAttendees()
            setIsRefreshing(false)}
          }
          keyExtractor = {(item) => item.ticketId}
           />
           {selectedTicket && (
                <ParticipantModal
                visible={modalVisible}
                onClose={() => setModalVisible(false)}
                onCheckIn={async() => {
                  if (selectedTicket.isValid) {
                    await supabase.from('event_tickets').update({ valid: false }).eq('id', selectedTicket.ticketId);
                    selectedTicket.isValid = false;
                  } else {
                    await supabase.from('event_tickets').update({ valid: true }).eq('id', selectedTicket.ticketId);
                    Toast.show({
                      type: 'success',
                      text1: "Attendee Was Checkout Out",
                      text2: selectedTicket.userName + " is checked out",
                      position:'bottom',
                      visibilityTime:2000
                      
                    })
                    selectedTicket.isValid = true;
                  }
                  setRefresh((prev) => prev + 1);
                }}
                name={selectedTicket.userName}
                contact={selectedTicket.phone ? formatPhoneNumber(selectedTicket.phone.substring(2) as string) : selectedTicket.email as string}
                checkedIn = {!selectedTicket.isValid}
                participantType='attendee'
                />
            )}
      </StyledSafeAreaView>
    
    
    
  )
}

export default attendees