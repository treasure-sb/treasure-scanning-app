import {
  View,
  Text,
  SafeAreaView,
  TouchableWithoutFeedback,
  Keyboard,
} from "react-native";
import React, { useEffect, useState } from "react";
import { styled } from "nativewind";
import FormField from "@/components/FormField";
import CustomButton from "@/components/CustomButton";
import { supabase, handleInfoSubmit } from "@/lib/supabase";
import { router, useLocalSearchParams, useNavigation } from "expo-router";
import Toast from "react-native-toast-message";
import Header from "@/components/header";
const StyledView = styled(View);
const StyledSafeAreaView = styled(SafeAreaView);
const StyledText = styled(Text);

const SignIn = () => {
  const navigation = useNavigation();

  useEffect(() => {
    navigation.setOptions({ headerShown: false });
  }, [navigation]);
  const [form, setForm] = useState({
    phoneNum: "",
    email: "",
  });

  const handleChangeText = (text: string) => {
    useEmail
      ? setForm({ ...form, email: text })
      : setForm({ ...form, phoneNum: text });
    setEmailVerify(false);
    setPhoneVerify(false);
    setPrintBadFormat(false);
    if (/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(text)) {
      setEmailVerify(true);
    }
    if (/^\d{10}$/.test(text)) {
      setPhoneVerify(true);
    }
  };

  const [useEmail, setUseEmail] = useState(false);

  const handleChangeInputType = () => {
    setUseEmail((prev) => !prev);
  };

  const [emailVerify, setEmailVerify] = useState(false);
  const [phoneVerify, setPhoneVerify] = useState(false);
  const [printBadFormat, setPrintBadFormat] = useState(false);
  const [badFormatString, setBadFormatString] = useState("");
  const [accountExists, setAccountExists] = useState(true);
  const params = useLocalSearchParams();

  return (
    <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
      <StyledSafeAreaView
        className="flex-1"
        style={{
          backgroundColor: "#0D0F0E",
        }}
      >
        <Header />
        <StyledView className="w-full items-center px-4 mt-6 mb-4">
          <StyledText className="text-white text-2xl font-bold mb-12">
            Welcome to Treasure
          </StyledText>
        </StyledView>

        <StyledView className="flex-1 w-full">
          <FormField
            title="Phone Number"
            value={useEmail ? form.email : form.phoneNum}
            placeholder={useEmail ? "Email Address" : "Phone Number"}
            placeholderTextColor="#535252"
            keyboardType={useEmail ? "email-address" : "numeric"}
            handleChangeText={handleChangeText}
          />
          <StyledText
            className="text-gray-400 mt-1 relative pl-[25%] pt-[0.3%] text-sm mb-12"
            onPress={handleChangeInputType}
          >
            {useEmail ? "Use phone number instead" : "Use email instead"}
          </StyledText>
          <StyledView style={{ alignItems: "center" }}>
            <CustomButton
              title="Continue"
              handlePress={async () => {
                if (useEmail) {
                  if (!emailVerify) {
                    setBadFormatString(
                      "Email has incorrect format... ex: email@company.com"
                    );
                    setPrintBadFormat(true);
                  } else {
                    const infoSubmit = handleInfoSubmit(form.email, useEmail);
                    const doesAccountExist = await infoSubmit.then((res) => {
                      return res?.error ? true : false;
                    });
                    console.log(doesAccountExist);
                    if (doesAccountExist) {
                      setAccountExists(false);
                      Toast.show({
                        type: "error",
                        position: "bottom",
                        text1: "Account does not exist",
                        text2: "Please sign up online or try again",
                      });
                      return;
                    }
                    router.push({
                      pathname: "./otp-code",
                      params: { info: form.email, type: "email" },
                    });
                  }
                }
                if (!useEmail) {
                  if (!phoneVerify) {
                    setBadFormatString(
                      "Phone number has incorrect format.. ex: 5555555555"
                    );
                    setPrintBadFormat(true);
                  } else {
                    const infoSubmit = handleInfoSubmit(
                      form.phoneNum,
                      useEmail
                    );
                    const doesAccountExist = await infoSubmit.then((res) => {
                      console.log("res", res?.error);
                      return res?.error ? true : false;
                    });
                    console.log("doesAccount", doesAccountExist);
                    if (doesAccountExist) {
                      setAccountExists(false);
                      Toast.show({
                        type: "error",
                        position: "bottom",
                        text1: "Account does not exist",
                        text2: "Please try again",
                      });
                      return;
                    }
                    router.push({
                      pathname: "./otp-code",
                      params: { info: form.phoneNum, type: "phone" },
                    });
                  }
                }
              }}
            />
            <StyledText className="text-red-600 text-sm pt-6">
              {printBadFormat ? badFormatString : null}{" "}
            </StyledText>
          </StyledView>
        </StyledView>
      </StyledSafeAreaView>
    </TouchableWithoutFeedback>
  );
};

export default SignIn;
