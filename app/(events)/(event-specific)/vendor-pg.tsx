import { View, Text, SafeAreaView, FlatList, TouchableOpacity, TextInput, TouchableWithoutFeedback, Keyboard } from 'react-native'
import Icon from 'react-native-vector-icons/EvilIcons'
import React, { useEffect, useState } from 'react'
import { styled } from 'nativewind'
import Header from '@/components/header'
import { Vendor, supabase } from '@/lib/supabase'
import { useLocalSearchParams } from 'expo-router'
import ParticipantModal from '@/components/ParticipantModal'


const StyledView = styled(View);
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);
const StyledTouchableOpacity = styled(TouchableOpacity)
const StyledTextInput = styled(TextInput)

type vendorsState = {
    data: Vendor[] | null;
    error: string | null;
  }
  


const vendors = () => {
    const {eventID} = useLocalSearchParams()
    const [refresh, setRefresh] = useState(0)
    const [vendorsState, setvendorsState] = useState<vendorsState>({ data: null, error: null })
    const [searchQuery, setSearchQuery] = useState('')
    const [filteredData, setFilteredData] = useState<Vendor[] | null>(null)
    const [modalVisible, setModalVisible] = useState(false)
    const [selectedVendor, setSelectedVendor] = useState<Vendor | null>(null);
    const fetchVendors = async () => {
        try {
          const { data, error } = await supabase
                    .from('event_vendors')
                    .select('profiles(first_name, last_name, email, phone), tables(quantity, section_name), vendor_id, checked_in')
                    .eq('event_id', eventID as NonNullable<string | string[] | undefined>)
          console.log({data, error})
  
          if (error) {
            setvendorsState({ data: null, error: error.message })
          } else {
            const vendors: Vendor[] = data.map((item) => ({
              userName: `${item.profiles?.first_name} ${item.profiles?.last_name}`,
              tableId: item.vendor_id,
              tableQuantity: item.tables?.quantity ? item.tables?.quantity : 0,
              tableSection: item.tables?.section_name as string,
              vendorId: item.vendor_id as string,
              email: item.profiles?.email,
              phone: item.profiles?.phone,
              checkedIn: item.checked_in
          }));
            setvendorsState({ data:vendors, error: null });
            setFilteredData(vendors); // Set the initial filtered data
          }
        } catch (err: any) {
          setvendorsState({ data: null, error: err.message })
        }
      }
      useEffect(() => {
          fetchVendors()
      }, [])
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
              Vendors
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
            <StyledText className='font-bold w-[33%] text-white text-sm pl-4'>Name</StyledText>
            <StyledText className='font-bold w-[33%] text-center text-white text-sm'>Tables</StyledText>
            <StyledText className='font-bold w-[33%] text-right text-white text-sm pr-4'>Check In</StyledText>
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
                    setSelectedVendor(item)
                    setModalVisible(true)
                }}>
                <StyledView className = "flex-row w-[99%] h-full bg-[#2A2424] items-center pl-1" style={{borderRadius:30}}>
                  <StyledText className='w-[33%] text-white text-left text-ellipsis align-middle text-md pl-[2px]' >{item.userName}</StyledText>
                  <StyledText className='w-[33%] text-white text-center text-ellipsis align-middle text-md pl-[2px]' >{item.tableQuantity.toString()}</StyledText> 
                  <>{console.log(item)}</>
                  <TouchableOpacity 
                      onPress={async () => {
                        if (item.checkedIn) {
                          await supabase.from('event_vendors').update({ checked_in: false }).eq('vendor_id', item.vendorId);
                          item.checkedIn = false;
                        } else {
                          await supabase.from('event_vendors').update({ checked_in: true }).eq('vendor_id', item.vendorId);
                          item.checkedIn = true;
                        }
                        setRefresh((prev) => prev + 1);
                      }}
                      activeOpacity={0.7}
                      style = {{
                        flex:1,
                        borderRadius: 30,
                        backgroundColor: !item.checkedIn ? "#73D08D" : "#535252",
                        width: 80,
                        height: 50,
                        marginLeft:15,
                        marginRight:4,
                        alignItems:"center",
                        justifyContent:"center"
                      }}
                      >
                      <StyledText style={{
                          color: !item.checkedIn ? "black": "white",
                          fontWeight: "bold",
                          fontSize: 16
                      }}>{!item.checkedIn ? "Check In" : "Checked In"}</StyledText>
                  </TouchableOpacity>
                  
                  
        
                </StyledView>
                </TouchableOpacity>
              </StyledView>
              
            }
            keyExtractor = {(item) => item.vendorId}
             />
            {selectedVendor && (
                <ParticipantModal
                visible={modalVisible}
                onClose={() => setModalVisible(false)}
                onCheckIn={() => {
                    setModalVisible(false);
                    // Perform check-in logic here if needed
                }}
                name={selectedVendor.userName}
                tables={selectedVendor.tableQuantity}
                section={selectedVendor.tableSection}
                contact={selectedVendor.phone ? selectedVendor.phone as string : selectedVendor.email as string}
                participantType='vendor'
                />
            )}
        </StyledSafeAreaView>
      
      
      
    )
  }
  
  export default vendors