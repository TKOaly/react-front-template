export const createTemplate = ({title, body, initialState}: {title: string, body: string, initialState: string}) => {
  return `
  <!DOCTYPE html>
  <html>
    <div style="display: none" id="initial-state">${initialState}</div>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <link rel="stylesheet" href="/css/main.css"></link>
      <title>${title}</title>
    </head>
    <body style="margin:0">
      <div id="app">${body}</div>
    </body>
    <script src="/js/client.js" defer></script>
  </html>
  `
}
