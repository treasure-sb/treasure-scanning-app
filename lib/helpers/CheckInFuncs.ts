import { DateValidityMap, Ticket } from "@/lib/supabase";
import { supabase } from '@/lib/supabase'
import { Tables } from "@/types/supabase";


function getToday(dateValidityMap: DateValidityMap): [boolean, string, string] | null {
  const today = new Date().toISOString().split("T")[0];
  return dateValidityMap[today] || null; // Return null if today is not in the map
}


function getTicketByDate(dateValidityMap : DateValidityMap, date: string) : [boolean, string, string] {
  return dateValidityMap[date];
}

function isTodayValid(dateValidityMap: DateValidityMap): boolean {
  const today = new Date().toISOString().split("T")[0];
  // Return false if today's date is not in the map
  if (!dateValidityMap[today]) return true;
  // Otherwise, return whether the ticket is valid
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
