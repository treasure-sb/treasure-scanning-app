import React from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet } from 'react-native';

type Props = {
  visible: boolean;
  onClose: () => void;
  onCheckIn: () => void;
  participantType: string, //vendor or attendee
  name: string;
  tables: Number;
  section: string;
  contact: string;
};

const ParticipantModal: React.FC<Props> = ({ visible, onClose, onCheckIn, name, tables, section, contact, participantType }) => {
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
          <Text style={styles.infoText}>Tables: {tables as any as string}</Text>
          <Text style={styles.infoText}>Section: {section}</Text>
          <Text style={styles.infoText}>Contact: {contact}</Text>
          <TouchableOpacity style={styles.checkInButton} onPress={onCheckIn}>
            <Text style={styles.checkInButtonText}>Check In</Text>
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
    padding: 5,
  },
  closeButtonText: {
    color: '#ffffff',
    fontSize: 25,
  },
  nameText: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#ffffff',
    marginBottom: 10,
  },
  infoText: {
    fontSize: 18,
    color: '#cccccc',
    marginBottom: 10,
  },
  checkInButton: {
    backgroundColor: '#73D08D',
    borderRadius: 30,
    paddingVertical: 12,
    paddingHorizontal: 40,
    marginTop: 20,
    marginBottom:15
  },
  checkInButtonText: {
    color: '#000000',
    fontWeight: 'bold',
    fontSize: 18,
  },
});

export default ParticipantModal;
