const express = require('express')
const morgan = require('morgan')
const axios = require('axios')

const app = express();
app.use(morgan('tiny'))
app.use(express.json())

// ENV
const port = process.env.PORT || 8080;
const backendUrl = process.env.BACKEND_URL
const labels = process.env.LABELS

app.get('/', async (req, res) => {
  return res.status(200)
})

app.post('/', async (req, res) => {
  if (req.header('X-GitHub-Event') === "workflow_job" && req.body.action === "queued" ) {
    const _labels = labels.split(',')
    // 厳密には少し誤った条件だが、ジョブのラベル指定のいずれかがLABELSに一致していたらバックエンドに流す
    if (_labels.some((label) => req.body.workflow_job.labels.includes(label))) {
      console.log(`Filterd webhook: name: ${req.body.workflow_job.name}, labels: ${req.body.workflow_job.labels}`)
      console.log(`POST to backendUrl: ${backendUrl}`)
      await axios({
        method: 'POST',
        url: backendUrl,
        body: req.body
      }).then((_res) => console.log("Finish dispatch webhook to backend"))
      return res.status(200).json({})
    }
  }

  return res.status(200).json({})
});

app.listen(port, () => {
  console.log(`listening on port ${port}`);
});
