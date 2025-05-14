// Quantumult X resource-parser.js
// 用于将 Surge Rule Set 转换为 Quantumult X 支持格式
// 支持类型：DOMAIN, DOMAIN-SUFFIX, DOMAIN-KEYWORD, IP-CIDR, IP-CIDR6, IP-ASN

(async () => {
  if (typeof $resource === "undefined") {
    console.log("请在 Quantumult X 中使用该脚本");
    return;
  }

  const POLICY = "proxy"; // 默认策略，可修改

  const raw = $resource.content;
  if (!raw) $done("");

  const lines = raw.split("\n");

  const output = lines.map((line) => {
    const trimmed = line.trim();

    // 跳过空行或注释
    if (!trimmed || trimmed.startsWith("#") || trimmed.startsWith(";")) {
      return "";
    }

    const parts = trimmed.split(",");
    if (parts.length < 2) return "";

    const type = parts[0].trim().toUpperCase();
    const value = parts[1].trim();

    switch (type) {
      case "DOMAIN-SUFFIX":
        return `host-suffix, ${value}, ${POLICY}`;
      case "DOMAIN":
        return `host, ${value}, ${POLICY}`;
      case "DOMAIN-KEYWORD":
        return `host-keyword, ${value}, ${POLICY}`;
      case "IP-CIDR":
        return `ip-cidr, ${value}, ${POLICY}`;
      case "IP-CIDR6":
        return `ip6-cidr, ${value}, ${POLICY}`;
      case "IP-ASN":
        return `ip-asn, ${value}, ${POLICY}`;
      default:
        return "";
    }
  }).filter(Boolean);

  $done(output.join("\n"));
})();