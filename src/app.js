const http = require('http');

const port = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/plain');
    res.end('OK');
  } else {
    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/html');
    res.end('Hello World! This is a simple web application deployed with Kubernetes on AWS.');
  }
});

server.listen(port, () => {
  console.log(`Server running at http://localhost:${port}/`);
});
