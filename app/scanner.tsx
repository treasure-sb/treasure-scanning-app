import { Button, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { Camera, CameraView, useCameraPermissions } from 'expo-camera'
import { SetStateAction, useEffect, useState } from 'react'
import React from 'react'

const Scanner = () => {
    const [hasPermission, setHasPermission] = useState<boolean | null>(null);
    const [scanData, setScanData] = useState("");
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
          <Text style={{ textAlign: 'center' }}>We need your permission to show the camera</Text>
          <Button onPress={() => getCameraPermissions()} title="Grant Permission" />
        </View>
      );
    }
  
    const handleScan = ({ data }: { data: string }) => {
      if (data !== scanData){
        setScanData(data);
      }
      
    }
    console.log(scanData)
    return (
      <View style={styles.container}>
        <CameraView
          style={styles.camera}
          onBarcodeScanned={handleScan}
          barcodeScannerSettings={{barcodeTypes: ['qr']}}
          >
          <View style={styles.buttonContainer}>
            <TouchableOpacity style={styles.button}>
              <Text style={styles.text}>This Does Nothing Could Be a Tap to Scan Again</Text>
            </TouchableOpacity>
          </View>
        </CameraView>
      </View>
    );
  }
  export default Scanner
  const styles = StyleSheet.create({
    container: {
      flex: 1,
      justifyContent: 'center',
    },
    camera: {
      flex: 1,
    },
    buttonContainer: {
      flex: 1,
      flexDirection: 'row',
      backgroundColor: 'transparent',
      margin: 64,
    },
    button: {
      flex: 1,
      alignSelf: 'flex-end',
      alignItems: 'center',
    },
    text: {
      fontSize: 24,
      fontWeight: 'bold',
      color: 'white',
    },
  });


