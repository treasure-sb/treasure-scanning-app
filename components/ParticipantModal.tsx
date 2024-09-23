import React from "react";
import { Modal, View, Text, TouchableOpacity, StyleSheet } from "react-native";

type Props = {
  visible: boolean;
  onClose: () => void;
  onCheckIn: () => void;
  participantType: string; //vendor or attendee
  name: string;
  tables?: Number;
  section?: string;
  contact: string;
  checkedIn: boolean;
};

const ParticipantModal: React.FC<Props> = ({
  visible,
  onClose,
  onCheckIn,
  name,
  tables,
  section,
  contact,
  participantType,
  checkedIn,
}) => {
  const onClickFunc = () => {
    onCheckIn();
    checkedIn = !checkedIn;
  };
  return (
    <Modal
      animationType="slide"
      transparent={true}
      visible={visible}
      onRequestClose={onClose}
    >
      <View style={styles.overlay}>
        <View style={styles.modalContainer}>
          <TouchableOpacity style={styles.closeButton} onPress={onClose}>
            <Text style={styles.closeButtonText}>✕</Text>
          </TouchableOpacity>
          <Text style={styles.nameText}>{name}</Text>
          {participantType === "vendor" && (
            <>
              <View style={styles.textRowView}>
                <View style={styles.leftTextView}>
                  <Text style={styles.leftText}>Tables: </Text>
                </View>
                <View style={styles.rightTextView}>
                  <Text style={styles.infoText}>{tables as any as string}</Text>
                </View>
              </View>
              <View style={styles.textRowView}>
                <View style={styles.leftTextView}>
                  <Text style={styles.leftText}>Section: </Text>
                </View>
                <View style={styles.rightTextView}>
                  <Text style={styles.infoText}>{section}</Text>
                </View>
              </View>
            </>
          )}
          <View
            style={{
              alignContent: "center",
              justifyContent: "center",
              alignSelf: "center",
            }}
          >
            <Text
              style={{
                color: "white",
                textAlign: "center",
                fontWeight: "bold",
                fontSize: 17,
              }}
            >
              Contact:{" "}
            </Text>
          </View>
          <Text style={styles.infoText} selectable={true}>
            {contact}
          </Text>
          <TouchableOpacity
            style={{
              backgroundColor: !checkedIn ? "#73D08D" : "#535252",
              borderRadius: 30,
              width: 150,
              height: 55,
              marginTop: 20,
              marginBottom: 15,
              alignContent: "center",
              justifyContent: "center",
            }}
            onPress={onClickFunc}
          >
            <Text
              style={{
                color: !checkedIn ? "black" : "white",
                fontWeight: "bold",
                fontSize: 18,
                textAlign: "center",
              }}
            >
              {checkedIn ? "Checked In" : "Check In"}
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "rgba(0, 0, 0, 0.5)",
  },
  modalContainer: {
    width: "75%",
    backgroundColor: "#0D0F0E",
    borderRadius: 70,
    borderWidth: 1,
    borderColor: "#3F4743",
    padding: 20,
    alignItems: "center",
    position: "relative",
    marginTop: 0,
  },
  closeButton: {
    position: "absolute",
    top: 15,
    right: 25,
    padding: 5,
  },
  closeButtonText: {
    color: "#ffffff",
    fontSize: 25,
  },
  nameText: {
    fontSize: 20,
    fontWeight: "700",
    color: "#ffffff",
    marginBottom: 30,
    marginRight: 8,
  },
  textRowView: {
    width: "100%",
    flexDirection: "row",
    alignContent: "flex-start",
  },
  leftTextView: {
    width: "28%",
    marginLeft: 15,
  },
  leftText: {
    color: "white",
    fontSize: 17,
    fontWeight: "600",
  },
  rightTextView: {
    width: "75%",
    paddingLeft: 30,
  },
  infoText: {
    fontSize: 17,
    color: "white",
    fontWeight: "300",
    marginBottom: 20,
    textAlign: "center",
  },
  checkInButton: {
    backgroundColor: "#73D08D",
    borderRadius: 30,
    paddingVertical: 12,
    paddingHorizontal: 40,
    marginTop: 20,
    marginBottom: 15,
  },
});

export default ParticipantModal;
