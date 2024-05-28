import { StatusBar } from "expo-status-bar";
import { getBackgroundColorAsync } from "expo-system-ui";
import { StyleSheet, Text, View } from "react-native";


export default function App() {
    return(
        <View style={styles.container}>
            <Text>QR Code Scanner</Text>
            <StatusBar backgroundColor="#161622" style='light'/>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#fff',
        alignItems: 'center',
        justifyContent:'center',
    }
});