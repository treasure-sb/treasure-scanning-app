import { View, Text, Image } from 'react-native'
import React from 'react'
import { styled } from 'nativewind';
const StyledView = styled(View);
const StyledText = styled(Text);

export type Props = {
    time: string
}
const RefreshText: React.FC<Props> = ({ time }) => {
  return (
    <StyledView className='w-full h-19 justify-top text-right mb-6'>
        <StyledView className='flex-row-reverse flex-shrink w-full text-right items-center justify-start'>
            <Image source={require('../assets/images/refresh-icon.png')} style={{marginLeft:4, alignItems:"flex-start", height:15, width: 15}} resizeMode='contain'/>
            <StyledText className='text-right text-sm' style={{color:"#6A6A6A"}}>Pull down to refresh</StyledText>
        </StyledView>
        <StyledText className='text-right text-xs'style={{color:"#535252"}}>Last updated at {time}</StyledText>
    </StyledView>
  )
}
export const TimeDisplay = () => {
  const currentDate = new Date()
  let hours = currentDate.getHours()
  let minutes = currentDate.getMinutes()
  
  let period = hours >= 12 ? 'pm' : 'am'
  hours = hours % 12 || 12
  let minutesStr = minutes < 10 ? '0' + minutes.toString() : minutes.toString()

  return `${hours}:${minutesStr}${period}`}

export default RefreshText
