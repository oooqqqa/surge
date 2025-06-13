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
  site: "https://ddys.pro/",
  tabs: [
    { name: '首页', ext: { url: '/' } },
    { name: '所有电影', ext: { url: '/category/movie/' } },
    { name: '连载剧集', ext: { url: '/category/airing/' } },
    { name: '动画', ext: { url: '/category/anime/' } },
    { name: '欧美剧', ext: { url: '/category/drama/western-drama/' } },
    { name: '韩剧', ext: { url: '/category/drama/kr-drama/' } },
    { name: '日剧', ext: { url: '/category/drama/jp-drama/' } },
    { name: '华语剧', ext: { url: '/category/drama/cn-drama/' } },
  ]
}

async function getConfig() {
  return jsonify(appConfig)
}

async function getCards(ext) {
  ext = argsify(ext)
  let cards = []
  let url = appConfig.site + ext.url + `/page/${ext.page || 1}/`
  const res = await $fetch.get(url, { headers })
  const $ = cheerio.load(res.data)

  $('article.post').each((_, el) => {
    const style = $(el).find('.post-box-image').attr('style') || ''
    const match = style.match(/url\\(([^)]+)\\)/)
    cards.push({
      vod_id: $(el).find('h2 > a').attr('href'),
      vod_name: $(el).find('h2.post-box-title').text().trim(),
      vod_pic: match ? match[1] : '',
      vod_remarks: $(el).find('div.post-box-text > p').text().trim(),
      ext: { url: $(el).find('h2 > a').attr('href') }
    })
  })

  return jsonify({ list: cards })
}

async function getTracks(ext) {
  ext = argsify(ext)
  let groups = []
  const res = await $fetch.get(ext.url, { headers })
  const $ = cheerio.load(res.data)

  const scriptText = $('script.wp-playlist-script').text()
  const tracks = JSON.parse(scriptText).tracks
  groups.push({
    title: '在线',
    tracks: tracks.map(t => ({
      name: t.caption,
      pan: '',
      ext: t
    }))
  })

  let panGroup = { title: '网盘', tracks: [] }
  $('a').each((_, a) => {
    const href = $(a).attr('href')
    if (href && (href.startsWith('https://drive.uc.cn/s') || href.startsWith('https://pan.quark.cn/s/'))) {
      panGroup.tracks.push({ name: '网盘链接', pan: href })
    }
  })
  if (panGroup.tracks.length > 0) groups.push(panGroup)

  return jsonify({ list: groups })
}

async function getPlayinfo(ext) {
  ext = argsify(ext)
  const url = 'https://v.ddys.pro' + ext.src0
  return jsonify({
    urls: [url],
    headers: [{
      'Referer': 'https://ddys.mov/',
      'Origin': 'https://ddys.mov',
      'User-Agent': UA,
    }],
    ui: 1
  })
}

async function search(ext) {
  ext = argsify(ext)
  let cards = []
  const text = encodeURIComponent(ext.text)
  const url = appConfig.site + `/?s=${text}&post_type=post`
  const res = await $fetch.get(url, { headers })
  const $ = cheerio.load(res.data)

  $('article.post').each((_, el) => {
    cards.push({
      vod_id: $(el).find('h2 > a').attr('href'),
      vod_name: $(el).find('h2.post-title').text().trim(),
      vod_pic: '',
      vod_remarks: $(el).find('div.entry-content > p').text().trim(),
      ext: { url: $(el).find('h2 > a').attr('href') }
    })
  })

  return jsonify({ list: cards })
}