const fs = require('fs');
const path = require('path');
const matter = require('gray-matter');
const { marked } = require('marked');

const postsDir = path.join(__dirname, '..', 'content', 'blog');
const outputPath = path.join(__dirname, '..', 'public', 'posts.json');

console.log(`Scanning markdown files in directory: ${postsDir}`);

function getAllMarkdownFiles(dir) {
  let files = [];
  const items = fs.readdirSync(dir, { withFileTypes: true });

  items.forEach(item => {
    const fullPath = path.join(dir, item.name);
    if (item.isDirectory()) {
      console.log(`Descending into folder: ${fullPath}`);
      files = files.concat(getAllMarkdownFiles(fullPath));
    } else if (item.isFile() && fullPath.toLowerCase().endsWith('.md')) {
      console.log(`Found markdown file: ${fullPath}`);
      files.push(fullPath);
    }
  });

  return files;
}

try {
  const files = getAllMarkdownFiles(postsDir);

  if (files.length === 0) {
    console.warn('No markdown files found. Check your folder structure and paths.');
  }

  const posts = files.map(filePath => {
    const fileContents = fs.readFileSync(filePath, 'utf8');
    const { data, content } = matter(fileContents);

    return {
      title: data.title || 'Untitled',
      date: data.date || null,
      content: marked(content, { mangle: false, headerIds: false }), // avoid deprecated warnings
      slug: path.relative(postsDir, filePath).replace(/\\/g, '/').replace(/\.md$/, ''),
    };
  });

  // Ensure output directory exists
  const outputDir = path.dirname(outputPath);
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  fs.writeFileSync(outputPath, JSON.stringify(posts, null, 2));
  console.log(`Built ${posts.length} posts to ${outputPath}`);
} catch (err) {
  console.error('Error building posts:', err);
  process.exit(1);
}
