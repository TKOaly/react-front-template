import express from 'express'
import React from 'react'
import ReactServer from 'react-dom/server'
import { createTemplate } from './basePage'
import { App } from '../features/App'
import { getTimetables } from '../services/hslService'

const PORT = process.env.PORT || 3000
const server = express()

server.use(express.static('dist'))

server.get('/', async (req, res) => {
  const initialState = {
    timetables: await getTimetables()
  }
  const body = ReactServer.renderToString(<App initialState={initialState} />)
  res.send(createTemplate({
    title: 'Babbys first web app',
    body,
    initialState: JSON.stringify(initialState)
  }))
})

// Needed for CORS
server.get(
  '/api/timetables', (req, res) =>
    getTimetables()
      .then(t => res.json(t))
)

server.listen(PORT, () => console.log('🍺 Listening on port', PORT))
