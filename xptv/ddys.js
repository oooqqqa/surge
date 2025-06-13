const cheerio = createCheerio();

const UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

const headers = {
  'Referer': 'https://ddys.pro/',
  'Origin': 'https://ddys.pro',
  'User-Agent': UA
};

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
    { name: '华语剧', ext: { url: '/category/drama/cn-drama/' } }
  ]
};

async function getConfig() {
  return jsonify(appConfig);
}

async function getCards(ext) {
  ext = argsify(ext);

  const cards = [];

  const page = ext.page || 1;
  const url = appConfig.site + ext.url + "/page/" + page + "/";

  const res = await $fetch.get(url, { headers });
  const $ = cheerio.load(res.data);

  const posts = $('article.post');

  for (let i = 0; i < posts.length; i++) {
    const el = posts[i];

    const style = $(el).find('.post-box-image').attr('style') || '';
    const match = style.match(/url\(([^)]+)\)/);

    let pic = '';
    if (match) {
      pic = match[1];
    }

    const card = {
      vod_id:     $(el).find('h2 > a').attr('href'),
      vod_name:   $(el).find('h2.post-box-title').text().trim(),
      vod_pic:    pic,
      vod_remarks: $(el).find('div.post-box-text > p').text().trim(),
      ext: {
        url: $(el).find('h2 > a').attr('href')
      }
    };

    cards.push(card);
  }

  return jsonify({ list: cards });
}

async function getTracks(ext) {
  ext = argsify(ext);

  const groups = [];
  const res = await $fetch.get(ext.url, { headers });
  const $ = cheerio.load(res.data);

  const seasonNumbers = [];

  const seasonEls = $('.page-links .post-page-numbers');
  for (let i = 0; i < seasonEls.length; i++) {
    const text = $(seasonEls[i]).text().trim();
    if (!isNaN(text)) {
      seasonNumbers.push(text);
    }
  }
  /**
   * TODO: Improved loading speed for multiple seasons.
   */
  if (seasonNumbers.length > 0) {
    for (let i = 0; i < seasonNumbers.length; i++) {
      const season = seasonNumbers[i];
      const seasonUrl = ext.url + season + "/";
      const seasonRes = await $fetch.get(seasonUrl, { headers });
      const $season = cheerio.load(seasonRes.data);

      const scriptText = $season('script.wp-playlist-script').text();
      const tracks = JSON.parse(scriptText).tracks || [];

      if (tracks.length > 0) {
        const trackList = [];
        for (let j = 0; j < tracks.length; j++) {
          const t = tracks[j];
          trackList.push({
            name: t.caption,
            pan: '',
            ext: t
          });
        }
        groups.push({
          title: "第" + season + "季",
          tracks: trackList
        });
      }
    }
  } else {
    const scriptText = $('script.wp-playlist-script').text();
    const tracks = JSON.parse(scriptText).tracks || [];

    if (tracks.length > 0) {
      const trackList = [];
      for (let i = 0; i < tracks.length; i++) {
        const t = tracks[i];
        trackList.push({
          name: t.caption,
          pan: '',
          ext: t
        });
      }
      groups.push({
        title: '在线',
        tracks: trackList
      });
    }
  }

  const panGroup = {
    title: '网盘',
    tracks: []
  };

  const links = $('a');
  for (let i = 0; i < links.length; i++) {
    const href = $(links[i]).attr('href');

    if (href && (href.startsWith('https://drive.uc.cn/s') || href.startsWith('https://pan.quark.cn/s/'))) {
      panGroup.tracks.push({
        name: '网盘链接',
        pan: href
      });
    }
  }

  if (panGroup.tracks.length > 0) {
    groups.push(panGroup);
  }

  return jsonify({ list: groups });
}

async function getPlayinfo(ext) {
  ext = argsify(ext);

  const url = 'https://v.ddys.pro' + ext.src0;

  return jsonify({
    urls: [url],
    headers: [
      {
        'Referer': 'https://ddys.mov/',
        'Origin':  'https://ddys.mov',
        'User-Agent': UA
      }
    ],
    ui: 1
  });
}

async function search(ext) {
  ext = argsify(ext);

  const cards = [];

  const text = encodeURIComponent(ext.text);
  const url = appConfig.site + "?s=" + text + "&post_type=post";

  const res = await $fetch.get(url, { headers });
  const $ = cheerio.load(res.data);

  const posts = $('article.post');

  for (let i = 0; i < posts.length; i++) {
    const el = posts[i];

    const card = {
      vod_id:     $(el).find('h2 > a').attr('href'),
      vod_name:   $(el).find('h2.post-title').text().trim(),
      vod_pic:    '',
      vod_remarks: $(el).find('div.entry-content > p').text().trim(),
      ext: {
        url: $(el).find('h2 > a').attr('href')
      }
    };

    cards.push(card);
  }

  return jsonify({ list: cards });
}