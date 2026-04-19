import http from 'http';

const req = http.request(
  'http://localhost:3000/api/v1/admin/dashboard',
  { method: 'GET', headers: { 'Accept': 'application/json' } },
  (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => console.log('STATUS:', res.statusCode, 'DATA:', data));
  }
);
req.on('error', e => console.error(e));
req.end();
