import React from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet } from 'react-native';

type Props = {
  visible: boolean;
  onClose: () => void;
  onCheckIn: () => void;
  name: string;
  isValid: boolean
};

const AttendeeModal: React.FC<Props> = ({ visible, onClose, onCheckIn, name, isValid }) => {
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
          <Text style={{
            fontSize: 24,
            fontWeight: 'bold',
            color: isValid ? '#73D08D' : "red",
            marginTop: 20,
            marginBottom:15
          }}>
            {isValid ?"Ticket Found!" : " Oops :/"}
          </Text>
          <Text style={styles.subText}>{isValid ? "This ticket is for:" : "Looks like this ticket was already scanned"}</Text>
          <Text style={styles.nameText}>{name}</Text>
          <TouchableOpacity style={styles.checkInButton} onPress={onCheckIn}>
            <Text style={styles.checkInButtonText}>{isValid ? "Check In" : "Try Again"}</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  modalContainer: {
    width: '75%',
    backgroundColor: '#1D1D1D',
    borderRadius: 70,
    padding: 20,
    alignItems: 'center',
    position: 'relative',
    marginTop: 0
  },
  closeButton: {
    position: 'absolute',
    top: 15,
    right: 25,
    padding: 5
  },
  closeButtonText: {
    color: '#ffffff',
    fontSize: 25,
  },
  subText: {
    fontSize: 14,
    color: '#cccccc',
    marginBottom: 30
  },
  nameText: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#ffffff',
    marginBottom: 20,
  },
  checkInButton: {
    backgroundColor: '#73D08D',
    borderRadius: 30,
    paddingVertical: 12,
    paddingHorizontal: 40,
    marginTop:20,
    marginBottom:15

  },
  checkInButtonText: {
    color: '#000000',
    fontWeight: 'bold',
    fontSize: 18,
  },
});

export default AttendeeModal;
