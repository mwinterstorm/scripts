const puppeteer = require('puppeteer');
const fs = require('fs');

const args = process.argv.slice(2);
const homeArg = args.find(arg => arg.startsWith('--home='));
if (!homeArg) {
  console.error('❌ Please provide a home URL using --home=https://example.com');
  process.exit(1);
}
const baseUrl = homeArg.split('=')[1];
(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();

  await page.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });

  const internalLinks = await page.evaluate((base) => {
    const anchors = Array.from(document.querySelectorAll('a[href]'));
    const links = anchors
      .map(a => a.href.trim())
      .filter(href =>
        href.startsWith(base) &&
        !href.includes('#') &&
        !href.endsWith('.pdf')
      );
    return Array.from(new Set(links)); // dedupe
  }, baseUrl);

  await browser.close();

  fs.writeFileSync('urls.txt', internalLinks.join('\n'), 'utf-8');
  console.log(`✅ Extracted ${internalLinks.length} internal URLs to urls.txt`);
})();