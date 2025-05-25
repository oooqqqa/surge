const headers = { ...$request.headers };

if (!headers['Referer']) {
  headers['Referer'] = 'https://sspai.com/';
}

$done({ headers });