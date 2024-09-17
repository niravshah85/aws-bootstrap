const { hostname } = require("os");
const http = require("http");
const https = require("https");
const fs = require("fs");

const STACK_NAME = process.env.STACK_NAME || "Unknown Stack";
const port = 8080;
const httpsport = 8443;
const httpsKey = "../keys/key.pm";
const httpsCert = "../keys/cert.pem";

if (fs.existsSync(httpsKey) && fs.existsSync(httpsCert)) {

    console.log("Starting https server");

    const message = `Hello HTTPS world from ${hostname()} in ${STACK_NAME}\n`;
    
    const options = {
        key: fs.readFileSync(httpsKey),
        cert: fs.readFileSync(httpsCert)
    }
    
    const server = https.createServer(options, (req, res) => {
        res.statusCode = 200;
        res.setHeader("Content-Type", "text/plain");
        res.end(message);
    });

    server.listen(httpsport, hostname, () => {
        console.log(`server running at http://${hostname()}:${httpsport}/`)
    });
}

console.log("Starting https server");
const message = `Hello world from ${hostname()} in ${STACK_NAME}\n`;
const server = http.createServer((req, res) => {
    res.statusCode = 200;
    res.setHeader("Content-Type", "text/plain");
    res.end(message);
});

server.listen(port, hostname, () => {
    console.log(`server running at http://${hostname()}:${port}/`)
});
