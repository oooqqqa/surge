const headers = { ...$request.headers };

if (!headers['referer']) {
  headers['referer'] = 'https://sspai.com/';
}

$done({ headers });