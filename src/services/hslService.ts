import axios from 'axios'

export interface Timetable {
  realtimeArrival: number,
  headsign: string
}

const API_URL = 'https://api.digitransit.fi/routing/v1/routers/hsl/index/graphql'

const QUERY = `
{
  stop(id: "HSL:1173148") {
    name
      stoptimesWithoutPatterns {
      scheduledArrival
      realtimeArrival
      arrivalDelay
      scheduledDeparture
      realtimeDeparture
      departureDelay
      realtime
      realtimeState
      serviceDay
      headsign
    }
  }  
}`

export const getTimetables = () =>
  axios.post(API_URL, { query: QUERY, variables: null }, { headers: { 'Content-Type': 'application/json'} })
    .then(({ data }) => data)
    .then(parseData)

export const parseData = ({ data }: any): Timetable[] =>
  data.stop.stoptimesWithoutPatterns
    .map(({realtimeArrival, headsign }: any) => ({
      realtimeArrival,
      headsign
    }))