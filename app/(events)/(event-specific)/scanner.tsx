import {
  Button,
  StyleSheet,
  Text,
  TouchableOpacity,
  TouchableWithoutFeedback,
  View,
  Image,
} from "react-native";
import { Camera, CameraView, useCameraPermissions } from "expo-camera";
import { SetStateAction, useEffect, useState } from "react";
import React from "react";
import { Ticket, supabase } from "@/lib/supabase";
import { router, useLocalSearchParams } from "expo-router";
import AttendeeModal from "@/components/scannerModal";
import Header from "@/components/header";
import { SafeAreaView } from "react-native-safe-area-context";
import { styled } from "nativewind";
import { isTodayValid, getToday } from "@/lib/helpers/CheckInFuncs";
import Toast from "react-native-toast-message";

const StyledView = styled(View);
const Scanner = () => {
  const { userID } = useLocalSearchParams();
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  const [scanData, setScanData] = useState("");
  const [ticket, setTicket] = useState<Ticket | null>(null);
  const [modalVisible, setModalVisible] = useState(false);
  const getCameraPermissions = async () => {
    const { status } = await Camera.requestCameraPermissionsAsync();
    setHasPermission(status === "granted");
  };

  useEffect(() => {
    getCameraPermissions();
  }, []);

  if (hasPermission == null) {
    // Camera permissions are still loading.
    return <View />;
  }

  if (!hasPermission) {
    // Camera permissions are not granted yet.
    return (
      <View style={styles.container}>
        <Text style={{ textAlign: "center" }}>
          We need your permission to show the camera
        </Text>
        <Button
          onPress={() => getCameraPermissions()}
          title="Grant Permission"
        />
      </View>
    );
  }
  function parseTicketId(url: string): string | null {
    try {
      const urlObj = new URL(url);

      // Check if the hostname ends with 'ontreasure.xyz'
      if (!urlObj.hostname.endsWith("ontreasure.com")) {
        console.error("Invalid hostname:", urlObj.hostname);
        return null;
      }

      const params = new URLSearchParams(urlObj.search);
      const ticketId = params.get("ticket_id");
      return ticketId;
    } catch (error) {
      console.error("Invalid URL:", error);
      return null;
    }
  }

  const handleScan = async ({ data }: { data: string }) => {
    if (data !== scanData && modalVisible === false) {
      setScanData(data);
      const ticketId = parseTicketId(data);
      if (ticketId != null) {
        try {
          const { data, error } = await supabase
            .from("event_tickets")
            .select(
              "profiles(first_name, last_name), event_tickets_dates(event_dates!inner(date), valid, event_dates_id, id)"
            )
            .eq("id", ticketId)
            .single();
          if (error) {
            console.error("Failed to fetch ticket:", error);
            setTicket(null);
            setModalVisible(true);
          } else {
            const tickets: Ticket = {
              userName: `${data.profiles?.first_name} ${data.profiles?.last_name}`,
              ticketId: ticketId,
              dates: data.event_tickets_dates.reduce(
                (
                  acc: { [date: string]: [boolean, string, string] },
                  dateItem: any
                ) => {
                  acc[dateItem.event_dates.date] = [
                    dateItem.valid,
                    dateItem.event_dates_id,
                    dateItem.id,
                  ];
                  return acc;
                },
                {} as { [date: string]: [boolean, string, string] }
              ),
            };
            console.log("Mapped ticket:", tickets);
            //if(userID === ticket.organizerId){
            setTicket(tickets);
            setModalVisible(true);
            //}
            /*else{
              setTicket(null)
              setModalVisible(true)
            }*/
          }
        } catch (err: any) {
          console.log(err);
        }
      }
    }
  };

  const today = new Date().toISOString().split("T")[0];
  return (
    <SafeAreaView
      style={{
        backgroundColor: "#0D0F0E",
        flex: 1,
      }}
    >
      <StyledView
        style={{
          height: "8%",
          flexDirection: "row",
          alignItems: "center",
          justifyContent: "space-between",
          paddingHorizontal: 20,
          paddingTop: 0,
        }}
      >
        <TouchableWithoutFeedback
          onPressIn={() => {
            router.back();
          }}
        >
          <StyledView
            className="align-top"
            style={{
              flexDirection: "row",
              alignItems: "center",
            }}
          >
            <Image source={require("../../../assets/images/back-btn.png")} />
          </StyledView>
        </TouchableWithoutFeedback>
        <StyledView
          className="align-top"
          style={{
            alignItems: "center",
          }}
        >
          <Image
            resizeMode="contain"
            source={require("../../../assets/images/emerald.png")}
            style={{
              width: 30,
              height: 30,
            }}
          />
        </StyledView>
      </StyledView>
      <CameraView
        style={styles.camera}
        onBarcodeScanned={handleScan}
        barcodeScannerSettings={{ barcodeTypes: ["qr"] }}
      >
        <Text
          style={{
            fontWeight: "bold",
            fontSize: 25,
            color: "white",
            textAlign: "center",
            marginTop: 10,
            textShadowColor: "black",
            shadowOffset: { width: 1, height: 1 },
          }}
        >
          Scan Tickets
        </Text>
        <View style={styles.scannerBoxContainer}>
          <View style={styles.scannerBox}>
            <View style={styles.scannerCornerTopLeft}></View>
            <View style={styles.scannerCornerTopRight}></View>
            <View style={styles.scannerCornerBottomLeft}></View>
            <View style={styles.scannerCornerBottomRight}></View>
          </View>
        </View>
        <AttendeeModal
          visible={modalVisible}
          onClose={function (): void {
            setModalVisible(false);
            setScanData("");
          }}
          onCheckIn={async () => {
            if (ticket?.dates && isTodayValid(ticket?.dates)) {
              await supabase
                .from("event_tickets_dates")
                .update({ valid: false })
                .eq("id", ticket.dates[today][2]);
              setModalVisible(false);
              Toast.show({
                type: "success",
                text1: "Checked In!",
                text2: ticket.userName + " is checked in",
                position: "bottom",
              });
            } else {
              setModalVisible(false);
            }
          }}
          name={ticket ? ticket?.userName : "Ticket Not Found"}
          isValid={ticket ? isTodayValid(ticket?.dates) : false}
        />
      </CameraView>
    </SafeAreaView>
  );
};
export default Scanner;
const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
  },
  camera: {
    flex: 1,
  },
  buttonContainer: {
    flex: 1,
    flexDirection: "row",
    backgroundColor: "transparent",
    margin: 64,
  },
  button: {
    flex: 1,
    alignSelf: "flex-end",
    alignItems: "center",
  },
  text: {
    fontSize: 24,
    fontWeight: "bold",
    color: "white",
  },
  scannerBoxContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  scannerBox: {
    width: 250,
    height: 250,
    borderWidth: 2,
    borderColor: "transparent",
    position: "relative",
  },
  scannerCornerTopLeft: {
    position: "absolute",
    top: -2,
    left: -2,
    width: 75,
    height: 75,
    borderTopWidth: 10,
    borderLeftWidth: 10,
    borderRadius: 10,
    borderColor: "#3CC13B",
  },
  scannerCornerTopRight: {
    position: "absolute",
    top: -2,
    right: -2,
    width: 75,
    height: 75,
    borderTopWidth: 10,
    borderRightWidth: 10,
    borderRadius: 10,
    borderColor: "#3CC13B",
  },
  scannerCornerBottomLeft: {
    position: "absolute",
    bottom: -2,
    left: -2,
    width: 75,
    height: 75,
    borderBottomWidth: 10,
    borderLeftWidth: 10,
    borderRadius: 10,
    borderColor: "#3CC13B",
  },
  scannerCornerBottomRight: {
    position: "absolute",
    bottom: -2,
    right: -2,
    width: 75,
    height: 75,
    borderBottomWidth: 10,
    borderRightWidth: 10,
    borderRadius: 10,
    borderColor: "#3CC13B",
  },
});
