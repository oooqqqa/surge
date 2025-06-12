const cheerio = createCheerio()
const UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
const headers = {
  'Referer': 'https://ddys.pro/',
  'Origin': 'https://ddys.pro',
  'User-Agent': UA,
}

const appConfig = {
  ver: 2,
  title: "低端影视",
  site: "https://ddys.pro/",
  tabs: [
    { name: '首页', ext: { url: '/', filterable: false } },
    { name: '所有电影', ext: { url: '/category/movie/', filterable: true } },
    { name: '连载剧集', ext: { url: '/category/airing/', hasMore: false } },
    { name: '本季新番', ext: { url: '/category/anime/new-bangumi/', hasMore: false } },
    { name: '动画', ext: { url: '/category/anime/' } },
    { name: '华语电影', ext: { url: '/category/movie/chinese-movie/' } },
    { name: '欧美电影', ext: { url: '/category/movie/western-movie/' } },
    { name: '日韩电影', ext: { url: '/category/movie/asian-movie/' } },
    { name: '豆瓣电影Top250', ext: { url: '/tag/douban-top250/' } },
    { name: '欧美剧', ext: { url: '/category/drama/western-drama/' } },
    { name: '日剧', ext: { url: '/category/drama/jp-drama/' } },
    { name: '韩剧', ext: { url: '/category/drama/kr-drama/' } },
    { name: '华语剧', ext: { url: '/category/drama/cn-drama/' } },
  ]
}

async function fetchWithRetry(url, options = {}) {
  for (let i = 0; i < 2; i++) {
    try {
      return await $fetch.get(url, options);
    } catch (e) {}
  }
  return { data: '' };
}

async function getConfig() {
  return jsonify(appConfig)
}

async function getCards(ext) {
  ext = argsify(ext)
  let cards = []
  let url = ext.url
  let page = ext.page || 1
  let hasMore = ext.hasMore !== false
  let filter = ext.filter || ''

  if (!hasMore && page > 1) {
    return jsonify({ list: cards, hasMore: false })
  }

  let fullUrl = appConfig.site + url + (filter ? filter : '') + `/page/${page}/`
  const res = await fetchWithRetry(fullUrl, { headers })
  const data = res.data
  if (!data) return jsonify({ list: [], hasMore: false })

  const $ = cheerio.load(data)
  const items = $('article.post')
  items.each((_, each) => {
    const style = $(each).find('.post-box-image').attr('style') || ''
    const match = style.match(/url\(["']?(.*?)["']?\)/)
    cards.push({
      vod_id: $(each).find('h2 > a').attr('href') || '',
      vod_name: $(each).find('h2.post-box-title').text().trim() || '无标题',
      vod_pic: match ? match[1] : '',
      vod_remarks: $(each).find('div.post-box-text > p').text().trim() || '',
      ext: { url: $(each).find('h2 > a').attr('href') || '' },
    })
  })

  const nextPageExists = items.length >= 10
  return jsonify({ list: cards, hasMore: nextPageExists })
}

async function getTracks(ext) {
  ext = argsify(ext);
  let groups = [];
  let url = ext.url;

  const res = await fetchWithRetry(url, { headers });
  const data = res.data;
  if (!data) return jsonify({ list: [] });

  const $ = cheerio.load(data);
  const seasonNumbers = [];
  $('.page-links .post-page-numbers').each((_, each) => {
    const seasonNumber = $(each).text().trim();
    if (!isNaN(seasonNumber)) seasonNumbers.push(seasonNumber);
  });

  if (seasonNumbers.length === 0) {
    const trackText = $('script.wp-playlist-script').text();
    try {
      const tracks = JSON.parse(trackText).tracks || [];
      if (tracks.length > 0) {
        groups.push({
          title: '在线',
          tracks: tracks.map(each => ({
            name: each.caption || '未命名',
            pan: '',
            ext: each
          }))
        })
      }
    } catch {}
  } else {
    for (const season of seasonNumbers) {
      const seasonUrl = `${url}${season}/`
      const res2 = await fetchWithRetry(seasonUrl, { headers })
      const seasonData = res2.data;
      if (!seasonData) continue;
      const season$ = cheerio.load(seasonData);
      const trackText = season$('script.wp-playlist-script').text();
      try {
        const tracks = JSON.parse(trackText).tracks || []
        if (tracks.length > 0) {
          groups.push({
            title: `第${season}季`,
            tracks: tracks.map(each => ({
              name: each.caption || '未命名',
              pan: '',
              ext: each
            }))
          })
        }
      } catch {}
    }
  }

  let group2 = { title: '网盘', tracks: [] }
  $('a').each((_, each) => {
    const v = $(each).attr('href') || ''
    if (v.startsWith('https://drive.uc.cn/s')) {
      group2.tracks.push({ name: 'UC网盘', pan: v })
    } else if (v.startsWith('https://pan.quark.cn/s/')) {
      group2.tracks.push({ name: '夸克网盘', pan: v })
    }
  })
  if (group2.tracks.length > 0) groups.push(group2)

  return jsonify({ list: groups });
}

async function getPlayinfo(ext) {
  ext = argsify(ext)
  const { srctype, src0 } = ext
  let url = ''
  if (srctype && src0) {
    url = 'https://v.ddys.pro' + src0
  }
  return jsonify({
    urls: [url],
    headers: [{
      'Referer': 'https://ddys.mov/',
      'Origin': 'https://ddys.mov',
      'User-Agent': UA,
    }],
    ui: 1,
  })
}

async function search(ext) {
  ext = argsify(ext)
  let cards = []
  let text = encodeURIComponent(ext.text || '')
  let page = ext.page || 1
  if (!text) return jsonify({ list: [] })

  let url = appConfig.site + (page > 1 ? `/page/${page}/?s=${text}` : `/?s=${text}&post_type=post`)
  const res = await fetchWithRetry(url, { headers })
  const data = res.data
  if (!data) return jsonify({ list: [] })

  const $ = cheerio.load(data)
  $('article.post').each((_, each) => {
    cards.push({
      vod_id: $(each).find('h2 > a').attr('href') || '',
      vod_name: $(each).find('h2.post-title').text().trim() || '无标题',
      vod_pic: '',
      vod_remarks: $(each).find('div.entry-content > p').text().trim() || '',
      ext: {
        url: $(each).find('h2 > a').attr('href') || ''
      },
    })
  })

  const hasMore = cards.length >= 10
  return jsonify({ list: cards, hasMore })
}