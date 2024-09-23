import { DateValidityMap, Ticket } from "@/lib/supabase";
import { supabase } from '@/lib/supabase'
import { Tables } from "@/types/supabase";


function getToday(dateValidityMap: DateValidityMap): [boolean, string, string] {
  const today = new Date().toISOString().split("T")[0];
  return dateValidityMap[today];
}

function getTicketByDate(dateValidityMap : DateValidityMap, date: string) : [boolean, string, string] {
  return dateValidityMap[date];
}

function isTodayValid(dateValidityMap: DateValidityMap): boolean {
  // Get today's date in YYYY-MM-DD format
  const today = new Date().toISOString().split("T")[0];
  // Check if today's date is in the map and is valid
  if (!dateValidityMap[today]) return true
  return dateValidityMap[today][0];
  
}

async function getEventDates(eventId: string): Promise<Tables<"event_dates">[]> {
  const { data, error } = await supabase
                  .from('event_dates')
                  .select('*')
                  .eq('event_id', eventId)
                  .order("date", {ascending: true})
  if (error) throw error;
  return data;
}
export { getToday, isTodayValid, getEventDates, getTicketByDate};
