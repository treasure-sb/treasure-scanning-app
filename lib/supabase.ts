import { AppState } from 'react-native'
import 'react-native-url-polyfill/auto'
import AsyncStorage from '@react-native-async-storage/async-storage'
import { createClient } from '@supabase/supabase-js'
import { Database } from '@/types/supabase'

const supabaseUrl = 'https://qkdlfshzugzeqlznyqfv.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFrZGxmc2h6dWd6ZXFsem55cWZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDAwMDA3MzYsImV4cCI6MjAxNTU3NjczNn0.TmjUj-7otNZgLWMWqYKV4x49mQlq41HqmwuJFgpfU6I'
export const userID = async() =>{
  return (await supabase.auth.getUser()).data.user?.id
}
export const handleInfoSubmit = async(userInfo: string, useEmail: boolean) =>{
  let sendMsgData
  if(useEmail){sendMsgData = await supabase.auth.signInWithOtp({
    email:userInfo
  })}
  else{
    const formattedPhoneNumber = `+1${userInfo}`
    sendMsgData = await supabase.auth.signInWithOtp({
    phone:formattedPhoneNumber
    })
  }}
export const verifyMessageData = async(info: any, code:string, type : any) => {
  let verificationResult
  if(type === "email"){
    verificationResult = await supabase.auth.verifyOtp({
          email: `${info}`,
          token: code,
          type: 'email',
      })
  }
  else {
    verificationResult = await supabase.auth.verifyOtp({
          phone: `+1${info}`,
          token: code,
          type: 'sms',
      })
  }
  const {data: verificationData, error:verificationError} = verificationResult
  return verificationData
}

export type Ticket = {
  userName: string;
  ticketType?: string;
  ticketId: string,
  email?: string | null | undefined,
  phone?: string | null | undefined,
  organizerId? : string,
  isValid: boolean
};
export type Vendor = {
  userName: string;
  tableId: string;
  tableQuantity: Number,
  tableSection: string,
  vendorId: string,
  email?: string | null | undefined,
  phone?: string | null | undefined,
  organizerId? : string,
  checkedIn: boolean,
  vendorsAtTable: Number
};

export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
})
