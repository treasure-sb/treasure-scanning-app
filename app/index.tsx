import { StatusBar } from "expo-status-bar";
import { Text, View } from "react-native";
import { withExpoSnack, styled } from "nativewind";
import {Link } from 'expo-router';
const StyledView = styled(View)
const StyledText = styled(Text)


export default function App() {
    return(
        <StyledView className="flex-1 items-center justify-center bg">
            <StyledText className = "text-3xl">QR Code Scanner</StyledText>
            <StatusBar style="auto" />
            <Link href="/scanner" style = {{color: 'blue'}}> Go to Scanner </Link>
        </StyledView>
    );
}


