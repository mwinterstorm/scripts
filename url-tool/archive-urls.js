const puppeteer = require('puppeteer');
const fs = require('fs');
const readline = require('readline-sync');
const { default: PDFMerger } = require('pdf-merger-js');

// === Parse command line arguments ===
const args = process.argv.slice(2);
let outputFileArg = args.find(arg => arg.startsWith('--output='));
let outputFile = outputFileArg ? outputFileArg.split('=')[1] : null;
const markdownOnly = args.includes('--markdown');

// === Load URLs from file ===
const urlFile = 'urls.txt';
if (!fs.existsSync(urlFile)) {
  console.error(`❌ URL file not found: ${urlFile}`);
  process.exit(1);
}

const urls = fs.readFileSync(urlFile, 'utf-8')
  .split('\n')
  .map(line => line.trim())
  .filter(line => line.length > 0);

console.log('\n📄 URLs to be processed:\n');
urls.forEach((url, idx) => console.log(`${idx + 1}. ${url}`));

// === Confirm ===
const confirm = readline.question('\nProceed with these URLs? (y/n): ');
if (confirm.toLowerCase() !== 'y') {
  console.log('Aborted.');
  process.exit(0);
}

// === Output file name ===
if (!outputFile) {
  const prompt = markdownOnly ? '\nEnter output markdown filename (no extension): ' : '\nEnter output PDF filename (no extension): ';
  outputFile = readline.question(prompt);
  if (!outputFile) {
    console.log('❌ Invalid filename. Aborted.');
    process.exit(1);
  }
}
outputFile = markdownOnly
  ? (outputFile.endsWith('.md') ? outputFile : `${outputFile}.md`)
  : (outputFile.endsWith('.pdf') ? outputFile : `${outputFile}.pdf`);

(async () => {
  const browser = await puppeteer.launch();

  if (markdownOnly) {
    const sections = [];
    for (let i = 0; i < urls.length; i++) {
      const page = await browser.newPage();
      console.log(`\n🔄 Processing: ${urls[i]}`);
      await page.goto(urls[i], { waitUntil: 'load', timeout: 0 });
      await page.evaluate(() => {
        document.querySelectorAll('[aria-expanded="false"], summary, .accordion-toggle, .faq-question').forEach(el => {
          try { el.click(); } catch (e) {}
        });
        document.querySelectorAll('details').forEach(el => el.open = true);
      });
      await new Promise(resolve => setTimeout(resolve, 1000));

      const title = await page.title();
      const text = await page.evaluate(() => document.body.innerText);
      sections.push(`# ${title}\n\nSource: ${location.href}\n\n${text}\n`);
      await page.close();
    }
    fs.writeFileSync(outputFile, sections.join('\n---\n\n'), 'utf-8');
    await browser.close();
    console.log(`\n✅ Text saved to ${outputFile}`);
    return;
  }

  const merger = new PDFMerger();
  const tocEntries = [];

  // === Generate page PDFs ===
  for (let i = 0; i < urls.length; i++) {
    const page = await browser.newPage();
    console.log(`\n🔄 Processing: ${urls[i]}`);
    console.log('  ⏳ Opening page...');
    await page.goto(urls[i], { waitUntil: 'load', timeout: 0 });

    console.log('  🧩 Expanding content...');
    // Expand FAQ and collapsible elements
    await page.evaluate(() => {
      // Click elements that toggle visibility
      document.querySelectorAll('[aria-expanded="false"], summary, .accordion-toggle, .faq-question').forEach(el => {
        try { el.click(); } catch (e) {}
      });

      // Force-open <details> elements
      document.querySelectorAll('details').forEach(el => el.open = true);
    });

    console.log('  🕒 Waiting for animations...');
    // Optional: wait for any animations or JS-rendered content
    await new Promise(resolve => setTimeout(resolve, 1000));

    await page.screenshot({ path: `debug_page${i}.png`, fullPage: true });

    console.log('  🖨️ Generating PDF...');
    const title = await page.title();
    tocEntries.push({ title, url: urls[i], pageNum: i + 2 }); // TOC is page 1

    const filename = `page${i}.pdf`;
    await page.pdf({ path: filename, format: 'A4', printBackground: true });
    await merger.add(filename);
    console.log(`  ✅ Done: ${urls[i]}`);
    await page.close();
  }

  // === Create TOC ===
  const tocHtml = `
  <html>
    <head>
      <style>
        body { font-family: sans-serif; padding: 40px; }
        h1 { text-align: center; }
        ol { font-size: 14px; line-height: 1.6; }
        a { color: #0645AD; text-decoration: none; }
        a:hover { text-decoration: underline; }
      </style>
    </head>
    <body>
      <h1>Table of Contents</h1>
      <ol>
        ${tocEntries.map(entry => `
          <li><a href="${entry.url}" target="_blank">${entry.title}</a></li>
        `).join('')}
      </ol>
    </body>
  </html>
`;

  const tocPage = await browser.newPage();
  await tocPage.setContent(tocHtml, { waitUntil: 'domcontentloaded', timeout: 0 });
  await tocPage.pdf({ path: 'toc.pdf', format: 'A4', printBackground: true });
  await merger.add('toc.pdf', 0); // Add TOC first
  await tocPage.close();

  // === Save final merged PDF ===
  console.log(`\n📦 Saving to: ${outputFile}`);
  await merger.save(outputFile);

  // === Clean up temp files ===
  fs.unlinkSync('toc.pdf');
  for (let i = 0; i < urls.length; i++) {
    fs.unlinkSync(`page${i}.pdf`);
  }

  await browser.close();
  console.log('\n✅ Done!');
})();
