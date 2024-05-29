import { AppState } from 'react-native'
import 'react-native-url-polyfill/auto'
import AsyncStorage from '@react-native-async-storage/async-storage'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://qkdlfshzugzeqlznyqfv.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFrZGxmc2h6dWd6ZXFsem55cWZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDAwMDA3MzYsImV4cCI6MjAxNTU3NjczNn0.TmjUj-7otNZgLWMWqYKV4x49mQlq41HqmwuJFgpfU6I'

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
})
