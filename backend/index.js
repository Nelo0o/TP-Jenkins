const express = require('express')
const app = express()
const port = 5000

app.get('/', (req, res) => {
  res.send('Wassuuuuuuuuuuuuuuuup')
})

app.get('/users-list', (req, res) => {
  res.send({
    users: [
      {
        id: 1,
        name: 'John Doe',
        email: 'john.doe@example.com',
      },
      {
        id: 2,
        name: 'Jane Doe',
        email: 'jane.doe@example.com',
      },
      {
        id: 3,
        name: 'John Daube',
        email: 'john.daube@example.com',
      },
    ],
  })
})

app.listen(port, () => {
  console.log(`ça tourne sur le port ${port}`)
})