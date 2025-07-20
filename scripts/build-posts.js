const fs = require('fs');
const path = require('path');
const matter = require('gray-matter');
const { marked } = require('marked');

const postsDir = path.join(__dirname, '..', 'content', 'blog');
const outputPath = path.join(__dirname, '..', 'public', 'posts.json');

function getAllMarkdownFiles(dir) {
  let files = [];
  console.log(`Reading directory: ${dir}`);
  if (!fs.existsSync(dir)) {
    console.error(`Directory does not exist: ${dir}`);
    return files;
  }
  const items = fs.readdirSync(dir, { withFileTypes: true });

  items.forEach(item => {
    const fullPath = path.join(dir, item.name);
    if (item.isDirectory()) {
      files = files.concat(getAllMarkdownFiles(fullPath));
    } else if (item.isFile() && fullPath.endsWith('.md')) {
      console.log(`Found markdown file: ${fullPath}`);
      files.push(fullPath);
    }
  });

  return files;
}

const files = getAllMarkdownFiles(postsDir);

if (files.length === 0) {
  console.warn('No markdown files found.');
}

const posts = files.map(filePath => {
  const fileContents = fs.readFileSync(filePath, 'utf8');
  const { data, content } = matter(fileContents);

  return {
    title: data.title || 'Untitled',
    date: data.date || null,
    image: data.image || null, // ✅ Add this line
    content: marked(content),
    slug: path.relative(postsDir, filePath).replace(/\\/g, '/').replace(/\.md$/, ''),
  };
});


// Ensure output directory exists
const outputDir = path.dirname(outputPath);
if (!fs.existsSync(outputDir)) {
  console.log(`Creating directory: ${outputDir}`);
  fs.mkdirSync(outputDir, { recursive: true });
}

fs.writeFileSync(outputPath, JSON.stringify(posts, null, 2));

console.log(`Built ${posts.length} posts to ${outputPath}`);
