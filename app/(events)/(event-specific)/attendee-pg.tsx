import {
  View,
  Text,
  SafeAreaView,
  FlatList,
  TouchableOpacity,
  TextInput,
  TouchableWithoutFeedback,
  Keyboard,
} from "react-native";
import Icon from "react-native-vector-icons/EvilIcons";
import React, { useCallback, useEffect, useState } from "react";
import { styled } from "nativewind";
import Header from "@/components/header";
import { DateValidityMap, Ticket, supabase } from "@/lib/supabase";
import { useLocalSearchParams } from "expo-router";
import Toast from "react-native-toast-message";
import ParticipantModal from "@/components/ParticipantModal";
import { formatPhoneNumber } from "@/components/formattedPhoneNumber";
import RefreshText, { TimeDisplay } from "@/components/Refresh-text";
import { getEventDates } from "@/lib/helpers/CheckInFuncs";

const StyledView = styled(View);
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);
const StyledTouchableOpacity = styled(TouchableOpacity);
const StyledTextInput = styled(TextInput);

type ticketsState = {
  data: Ticket[] | null;
  error: string | null;
};

const attendees = () => {
  const { eventID } = useLocalSearchParams();
  const [refresh, setRefresh] = useState(0);
  const [ticketsState, setticketsState] = useState<ticketsState>({
    data: null,
    error: null,
  });
  const [isCheckingIn, setIsCheckingIn] = useState<Record<string, boolean>>({});
  const [searchQuery, setSearchQuery] = useState("");
  const [filteredData, setFilteredData] = useState<Ticket[] | null>(null);
  const [modalVisible, setModalVisible] = useState(false);
  const [selectedTicket, setSelectedTicket] = useState<Ticket | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [updatedTime, setUpdatedTime] = useState("");
  const [checkedInCount, setCheckedInCount] = useState(0);
  const [selectedDate, setSelectedDate] = useState("");
  const [eventDates, setEventDates] = useState<string[]>([]);

  const fetchEventInfo = async () => {
    try {
      const dateInfo = (await getEventDates(eventID as string)).map(
        (date) => date.date
      );

      if (eventDates.length === 0) {
        setEventDates(dateInfo);
        setSelectedDate(dateInfo[0]);
      }

      setUpdatedTime(TimeDisplay);
      const { data, error } = await supabase
        .from("event_tickets")
        .select(
          'profiles(first_name, last_name, email, phone), tickets("name"), id, event_tickets_dates(event_dates!inner(date), valid, event_dates_id, id)'
        )
        .eq("event_id", eventID as string);

      if (error) {
        setticketsState({ data: null, error: error.message });
        console.log("Error fetching tickets:", error.message);
        return;
      }

      const tickets: Ticket[] = data.map((item) => ({
        userName: `${item.profiles?.first_name} ${item.profiles?.last_name}`,
        ticketType: item.tickets?.name as string,
        ticketId: item.id as string,
        email: item.profiles?.email,
        phone: item.profiles?.phone,
        dates: item.event_tickets_dates.reduce((acc, dateItem) => {
          acc[dateItem.event_dates.date] = [
            dateItem.valid,
            dateItem.event_dates_id,
            dateItem.id as string,
          ];
          return acc;
        }, {} as DateValidityMap),
      }));

      setticketsState({ data: tickets, error: null });
      if (selectedDate) {
        setFilteredData(tickets.filter((item) => item.dates[selectedDate]));
      }
    } catch (err: any) {
      setticketsState({ data: null, error: err.message });
      console.log("Error in fetchEventInfo:", err.message);
    }
  };

  const handleCheckIn = useCallback(
    async (item: Ticket) => {
      if (!selectedDate || !item.dates[selectedDate]) {
        Toast.show({
          type: "error",
          text1: "Invalid Date",
          text2: "No ticket information found for this date",
          position: "bottom",
        });
        return;
      }

      if (isCheckingIn[item.ticketId]) return;

      setIsCheckingIn((prev) => ({ ...prev, [item.ticketId]: true }));

      try {
        const newStatus = !item.dates[selectedDate][0];
        const { error } = await supabase
          .from("event_tickets_dates")
          .update({
            valid: newStatus,
            checked_in_at: new Date().toISOString(),
          })
          .eq("id", item.dates[selectedDate][2])
          .select();

        if (error) throw error;

        setticketsState((prevState) => ({
          ...prevState,
          data:
            prevState.data?.map((ticket) =>
              ticket.ticketId === item.ticketId
                ? {
                    ...ticket,
                    dates: {
                      ...ticket.dates,
                      [selectedDate]: [
                        newStatus,
                        ...ticket.dates[selectedDate].slice(1),
                      ],
                    },
                  }
                : ticket
            ) || null,
        }));

        setCheckedInCount((prev) => (newStatus ? prev - 1 : prev + 1));

        Toast.show({
          type: "success",
          text1: newStatus ? "Attendee Checked Out" : "Attendee Checked In",
          text2: `${item.userName} is ${
            newStatus ? "checked out" : "checked in"
          }`,
          position: "bottom",
          visibilityTime: 2000,
        });
      } catch (err) {
        console.error("Check-in error:", err);
        Toast.show({
          type: "error",
          text1: "Check-in Failed",
          text2: "Please try again",
          position: "bottom",
        });
      } finally {
        setIsCheckingIn((prev) => ({ ...prev, [item.ticketId]: false }));
      }
    },
    [selectedDate, isCheckingIn]
  );

  useEffect(() => {
    if (ticketsState.data && eventDates.length > 0) {
      setSelectedDate(eventDates[0]);
    }
  }, [eventDates]);

  useEffect(() => {
    fetchEventInfo();
  }, []);

  useEffect(() => {
    if (ticketsState.data && selectedDate) {
      const checkedIn = ticketsState.data.filter(
        (ticket) => ticket.dates[selectedDate] && !ticket.dates[selectedDate][0]
      ).length;
      setCheckedInCount(checkedIn);
    }
  }, [ticketsState.data, selectedDate]);

  useEffect(() => {
    if (!selectedDate) return;

    const filtered = ticketsState.data
      ?.filter((ticket) => {
        if (!ticket.dates[selectedDate]) return false;

        if (searchQuery) {
          return (
            ticket.userName.toLowerCase().includes(searchQuery.toLowerCase()) ||
            ticket.email?.toLowerCase().includes(searchQuery.toLowerCase()) ||
            ticket.phone?.toLowerCase().includes(searchQuery.toLowerCase())
          );
        }
        return true;
      })
      .filter((item) => item.dates[selectedDate]);

    setFilteredData(filtered || null);
  }, [searchQuery, ticketsState.data, selectedDate]);

  const renderItem = ({ item }: { item: Ticket }) => {
    if (!selectedDate || !item.dates[selectedDate]) return null;

    return (
      <StyledView
        className="flex flex-row w-full items-center justify-center"
        style={{ height: 75 }}
      >
        <TouchableOpacity
          onPress={() => {
            setSelectedTicket(item);
            setModalVisible(true);
          }}
          style={{ width: "100%" }}
        >
          <StyledView
            className="flex-row w-[99%] h-full bg-[#2A2424] items-center pl-1"
            style={{ borderRadius: 30 }}
          >
            <StyledText className="w-[33%] text-white text-left text-ellipsis align-middle text-md pl-4">
              {item.userName}
            </StyledText>
            <StyledText className="w-[33%] text-white text-center text-ellipsis align-middle text-md pl-[2px]">
              {item.ticketType}
            </StyledText>
            <TouchableOpacity
              onPress={() => handleCheckIn(item)}
              activeOpacity={0.7}
              style={{
                flex: 1,
                borderRadius: 30,
                backgroundColor: item.dates[selectedDate][0]
                  ? "#73D08D"
                  : "#535252",
                width: 80,
                height: 50,
                marginLeft: 15,
                marginRight: 4,
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <StyledText
                style={{
                  color: item.dates[selectedDate][0] ? "black" : "white",
                  fontWeight: "bold",
                  fontSize: 16,
                }}
              >
                {item.dates[selectedDate][0] ? "Check In" : "Checked In"}
              </StyledText>
            </TouchableOpacity>
          </StyledView>
        </TouchableOpacity>
      </StyledView>
    );
  };

  return (
    <StyledSafeAreaView
      className="flex-1"
      style={{
        backgroundColor: "#0D0F0E",
        flex: 1,
      }}
    >
      <Header backButton={true} />
      <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
        <StyledView className="justify-center w-full items-center px-4 mt-0">
          <StyledView className="flex-row w-[100%] justify-center">
            <StyledText className="text-[#73D08D] text-2xl font-bold mb-0 text-center">
              Attendees
            </StyledText>
            <StyledView className="justify-end self-end flex-1 absolute right-1">
              <StyledText className="text-white text-xs text-right">
                Checked In{"\n"}{" "}
                <StyledText className="text-[#73D08D] font-bold text-right">
                  {checkedInCount}
                </StyledText>
                /{ticketsState.data?.length || 0}
              </StyledText>
            </StyledView>
          </StyledView>
        </StyledView>
      </TouchableWithoutFeedback>

      <StyledView
        className="flex-row justify-center w-full px-2 mt-4 mb-4 items-center self-center"
        style={{
          borderRadius: 30,
          width: "98%",
          flexDirection: "row",
          backgroundColor: "#2A2424",
          height: 30,
        }}
      >
        <Icon name="search" size={30} color="#535252" />
        <StyledTextInput
          style={{
            flex: 1,
            height: 25,
            color: "white",
          }}
          placeholder="Search by name, email, or phone..."
          value={searchQuery}
          onChangeText={setSearchQuery}
        />
      </StyledView>

      <StyledView className="flex flex-row mx-3 justify-between">
        <FlatList
          horizontal={true}
          data={eventDates}
          scrollToOverflowEnabled={true}
          style={{ flexGrow: 1 }}
          onScrollBeginDrag={Keyboard.dismiss}
          keyExtractor={(item) => item}
          renderItem={({ item }) => (
            <StyledView
              style={{ flex: 1, flexDirection: "row", marginRight: 12 }}
            >
              <TouchableOpacity
                onPress={() => setSelectedDate(item)}
                activeOpacity={0.7}
                style={{
                  flex: 1,
                  borderRadius: 10,
                  backgroundColor:
                    item === selectedDate ? "#73D08D" : "#535252",
                  width: 70,
                  height: 40,
                  alignItems: "center",
                  justifyContent: "center",
                  padding: 0,
                }}
              >
                <StyledText
                  style={{
                    color: item === selectedDate ? "black" : "white",
                    fontWeight: "bold",
                    fontSize: 16,
                  }}
                >
                  {new Date(item).toLocaleDateString(undefined, {
                    day: "numeric",
                    month: "short",
                    timeZone: "UTC",
                  })}
                </StyledText>
              </TouchableOpacity>
            </StyledView>
          )}
        />
        <RefreshText time={updatedTime} />
      </StyledView>

      <StyledView className="flex flex-row mt-4 w-full px-8 mb-1">
        <StyledText className="w-[33%] font-bold text-white text-sm">
          Name
        </StyledText>
        <StyledText className="w-[33%] font-bold text-white text-sm text-center">
          Ticket Type
        </StyledText>
        <StyledText className="w-[33%] font-bold text-white text-sm text-right pr-2">
          Status
        </StyledText>
      </StyledView>

      <FlatList
        data={filteredData || []}
        renderItem={renderItem}
        refreshing={isRefreshing}
        style={{ minWidth: "100%" }}
        onRefresh={async () => {
          setIsRefreshing(true);
          await fetchEventInfo();
          setIsRefreshing(false);
        }}
        keyExtractor={(item) => item.ticketId}
      />

      {selectedTicket && selectedDate && (
        <ParticipantModal
          visible={modalVisible}
          onClose={() => setModalVisible(false)}
          onCheckIn={async () => {
            if (!selectedTicket.dates[selectedDate]) {
              Toast.show({
                type: "error",
                text1: "Date Entry Missing",
                text2: "No entry found for the selected date.",
                position: "bottom",
                visibilityTime: 2000,
              });
              return;
            }

            const newStatus = !selectedTicket.dates[selectedDate][0];
            try {
              await supabase
                .from("event_tickets_dates")
                .update({ valid: newStatus })
                .eq("id", selectedTicket.dates[selectedDate][2]);

              selectedTicket.dates[selectedDate][0] = newStatus;
              setCheckedInCount((prev) => (newStatus ? prev - 1 : prev + 1));

              Toast.show({
                type: "success",
                text1: newStatus
                  ? "Attendee Was Checked Out"
                  : "Attendee Was Checked In",
                text2: `${selectedTicket.userName} is ${
                  newStatus ? "checked out" : "checked in"
                }`,
                position: "bottom",
                visibilityTime: 2000,
              });

              setRefresh((prev) => prev + 1);
            } catch (error) {
              console.error("Error updating check-in status:", error);
              Toast.show({
                type: "error",
                text1: "Update Failed",
                text2: "Failed to update check-in status",
                position: "bottom",
                visibilityTime: 2000,
              });
            }
          }}
          name={selectedTicket.userName}
          contact={
            selectedTicket.phone
              ? formatPhoneNumber(selectedTicket.phone.substring(2))
              : selectedTicket.email || "No contact information"
          }
          checkedIn={
            selectedTicket.dates[selectedDate]
              ? !selectedTicket.dates[selectedDate][0]
              : false
          }
          participantType="attendee"
        />
      )}
    </StyledSafeAreaView>
  );
};

export default attendees;
