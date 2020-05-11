import React from 'react'
import { Timetable } from '../services/hslService'
import { TimetableComponent } from './Timetable'

interface Props {
  initialState: {
    timetables: Timetable[]
  }
}

export const App = ({ initialState }: Props) =>
  <div className="app-wrapper">
    <img className="logo" src="/assets/img/logo.svg" />
    <h1 className="title">
      Hello world.
    </h1>
    <TimetableComponent timetable={initialState.timetables} />
  </div>