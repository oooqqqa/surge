/**
 * @fileoverview 将 Surge 规则集转换为 Quantumult X 支持的规则格式
 * @supported Quantumult X (v1.0.8-build253)
 */

// 读取输入内容并按行拆分
const lines = $resource.content.split(/\r?\n/);
const output = [];

// 定义 Surge 到 Quantumult X 规则类型的映射
const typeMap = {
  'DOMAIN':        'host',        // 精确域名匹配
  'DOMAIN-SUFFIX': 'host-suffix', // 后缀域名匹配
  'DOMAIN-KEYWORD':'host-keyword',// 关键字域名匹配
  'IP-CIDR':       'ip-cidr',     // IPv4 CIDR 匹配
  'IP-CIDR6':      'ip6-cidr',    // IPv6 CIDR 匹配
  'IP-ASN':        'ip-asn'       // ASN 匹配
};

// 遍历每行，过滤注释与空行，转换规则
for (let raw of lines) {
  let line = raw.trim();
  if (!line || line.startsWith('#') || line.startsWith('//') || line.startsWith(';')) continue;
  const parts = line.split(',').map(p => p.trim());
  const key = (parts[0] || '').toUpperCase();
  const target = parts[1];
  // 如果为支持的 Surge 规则类型，则转换
  if (typeMap[key] && target) {
    output.push(`${typeMap[key]}, ${target}, proxy`);
  }
}

// 返回转换后结果
$done({ content: output.join('\n') });