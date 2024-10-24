import { StatusBar } from "expo-status-bar";
import { Text, View, Image, ScrollView, Button } from "react-native";
import { withExpoSnack, styled } from "nativewind";
import { Redirect, router, useLocalSearchParams } from "expo-router";
import CustomButton from "@/components/CustomButton";
import { SafeAreaView } from "react-native-safe-area-context";
import { supabase } from "@/lib/supabase";
import { useEffect, useState } from "react";
import { set } from "date-fns";

const StyledView = styled(View);
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);
const StyledImage = styled(Image);

export default function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [userID, setUserID] = useState<string | null>(null);
  useEffect(() => {
    async function checkUser() {
      const { data, error } = await supabase.auth.getSession();
      if (data.session !== null) {
        console.log(data);
        setUserID(data.session.user.id);
        setIsLoggedIn(true);
        console.log(data.session.user.id);
      }
    }
    checkUser();
  }, []);
  useEffect(() => {
    if (isLoggedIn && userID) {
      router.push({
        pathname: "../(events)/my-events",
        params: { userID: userID },
      });
    }
  }, [isLoggedIn, userID]);
  return (
    <StyledSafeAreaView
      className="flex-1 items-center justify-center"
      style={{
        backgroundColor: "#0D0F0E",
      }}
    >
      <StyledView className="w-full h-full pt-64 items-center">
        <StyledImage
          className="align-bottom h-[100px] w-[85%] mr-4"
          resizeMode="contain"
          source={require("../assets/images/web_logo.png")}
        />
        <StyledText className="text-white text text-base font-semibold mb-32">
          For Hosts
        </StyledText>
        <CustomButton
          title="Log In"
          handlePress={() => router.push("./sign-in")}
        />
      </StyledView>
      <StatusBar backgroundColor="#161622" style="light" />
    </StyledSafeAreaView>
  );
}
