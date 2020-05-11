import React, { useEffect, useRef, useState } from 'react'
import axios from 'axios'
import { Timetable } from '../services/hslService'

export const TimetableComponent = (props: { timetable: Timetable[] }) => {
  const [timetable, setTimetables] = useState(props.timetable)

  useInterval(() => {
    axios.get('/api/timetables')
      .then(({ data }) => data)
      .then(setTimetables)
  }, 20000)

  return (
    <div>
      <h3>Pasilan asema (updates every 20sec)</h3>
      <tbody>
        {timetable.map(t => (
          <tr>
            <td>{t.headsign}</td>
            <td>{t.realtimeArrival}</td>
          </tr>
        ))}
      </tbody>
    </div>
  )
}

function useInterval(callback: () => void, delay: number) {
  const savedCallback: any = useRef();

  useEffect(() => {
    savedCallback.current = callback;
  }, [callback]);

  useEffect(() => {
    function tick() {
      savedCallback.current();
    }
    if (delay !== null) {
      let id = setInterval(tick, delay);
      return () => clearInterval(id);
    }
  }, [delay]);
}
