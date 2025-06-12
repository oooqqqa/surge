const cheerio = createCheerio()
const UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
const headers = {
  'Referer': 'https://ddys.pro/',
  'Origin': 'https://ddys.pro',
  'User-Agent': UA,
}

const appConfig = {
  ver: 1,
  title: "低端影视",
  site: 'https://ddys.pro/',
  tabs: [
    { name: '首页', ext: { url: '/' } },
    { name: '所有电影', ext: { url: '/category/movie/' } },
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

async function getConfig() {
  return jsonify(appConfig)
}

async function getCards(ext) {
  ext = argsify(ext)
  let cards = []
  let url = ext.url
  let page = ext.page || 1
  let hasMore = ext.hasMore !== false

  if (!hasMore && page > 1) {
    return jsonify({ list: cards })
  }

  url = appConfig.site + url + `/page/${page}/`
  let data = ''
  try {
    const res = await $fetch.get(url, { headers })
    data = res.data
  } catch (err) {
    return jsonify({ list: [] })
  }

  const $ = cheerio.load(data)
  $('article.post').each((_, each) => {
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

  return jsonify({ list: cards })
}

async function getTracks(ext) {
  ext = argsify(ext);
  let groups = [];
  let url = ext.url;

  let data = ''
  try {
    const res = await $fetch.get(url, { headers });
    data = res.data;
  } catch (err) {
    return jsonify({ list: [] });
  }

  const $ = cheerio.load(data);
  const seasonNumbers = [];
  $('.page-links .post-page-numbers').each((_, each) => {
    const seasonNumber = $(each).text().trim();
    if (!isNaN(seasonNumber)) seasonNumbers.push(seasonNumber);
  });

  if (seasonNumbers.length === 0) {
    let group = { title: '在线', tracks: [] }
    const trackText = $('script.wp-playlist-script').text()
    try {
      const tracks = JSON.parse(trackText).tracks || []
      tracks.forEach(each => {
        group.tracks.push({
          name: each.caption || '未命名',
          pan: '',
          ext: each
        })
      })
    } catch {}
    if (group.tracks.length > 0) groups.push(group)
  } else {
    for (const season of seasonNumbers) {
      const seasonUrl = `${url}${season}/`
      let seasonData = ''
      try {
        const res = await $fetch.get(seasonUrl, { headers })
        seasonData = res.data
      } catch { continue }

      const season$ = cheerio.load(seasonData);
      const trackText = season$('script.wp-playlist-script').text()
      try {
        const tracks = JSON.parse(trackText).tracks || []
        groups.push({
          title: `第${season}季`,
          tracks: tracks.map(each => ({
            name: each.caption || '未命名',
            pan: '',
            ext: each
          }))
        })
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
  if (!text || page > 1) return jsonify({ list: cards })

  const url = appConfig.site + `/?s=${text}&post_type=post`
  let data = ''
  try {
    const res = await $fetch.get(url, { headers })
    data = res.data
  } catch (err) {
    return jsonify({ list: [] })
  }

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

  return jsonify({ list: cards })
}