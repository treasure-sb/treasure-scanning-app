import { StatusBar } from "expo-status-bar";
import { Text, View, Image, ScrollView } from "react-native";
import { withExpoSnack, styled } from "nativewind";
import { Link, Redirect, router } from 'expo-router';
import  CustomButton  from "@/components/CustomButton";
import { SafeAreaView } from "react-native-safe-area-context";


const StyledView = styled(View)
const StyledSafeAreaView = styled(SafeAreaView)
const StyledText = styled(Text)
const StyledImage = styled(Image)
const StyledScrollView = styled(ScrollView)


export default function App() {
    return(
        <StyledSafeAreaView className="flex-1 items-center justify-center" style={{
            backgroundColor: "#0D0F0E"
        }}>
            <StyledView className="w-full h-full pt-64 items-center" >
                <StyledImage className="align-bottom w-full h-[100px] "  resizeMode = 'contain' source={require('../assets/images/web_logo.png')} />
                <StyledText className = "text-white text pt-1 text-base font-semibold">For Hosts</StyledText>
                <StatusBar style="auto" />
                <Link href="/scanner" style = {{color: 'green'}}> Go to Scanner </Link>
                <StyledView className="w-full h-full items-center pt-32"><CustomButton title = "Log In" handlePress={() => router.push('/sign-in')} /></StyledView>
                <StatusBar backgroundColor="#161622" style="light" />
            </StyledView>
            
        </StyledSafeAreaView>
    );
}


