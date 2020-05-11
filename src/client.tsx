import ReactDOM from 'react-dom'
import React from 'react'
import { App } from './features/App'

const initialStateElem = document.getElementById('initial-state')
initialStateElem.parentElement.removeChild(initialStateElem)
ReactDOM.hydrate(<App initialState={JSON.parse(initialStateElem.innerText)} />, document.getElementById('app'))
