import { getBackgroundColorAsync } from "expo-system-ui";
import { StatusBar, StyleSheet, Text, View } from "react-native-web";

export default function App() {
    return(
        <View style={styles.container}>
            <Text>QR Code Scanner</Text>
            <StatusBar style="auto" />
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        getBackgroundColor: '#fff',
        alignItems: 'center',
        justifyContent:'center',
    }
});